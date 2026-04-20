import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Manages Firebase Remote Config for paywall A/B experiments.
///
/// Parameters controlled from Firebase Console:
///   paywall_variant          → 'control' | 'variant_a' | 'variant_b'
///   yearly_offer_token       → Play offer token override for yearly plan
///   weekly_offer_token       → Play offer token override for weekly plan
///   yearly_intro_badge_pct   → Override the savings badge % shown on yearly card (0 = auto)
class RemoteConfigService {
  RemoteConfigService._();

  // ── Parameter keys ──────────────────────────────────────────────────────────
  static const String _keyVariant = 'paywall_variant';
  static const String _keyYearlyOfferToken = 'yearly_offer_token';
  static const String _keyWeeklyOfferToken = 'weekly_offer_token';
  static const String _keyYearlyBadgePct = 'yearly_intro_badge_pct';

  // ── Defaults (used before first fetch and in debug builds) ─────────────────
  static const Map<String, dynamic> _defaults = {
    _keyVariant: 'control',
    _keyYearlyOfferToken: '',
    _keyWeeklyOfferToken: '',
    _keyYearlyBadgePct: 0,
  };

  static FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;
  static bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await _rc.setDefaults(_defaults);

      await _rc.setConfigSettings(RemoteConfigSettings(
        // Debug: fetch every 30s so you can iterate quickly
        // Production: Firebase automatically throttles to ≥12h
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: kDebugMode
            ? const Duration(seconds: 30)
            : const Duration(hours: 12),
      ));

      // Fetch + activate in one shot; errors are non-fatal (defaults apply)
      await _rc.fetchAndActivate();
      _initialized = true;

      debugPrint('[RC] Initialized — variant: $paywallVariant');
    } catch (e) {
      debugPrint('[RC] Init error (defaults in use): $e');
      _initialized = true; // still mark done so we don't retry every call
    }
  }

  // ── Accessors ───────────────────────────────────────────────────────────────

  /// Which paywall variant this user is assigned to.
  /// Possible values: 'control', 'variant_a', 'variant_b'
  static String get paywallVariant => _rc.getString(_keyVariant);

  /// Optional Play offer token for the yearly plan.
  /// When non-empty, overrides the token returned by the Play Billing API.
  static String? get yearlyOfferTokenOverride {
    final v = _rc.getString(_keyYearlyOfferToken);
    return v.isNotEmpty ? v : null;
  }

  /// Optional Play offer token for the weekly plan.
  static String? get weeklyOfferTokenOverride {
    final v = _rc.getString(_keyWeeklyOfferToken);
    return v.isNotEmpty ? v : null;
  }

  /// Override for the "Save X%" badge percentage.
  /// 0 means "calculate automatically from prices".
  static int get yearlyBadgePct => _rc.getInt(_keyYearlyBadgePct);

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Force a fresh fetch (call e.g. when app resumes after long background).
  static Future<void> refresh() async {
    try {
      await _rc.fetchAndActivate();
      debugPrint('[RC] Refreshed — variant: $paywallVariant');
    } catch (e) {
      debugPrint('[RC] Refresh error: $e');
    }
  }
}
