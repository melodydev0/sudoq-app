import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

/// Tracks paywall funnel events for Firebase A/B Testing and Analytics.
///
/// Event flow:
///   paywall_view  →  paywall_cta_tapped  →  purchase_started
///                                         →  purchase_success
///                                         →  purchase_failed
///                                         →  purchase_cancelled
///
/// All events include `paywall_variant` so Firebase can split results
/// per experiment group automatically.
class PaywallAnalytics {
  PaywallAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Core events ─────────────────────────────────────────────────────────────

  /// Call when the paywall/subscription screen becomes visible.
  static void logPaywallView({String? plan}) {
    _log('paywall_view', {
      'plan': plan ?? 'none',
    });
  }

  /// Call when the user taps "Unlock Premium" button.
  static void logCtaTapped(String plan) {
    _log('paywall_cta_tapped', {'plan': plan});
  }

  /// Call right before `PurchaseService.buySubscription()`.
  static void logPurchaseStarted(String plan) {
    _log('paywall_purchase_started', {'plan': plan});
  }

  /// Call on `PurchaseResult.success` or `PurchaseResult.restored`.
  static void logPurchaseSuccess(String plan) {
    _log('paywall_purchase_success', {'plan': plan});
    // Also log Firebase's standard purchase event so it shows in
    // the "Purchases" tab of the Analytics dashboard.
    _analytics.logPurchase(
      currency: 'USD',  // Firebase just needs any ISO code; RC tracks the real one
      value: 0,         // We don't have the exact value here; set if available
      parameters: {
        'plan': plan,
        'paywall_variant': RemoteConfigService.paywallVariant,
      },
    ).ignore();
  }

  /// Call on `PurchaseResult.error`.
  static void logPurchaseFailed(String plan, String reason) {
    _log('paywall_purchase_failed', {
      'plan': plan,
      'reason': reason.length > 100 ? reason.substring(0, 100) : reason,
    });
  }

  /// Call on `PurchaseResult.cancelled`.
  static void logPurchaseCancelled(String plan) {
    _log('paywall_purchase_cancelled', {'plan': plan});
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  static void _log(String event, Map<String, Object> params) {
    final enriched = {
      ...params,
      'paywall_variant': RemoteConfigService.paywallVariant,
    };
    if (kDebugMode) {
      debugPrint('[Analytics] $event: $enriched');
    }
    _analytics.logEvent(name: event, parameters: enriched).ignore();
  }
}
