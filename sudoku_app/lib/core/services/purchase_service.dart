import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'ads_service.dart';
import 'user_sync_service.dart';

/// Result of a purchase operation
enum PurchaseResult {
  success,
  cancelled,
  error,
  pending,
  alreadyOwned,
  restored,
}

/// Subscription plan type
enum SubscriptionPlan {
  weekly,
  monthly,
  yearly,
}

/// Service for managing in-app purchases (subscriptions)
class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];
  static bool _isInitialized = false;
  static bool _isPurchasing = false;

  // Callbacks
  static Function(PurchaseResult, String?)? onPurchaseResult;

  /// Initialize the purchase service
  static Future<bool> init() async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        debugPrint('IAP not available');
        _isInitialized = true;
        return false;
      }

      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => debugPrint('Purchase stream closed'),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      // Load products
      await _loadProducts();

      // Restore purchases in background
      _restoreInBackground();

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('PurchaseService init error: $e');
      _isInitialized = true;
      return false;
    }
  }

  /// Load available products from stores
  static Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    try {
      // Query all subscription products
      final response = await _iap
          .queryProductDetails(
            AppConstants.subscriptionIds,
          )
          .timeout(const Duration(seconds: 15));

      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
        // This is expected if products aren't configured in stores yet
      }

      _products = response.productDetails;
      debugPrint(
          'Loaded ${_products.length} products: ${_products.map((p) => p.id).join(", ")}');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  /// Restore purchases in background
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

  /// Restore purchases manually
  static Future<bool> restorePurchases() async {
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

      // Wait for stream to process
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

  /// Buy a subscription
  static Future<PurchaseResult> buySubscription(SubscriptionPlan plan) async {
    if (_isPurchasing) {
      return PurchaseResult.pending;
    }

    if (!_isAvailable) {
      onPurchaseResult?.call(PurchaseResult.error, 'Store not available');
      return PurchaseResult.error;
    }

    if (StorageService.isAdsFree()) {
      onPurchaseResult?.call(PurchaseResult.alreadyOwned, 'Already premium');
      return PurchaseResult.alreadyOwned;
    }

    // Get product ID for the selected plan
    final productId = _getProductId(plan);

    // Find the product
    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      // Product not found, try to reload
      await _loadProducts();
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (e) {
        onPurchaseResult?.call(PurchaseResult.error, 'Product not available');
        return PurchaseResult.error;
      }
    }

    try {
      _isPurchasing = true;

      final purchaseParam = PurchaseParam(productDetails: product);

      // Use buyNonConsumable for subscriptions
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

  /// Handle purchase updates from the store
  static void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint('Purchase update: ${purchase.productID} - ${purchase.status}');

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
          onPurchaseResult?.call(
            PurchaseResult.error,
            purchase.error?.message ?? 'Unknown error',
          );
          break;

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          onPurchaseResult?.call(PurchaseResult.cancelled, 'Cancelled');
          break;
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Activate premium feature
  static void _activatePremium(PurchaseDetails purchase) {
    _isPurchasing = false;

    // Check if it's one of our subscription products
    if (AppConstants.subscriptionIds.contains(purchase.productID) ||
        purchase.productID == AppConstants.adsFreeProductId) {
      StorageService.setAdsFree(true);
      AdsService.onAdsFreeActivated();
      // Sync premium to Firestore so it follows the user across devices
      UserSyncService.syncToCloud().then((ok) {
        if (ok) debugPrint('Premium synced to cloud');
      });

      final isRestored = purchase.status == PurchaseStatus.restored;
      onPurchaseResult?.call(
        isRestored ? PurchaseResult.restored : PurchaseResult.success,
        isRestored ? 'Premium restored!' : 'Premium activated!',
      );
      debugPrint('Premium activated for: ${purchase.productID}');
    }
  }

  /// Get product ID for a plan
  static String _getProductId(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return AppConstants.subscriptionWeeklyId;
      case SubscriptionPlan.monthly:
        return AppConstants.subscriptionMonthlyId;
      case SubscriptionPlan.yearly:
        return AppConstants.subscriptionYearlyId;
    }
  }

  /// Get product details for a plan
  static ProductDetails? getProduct(SubscriptionPlan plan) {
    final productId = _getProductId(plan);
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get formatted price for a plan (from store)
  static String getPrice(SubscriptionPlan plan) {
    final product = getProduct(plan);
    if (product != null) {
      return product.price;
    }

    // Fallback prices if store not available
    switch (plan) {
      case SubscriptionPlan.weekly:
        return '\$1.99';
      case SubscriptionPlan.monthly:
        return '\$4.99';
      case SubscriptionPlan.yearly:
        return '\$29.99';
    }
  }

  /// Check if products are loaded
  static bool get hasProducts => _products.isNotEmpty;

  /// Check if store is available
  static bool get isStoreAvailable => _isAvailable;

  /// Check if a purchase is in progress
  static bool get isPurchasing => _isPurchasing;

  /// Reload products (for retry)
  static Future<void> reloadProducts() async {
    await _loadProducts();
  }

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _isPurchasing = false;
  }
}
