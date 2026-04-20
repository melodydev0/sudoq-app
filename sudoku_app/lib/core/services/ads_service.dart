import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

/// Service for managing advertisements
class AdsService {
  static bool _isInitialized = false;
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static int _gamesPlayedSinceLastAd = 0;

  // Daily limits keys
  static const String _keySecondChanceUsedToday = 'second_chance_used_today';
  static const String _keySecondChanceDate = 'second_chance_date';
  static const String _keyDailyBonusClaimed = 'daily_bonus_claimed';
  static const String _keyDailyBonusDate = 'daily_bonus_date';
  static const String _keyInstallTimestampMs = 'install_timestamp_ms';

  // Daily limits
  static const int maxSecondChancePerDay = 2;
  static const int interstitialFrequency = 2; // Show every 2nd game after grace period
  static const Duration _initialInterstitialGracePeriod = Duration(hours: 3);

  /// Ad unit IDs resolved per build mode: test IDs in debug, real IDs in release.
  static String get _bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : AppConstants.bannerAdUnitId;
  static String get _interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : AppConstants.interstitialAdUnitId;
  static String get _rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : AppConstants.rewardedAdUnitId;

  /// Initialize the ads service
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kReleaseMode && AppConstants.isUsingTestAdMobIds) {
        debugPrint(
          'Release build is still using test AdMob IDs. Ads are disabled.',
        );
        return;
      }

      await MobileAds.instance.initialize();
      _isInitialized = true;
      await _ensureInstallTimestamp();

      if (!StorageService.isAdsFree()) {
        loadBannerAd();
        loadInterstitialAd();
        loadRewardedAd();
      }
    } catch (e) {
      debugPrint('Ads initialization error: $e');
    }
  }

  /// Check if ads should be shown
  static bool shouldShowAds() {
    return !StorageService.isAdsFree();
  }

  // ==================== Banner Ad ====================

  static void loadBannerAd() {
    if (!shouldShowAds()) return;

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          // Retry after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            if (_bannerAd == null && shouldShowAds()) {
              loadBannerAd();
            }
          });
        },
      ),
    )..load();
  }

  static Widget getBannerAdWidget() {
    if (!shouldShowAds() || _bannerAd == null) {
      // Attempt reload if banner is missing
      if (shouldShowAds() && _bannerAd == null) {
        loadBannerAd();
      }
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  static bool isBannerAdLoaded() {
    return _bannerAd != null && shouldShowAds();
  }

  // ==================== Interstitial Ad ====================

  static void loadInterstitialAd() {
    if (!shouldShowAds()) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (!shouldShowAds()) {
      onAdClosed?.call();
      return;
    }

    if (await _isWithinInitialGracePeriod()) {
      onAdClosed?.call();
      return;
    }

    // Show ad every 2 games
    _gamesPlayedSinceLastAd++;
    if (_gamesPlayedSinceLastAd < interstitialFrequency) {
      onAdClosed?.call();
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _gamesPlayedSinceLastAd = 0;
          loadInterstitialAd();
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onAdClosed?.call();
        },
      );

      await _interstitialAd!.show();
    } else {
      onAdClosed?.call();
      loadInterstitialAd();
    }
  }

  // ==================== Rewarded Ad ====================

  static void loadRewardedAd() {
    if (!shouldShowAds()) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show rewarded ad with simple callbacks
  /// [onRewarded] is called when user successfully watches the ad
  /// [onAdClosed] is called when ad is closed (regardless of reward)
  /// [onAdNotReady] is called when ad is not loaded yet (e.g. emulator slow load)
  static Future<void> showRewardedAd({
    VoidCallback? onRewarded,
    VoidCallback? onAdClosed,
    VoidCallback? onAdNotReady,
  }) async {
    // Premium users never see any rewarded ad
    if (!shouldShowAds()) {
      onRewarded?.call();
      onAdClosed?.call();
      return;
    }
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready, loading...');
      loadRewardedAd();
      onAdNotReady?.call();
      onAdClosed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdClosed?.call();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onRewarded?.call();
      },
    );
  }

  static bool isRewardedAdReady() {
    return _rewardedAd != null;
  }

  // ==================== Dispose ====================

  static void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
  }

  /// Call when user purchases ads-free
  static void onAdsFreeActivated() {
    dispose();
  }

  // ==================== Second Chance (3 hatada devam et) ====================

  /// Check if second chance is available today (max 2 per day)
  static Future<bool> isSecondChanceAvailable() async {
    if (!shouldShowAds()) return true; // Premium users always have it

    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keySecondChanceDate) ?? '';

    if (savedDate != today) {
      // New day, reset counter
      return true;
    }

    final usedToday = prefs.getInt(_keySecondChanceUsedToday) ?? 0;
    return usedToday < maxSecondChancePerDay;
  }

  /// Get remaining second chances for today
  static Future<int> getSecondChanceRemaining() async {
    if (!shouldShowAds()) return 999; // Premium users unlimited

    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keySecondChanceDate) ?? '';

    if (savedDate != today) {
      return maxSecondChancePerDay;
    }

    final usedToday = prefs.getInt(_keySecondChanceUsedToday) ?? 0;
    return (maxSecondChancePerDay - usedToday).clamp(0, maxSecondChancePerDay);
  }

  /// Show rewarded ad for second chance
  /// Returns true if user earned second chance
  static Future<void> showSecondChanceAd({
    VoidCallback? onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    // Premium users get it free
    if (!shouldShowAds()) {
      onRewarded?.call();
      onAdClosed?.call();
      return;
    }

    // Check if available
    final available = await isSecondChanceAvailable();
    if (!available) {
      debugPrint('Second chance limit reached for today');
      onAdClosed?.call();
      return;
    }

    // Show rewarded ad
    await showRewardedAd(
      onRewarded: () {
        onRewarded?.call();
        _trackSecondChanceUsage();
      },
      onAdClosed: onAdClosed,
    );
  }

  // ==================== XP Boost (Oyun sonunda 2x XP) ====================

  /// Show rewarded ad for XP boost (2x XP)
  static Future<void> showXpBoostAd({
    VoidCallback? onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    // Premium users get it free
    if (!shouldShowAds()) {
      onRewarded?.call();
      onAdClosed?.call();
      return;
    }

    await showRewardedAd(
      onRewarded: onRewarded,
      onAdClosed: onAdClosed,
    );
  }

  // ==================== Daily Bonus (Günde 1 kez 50 XP) ====================

  /// Check if daily bonus is available
  static Future<bool> isDailyBonusAvailable() async {
    if (!shouldShowAds()) return false; // Premium users don't need this

    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyDailyBonusDate) ?? '';

    return savedDate != today;
  }

  /// Show rewarded ad for daily bonus (50 XP)
  static Future<void> showDailyBonusAd({
    VoidCallback? onRewarded,
    VoidCallback? onAdClosed,
    VoidCallback? onAdNotReady,
  }) async {
    if (!shouldShowAds()) {
      onAdClosed?.call();
      return;
    }
    // Check if available
    final available = await isDailyBonusAvailable();
    if (!available) {
      debugPrint('Daily bonus already claimed today');
      onAdClosed?.call();
      return;
    }

    await showRewardedAd(
      onRewarded: () {
        onRewarded?.call();
        _trackDailyBonusClaimed();
      },
      onAdClosed: onAdClosed,
      onAdNotReady: onAdNotReady,
    );
  }

  // ==================== Async Tracking (fire-and-forget) ====================

  static Future<void> _trackSecondChanceUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keySecondChanceDate) ?? '';

    if (savedDate != today) {
      await prefs.setString(_keySecondChanceDate, today);
      await prefs.setInt(_keySecondChanceUsedToday, 1);
    } else {
      final usedToday = prefs.getInt(_keySecondChanceUsedToday) ?? 0;
      await prefs.setInt(_keySecondChanceUsedToday, usedToday + 1);
    }
  }

  static Future<void> _trackDailyBonusClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    await prefs.setString(_keyDailyBonusDate, today);
    await prefs.setBool(_keyDailyBonusClaimed, true);
  }

  // ==================== Utility ====================

  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _ensureInstallTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyInstallTimestampMs)) {
      await prefs.setInt(_keyInstallTimestampMs, DateTime.now().millisecondsSinceEpoch);
    }
  }

  static Future<bool> _isWithinInitialGracePeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final installedAtMs = prefs.getInt(_keyInstallTimestampMs);
    if (installedAtMs == null) {
      await prefs.setInt(_keyInstallTimestampMs, DateTime.now().millisecondsSinceEpoch);
      return true;
    }

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(installedAtMs),
    );
    return elapsed < _initialInterstitialGracePeriod;
  }
}
