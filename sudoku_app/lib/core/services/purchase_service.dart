import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'user_sync_service.dart';
import 'auth_service.dart';
import 'entitlement_service.dart';
import 'remote_config_service.dart';
import 'paywall_analytics.dart';

enum PurchaseResult {
  success,
  cancelled,
  error,
  pending,
  alreadyOwned,
  restored,
}

enum SubscriptionPlan {
  weekly,
  yearly,
}

/// Parsed pricing info for a subscription plan (base price + optional intro offer).
class PlanPricing {
  final SubscriptionPlan plan;
  final String offerToken;
  final String regularPrice;
  final int regularPriceMicros;
  final String? introPrice;
  final int? introPriceMicros;
  final bool hasIntroOffer;
  final String currencyCode;

  const PlanPricing({
    required this.plan,
    required this.offerToken,
    required this.regularPrice,
    required this.regularPriceMicros,
    this.introPrice,
    this.introPriceMicros,
    this.hasIntroOffer = false,
    this.currencyCode = '',
  });

  String get displayPrice => hasIntroOffer && introPrice != null ? introPrice! : regularPrice;

  /// Effective price in micros: intro price if available, otherwise regular.
  int get displayPriceMicros =>
      hasIntroOffer && introPriceMicros != null ? introPriceMicros! : regularPriceMicros;

  int get introSavingsPercent {
    if (!hasIntroOffer || regularPriceMicros == 0 || introPriceMicros == null) {
      return 0;
    }
    return ((regularPriceMicros - introPriceMicros!) /
            regularPriceMicros *
            100)
        .round();
  }

  /// Weekly equivalent price in micros (yearly display price / 52).
  int get weeklyEquivalentMicros =>
      plan == SubscriptionPlan.yearly && displayPriceMicros > 0
          ? (displayPriceMicros / 52).round()
          : 0;
}

/// Service for managing in-app purchases (subscriptions).
class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];
  static final Map<SubscriptionPlan, PlanPricing> _planPricing = {};
  static bool _isInitialized = false;
  static bool _isPurchasing = false;

  /// The plan the user last initiated a purchase for.
  /// Used to recover plan context when processing the purchase stream, since
  /// `GooglePlayPurchaseDetails` does not expose basePlanId and offerToken
  /// is opaque/base64 (cannot be string-matched).
  static SubscriptionPlan? _pendingPlan;

  static Function(PurchaseResult, String?)? onPurchaseResult;

  // ────────────────────── Init ──────────────────────

  static Future<bool> init() async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        debugPrint('IAP not available');
        _isInitialized = true;
        return false;
      }

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => debugPrint('Purchase stream closed'),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      await _loadProducts();
      _restoreInBackground();

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('PurchaseService init error: $e');
      _isInitialized = true;
      return false;
    }
  }

  // ────────────────────── Products ──────────────────────

  static Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    try {
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final productIds = isAndroid
          ? {AppConstants.googlePlaySubscriptionId}
          : AppConstants.iosSubscriptionIds;

      final response = await _iap
          .queryProductDetails(productIds)
          .timeout(const Duration(seconds: 15));

      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint(
        'Loaded ${_products.length} products: '
        '${_products.map((p) => p.id).join(", ")}',
      );

      _parseOfferPricing();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  // ────────────────────── Offer Parsing ──────────────────────

  static void _parseOfferPricing() {
    _planPricing.clear();

    if (defaultTargetPlatform == TargetPlatform.android) {
      _parseAndroidOffers();
    } else {
      _parseIOSProducts();
    }

    debugPrint('Parsed ${_planPricing.length} plan pricings: '
        '${_planPricing.entries.map((e) => '${e.key.name}=${e.value.displayPrice}').join(", ")}');
  }

  static void _parseAndroidOffers() {
    if (_products.isEmpty) return;

    final product = _products.first;
    if (product is! GooglePlayProductDetails) return;

    final allOffers = product.productDetails.subscriptionOfferDetails;
    if (allOffers == null || allOffers.isEmpty) return;

    // Log all available offer tokens so you can copy them for Remote Config
    debugPrint('=== AVAILABLE OFFER TOKENS ===');
    for (final o in allOffers) {
      debugPrint(
        'basePlan=${o.basePlanId} | offerId=${o.offerId ?? "(base)"} '
        '| token=${o.offerIdToken}',
      );
    }
    debugPrint('==============================');

    // Group offers by basePlanId
    final grouped = <String, List<SubscriptionOfferDetailsWrapper>>{};
    for (final offer in allOffers) {
      final bpId = offer.basePlanId;
      grouped.putIfAbsent(bpId, () => []).add(offer);
    }

    for (final entry in grouped.entries) {
      final plan = _basePlanIdToPlan(entry.key);
      if (plan == null) continue;

      SubscriptionOfferDetailsWrapper? baseOffer;
      SubscriptionOfferDetailsWrapper? introOffer;

      for (final o in entry.value) {
        if (o.offerId == null || o.offerId!.isEmpty) {
          baseOffer = o;
        } else {
          // Prefer intro offer (first one found)
          introOffer ??= o;
        }
      }

      if (baseOffer == null && introOffer == null) continue;

      // Extract regular price from base offer
      String regularPrice = '';
      int regularPriceMicros = 0;
      String currencyCode = '';
      if (baseOffer != null && baseOffer.pricingPhases.isNotEmpty) {
        final recurring = baseOffer.pricingPhases.last;
        regularPrice = recurring.formattedPrice;
        regularPriceMicros = recurring.priceAmountMicros;
        currencyCode = recurring.priceCurrencyCode;
      }

      // If there's an intro offer with 2+ phases → strikethrough pricing
      if (introOffer != null && introOffer.pricingPhases.length >= 2) {
        final introPhase = introOffer.pricingPhases.first;
        final regularPhase = introOffer.pricingPhases.last;

        // Fallback regular price from the offer's recurring phase
        if (regularPrice.isEmpty) {
          regularPrice = regularPhase.formattedPrice;
          regularPriceMicros = regularPhase.priceAmountMicros;
          currencyCode = regularPhase.priceCurrencyCode;
        }

        _planPricing[plan] = PlanPricing(
          plan: plan,
          offerToken: introOffer.offerIdToken,
          regularPrice: regularPrice,
          regularPriceMicros: regularPriceMicros,
          introPrice: introPhase.formattedPrice,
          introPriceMicros: introPhase.priceAmountMicros,
          hasIntroOffer: true,
          currencyCode: currencyCode,
        );
        continue;
      }

      // No intro offer → use base plan directly
      final selected = introOffer ?? baseOffer!;
      if (regularPrice.isEmpty && selected.pricingPhases.isNotEmpty) {
        final phase = selected.pricingPhases.last;
        regularPrice = phase.formattedPrice;
        regularPriceMicros = phase.priceAmountMicros;
        currencyCode = phase.priceCurrencyCode;
      }

      _planPricing[plan] = PlanPricing(
        plan: plan,
        offerToken: selected.offerIdToken,
        regularPrice: regularPrice,
        regularPriceMicros: regularPriceMicros,
        currencyCode: currencyCode,
      );
    }
  }

  static void _parseIOSProducts() {
    for (final product in _products) {
      final plan = _iosProductIdToPlan(product.id);
      if (plan == null) continue;

      _planPricing[plan] = PlanPricing(
        plan: plan,
        offerToken: '',
        regularPrice: product.price,
        regularPriceMicros: (product.rawPrice * 1000000).round(),
        currencyCode: product.currencyCode,
      );
    }
  }

  // ────────────────────── Restore ──────────────────────

  static Future<void> _restoreInBackground() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (StorageService.isAdsFree()) {
        debugPrint('Already premium');
        return;
      }

      await _iap.restorePurchases().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Background restore error: $e');
    }
  }

  static Future<bool> restorePurchases() async {
    if (!AuthService.isSignedIn || AuthService.isAnonymous) {
      onPurchaseResult?.call(
        PurchaseResult.error,
        'Please sign in with a permanent account to restore purchases.',
      );
      return false;
    }

    if (!_isAvailable) {
      onPurchaseResult?.call(PurchaseResult.error, 'Store not available');
      return false;
    }

    try {
      if (StorageService.isAdsFree()) {
        onPurchaseResult?.call(PurchaseResult.alreadyOwned, 'Already premium');
        return true;
      }

      await _iap.restorePurchases().timeout(const Duration(seconds: 15));
      await Future.delayed(const Duration(seconds: 1));

      final restored = StorageService.isAdsFree();
      if (restored) {
        onPurchaseResult?.call(PurchaseResult.restored, 'Purchase restored!');
      }
      return restored;
    } catch (e) {
      debugPrint('Restore error: $e');
      onPurchaseResult?.call(PurchaseResult.error, 'Restore failed');
      return false;
    }
  }

  // ────────────────────── Purchase ──────────────────────

  static Future<PurchaseResult> buySubscription(SubscriptionPlan plan) async {
    if (!AuthService.isSignedIn || AuthService.isAnonymous) {
      onPurchaseResult?.call(
        PurchaseResult.error,
        'Please sign in with Google or Apple before purchasing premium.',
      );
      return PurchaseResult.error;
    }

    if (_isPurchasing) return PurchaseResult.pending;

    if (!_isAvailable) {
      onPurchaseResult?.call(PurchaseResult.error, 'Store not available');
      return PurchaseResult.error;
    }

    if (StorageService.isAdsFree()) {
      onPurchaseResult?.call(PurchaseResult.alreadyOwned, 'Already premium');
      return PurchaseResult.alreadyOwned;
    }

    // Ensure products are loaded
    if (_products.isEmpty) await _loadProducts();

    final pricing = _planPricing[plan];
    final product = _findProductForPlan(plan);

    if (product == null || pricing == null) {
      onPurchaseResult?.call(PurchaseResult.error, 'Product not available');
      return PurchaseResult.error;
    }

    try {
      _isPurchasing = true;

      // Apply Remote Config offer token override (A/B experiment)
      final rcOverride = plan == SubscriptionPlan.yearly
          ? RemoteConfigService.yearlyOfferTokenOverride
          : RemoteConfigService.weeklyOfferTokenOverride;
      final effectiveOfferToken =
          (rcOverride != null && rcOverride.isNotEmpty) ? rcOverride : pricing.offerToken;

      final PurchaseParam purchaseParam;

      if (defaultTargetPlatform == TargetPlatform.android &&
          effectiveOfferToken.isNotEmpty) {
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: effectiveOfferToken,
        );
      } else {
        purchaseParam = PurchaseParam(productDetails: product);
      }

      PaywallAnalytics.logPurchaseStarted(plan.name);
      _pendingPlan = plan;
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!result) {
        _isPurchasing = false;
        onPurchaseResult?.call(PurchaseResult.cancelled, 'Purchase cancelled');
        return PurchaseResult.cancelled;
      }

      return PurchaseResult.pending;
    } catch (e) {
      _isPurchasing = false;
      debugPrint('Purchase error: $e');
      onPurchaseResult?.call(PurchaseResult.error, e.toString());
      return PurchaseResult.error;
    }
  }

  static ProductDetails? _findProductForPlan(SubscriptionPlan plan) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _products.isNotEmpty ? _products.first : null;
    }
    final iosId = _planToIosProductId(plan);
    for (final p in _products) {
      if (p.id == iosId) return p;
    }
    return null;
  }

  // ────────────────────── Purchase Updates ──────────────────────

  static Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint(
          'Purchase update: ${purchase.productID} - ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPurchaseResult?.call(PurchaseResult.pending, 'Processing...');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _activatePremium(purchase);
          break;

        case PurchaseStatus.error:
          _isPurchasing = false;
          PaywallAnalytics.logPurchaseFailed(
            purchase.productID,
            purchase.error?.message ?? 'unknown',
          );
          onPurchaseResult?.call(
            PurchaseResult.error,
            purchase.error?.message ?? 'Unknown error',
          );
          break;

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          PaywallAnalytics.logPurchaseCancelled(purchase.productID);
          onPurchaseResult?.call(PurchaseResult.cancelled, 'Cancelled');
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  static Future<void> _activatePremium(PurchaseDetails purchase) async {
    _isPurchasing = false;

    if (AppConstants.subscriptionIds.contains(purchase.productID) ||
        purchase.productID == AppConstants.adsFreeProductId) {
      onPurchaseResult?.call(
        PurchaseResult.pending,
        'Verifying purchase securely...',
      );

      bool premiumActivated = false;
      try {
        // Find price info for this purchase.
        // On Android all plans share one product ID (sudoq_premium), so we
        // cannot distinguish plans by productID alone and the offerToken is
        // opaque (base64) — we cannot string-match base plan names inside it.
        // Instead we rely on `_pendingPlan`, set in `buySubscription()` right
        // before calling the billing client.
        //
        // For the price we use `displayPrice`, which returns the intro price
        // when an intro offer is active (e.g. yearly-intro at TRY 1,799.99)
        // and the regular price otherwise. This matches what the user actually
        // paid.
        String? priceStr;
        String? currencyStr;

        SubscriptionPlan? resolvedPlan = _pendingPlan;

        if (defaultTargetPlatform == TargetPlatform.android &&
            purchase is GooglePlayPurchaseDetails) {
          if (resolvedPlan != null) {
            final pricing = _planPricing[resolvedPlan];
            if (pricing != null) {
              priceStr = pricing.displayPrice;
              currencyStr = pricing.currencyCode.isNotEmpty
                  ? pricing.currencyCode
                  : (_products.isNotEmpty ? _products.first.currencyCode : null);
            }
          }
          // Fallback: if we lost pendingPlan (e.g. app was restarted mid-flow),
          // take the first known pricing entry.
          if (priceStr == null && _planPricing.isNotEmpty) {
            final entry = _planPricing.entries.first;
            priceStr = entry.value.displayPrice;
            currencyStr = entry.value.currencyCode.isNotEmpty
                ? entry.value.currencyCode
                : (_products.isNotEmpty ? _products.first.currencyCode : null);
          }
        } else {
          for (final entry in _planPricing.entries) {
            final product = _findProductForPlan(entry.key);
            if (product != null && product.id == purchase.productID) {
              priceStr = entry.value.displayPrice;
              currencyStr = product.currencyCode;
              break;
            }
          }
        }

        _pendingPlan = null;

        premiumActivated =
            await EntitlementService.submitPurchaseClaim(
              purchase,
              price: priceStr,
              currency: currencyStr,
            );
      } catch (e) {
        debugPrint('Purchase verification error: $e');
      }

      if (!premiumActivated) {
        onPurchaseResult?.call(
          PurchaseResult.error,
          'Purchase could not be verified. Please try Restore Purchases.',
        );
        return;
      }

      UserSyncService.syncToCloud().then((ok) {
        if (ok) debugPrint('User data synced after premium verification');
      });

      final isRestored = purchase.status == PurchaseStatus.restored;
      PaywallAnalytics.logPurchaseSuccess(purchase.productID);
      onPurchaseResult?.call(
        isRestored ? PurchaseResult.restored : PurchaseResult.success,
        isRestored ? 'Premium restored!' : 'Premium activated!',
      );
      debugPrint('Premium activated for: ${purchase.productID}');
    }
  }

  // ────────────────────── Public Getters ──────────────────────

  /// Get parsed pricing info for a plan.
  static PlanPricing? getPlanPricing(SubscriptionPlan plan) =>
      _planPricing[plan];

  /// Get formatted display price for a plan (intro price if available).
  /// Returns null if store data hasn't loaded yet.
  static String? getPrice(SubscriptionPlan plan) {
    return _planPricing[plan]?.displayPrice;
  }

  /// Get the regular (non-discounted) price for a plan, or null if no offers loaded.
  static String? getRegularPrice(SubscriptionPlan plan) =>
      _planPricing[plan]?.regularPrice;

  /// Whether the plan has an introductory offer.
  static bool hasIntroOffer(SubscriptionPlan plan) =>
      _planPricing[plan]?.hasIntroOffer ?? false;

  /// Weekly equivalent price string for yearly plan (yearly display price / 52).
  /// Uses the intro/discounted price when available so the per-week figure
  /// reflects what the user actually pays.
  /// Formats using the device locale so symbol, separator and position are
  /// all correct for every currency (₺34,62 · $34.62 · 34,62 € · £34.62 …).
  /// Returns null if pricing hasn't loaded yet.
  static String? getYearlyWeeklyEquivalent() {
    final yearly = _planPricing[SubscriptionPlan.yearly];
    if (yearly == null || yearly.displayPriceMicros == 0) return null;

    final weeklyAmount = yearly.displayPriceMicros / 52 / 1000000;
    final code = yearly.currencyCode.isNotEmpty ? yearly.currencyCode : null;

    try {
      // Use device locale so number format (separators, symbol position)
      // matches the store's own formatting for every country/currency.
      final locale = kIsWeb ? Intl.defaultLocale : Platform.localeName;
      final fmt = NumberFormat.simpleCurrency(
        locale: locale,
        name: code,
        decimalDigits: 2,
      );
      return fmt.format(weeklyAmount);
    } catch (_) {
      // Fallback: raw code + number
      final formatted = weeklyAmount.toStringAsFixed(2);
      return code != null ? '$code $formatted' : formatted;
    }
  }

  /// Savings percentage when choosing yearly over weekly plan.
  /// Compares each plan's effective (display) price so the badge reflects
  /// real prices the user sees. Returns null if either plan isn't loaded yet.
  static int? getYearlySavingsPercent() {
    final weekly = _planPricing[SubscriptionPlan.weekly];
    final yearly = _planPricing[SubscriptionPlan.yearly];

    if (weekly == null || yearly == null) return null;

    final weeklyMicros = weekly.displayPriceMicros.toDouble();
    final yearlyMicros = yearly.displayPriceMicros.toDouble();

    if (weeklyMicros == 0) return null;

    final yearlyAsWeekly = yearlyMicros / 52;
    final savings =
        ((weeklyMicros - yearlyAsWeekly) / weeklyMicros * 100).round();
    return savings > 0 ? savings : null;
  }

  static bool get hasProducts => _products.isNotEmpty;
  static bool get isStoreAvailable => _isAvailable;
  static bool get isPurchasing => _isPurchasing;

  static Future<void> reloadProducts() async => _loadProducts();

  // ────────────────────── Helpers ──────────────────────

  static SubscriptionPlan? _basePlanIdToPlan(String basePlanId) {
    switch (basePlanId) {
      case AppConstants.basePlanWeekly:
        return SubscriptionPlan.weekly;
      case AppConstants.basePlanYearly:
        return SubscriptionPlan.yearly;
      default:
        return null;
    }
  }

  static SubscriptionPlan? _iosProductIdToPlan(String productId) {
    switch (productId) {
      case AppConstants.iosWeeklyId:
        return SubscriptionPlan.weekly;
      case AppConstants.iosYearlyId:
        return SubscriptionPlan.yearly;
      default:
        return null;
    }
  }

  static String _planToIosProductId(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return AppConstants.iosWeeklyId;
      case SubscriptionPlan.yearly:
        return AppConstants.iosYearlyId;
    }
  }

  // ────────────────────── Dispose ──────────────────────

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _isPurchasing = false;
  }
}
