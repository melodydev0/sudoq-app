/// Application constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SudoQ';
  static const String appVersion = '1.0.3';

  // Grid sizes
  static const int gridSize9x9 = 9;
  static const int gridSize16x16 = 16;
  static const int boxSize3x3 = 3;
  static const int boxSize4x4 = 4;

  // Game settings
  static const int maxMistakes = 3;
  /// Max hints per game (same for free and premium).
  static const int maxHints = 5;
  /// Free users: this many hints per game without watching an ad; rest require ad.
  static const int freeHintsWithoutAd = 2;
  static const int scorePerCell = 10;
  static const int scorePerHint = -50;
  static const int scorePerfectGame = 500;

  /// Second chance limits per game
  static const int maxSecondChancesFree = 1;    // Free users: 1 per game (via ad)
  static const int maxSecondChancesPremium = 2; // Premium users: 2 per game (free)

  // Ad rewards
  static const int adsForHint = 1; // Watch 1 ad for one extra hint (free users, after freeHintsWithoutAd)
  static const int adsForFastPencil = 1; // Watch 1 ad to unlock fast pencil
  static const int adsForSecondChance = 1; // Watch 1 ad for second chance (free users)

  // Difficulty levels
  static const List<String> difficultyLevels = [
    'Beginner',
    'Easy',
    'Medium',
    'Hard',
    'Expert',
    'Extreme',
  ];

  // Cells to remove per difficulty (for 9x9)
  static const Map<String, int> cellsToRemove = {
    'Beginner': 30,
    'Easy': 38,
    'Medium': 45,
    'Hard': 50,
    'Expert': 54,
    'Extreme': 58,
  };

  // Storage keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyExperienceLevel = 'experience_level';
  static const String keyCurrentGame = 'current_game';
  static const String keyStatistics = 'statistics';
  static const String keyAchievements = 'achievements';
  static const String keySettings = 'settings';
  static const String keyAdsFree = 'ads_free';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyDailyChallenge = 'daily_challenge';
  static const String keyFavorites = 'favorites';
  static const String keyPushNotificationsEnabled = 'push_notifications_enabled';

  // AdMob IDs
  // Real IDs for production; debug mode overrides these with test IDs in AdsService.
  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-4679569583423185~4086488817',
  );
  static const String bannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-4679569583423185/6770769586',
  );
  static const String interstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-4679569583423185/5336825459',
  );
  static const String rewardedAdUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-4679569583423185/2710662116',
  );

  static const String _googleTestAdmobAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String _googleTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _googleTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _googleTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static bool get isUsingTestAdMobIds {
    return admobAppId == _googleTestAdmobAppId ||
        bannerAdUnitId == _googleTestBannerAdUnitId ||
        interstitialAdUnitId == _googleTestInterstitialAdUnitId ||
        rewardedAdUnitId == _googleTestRewardedAdUnitId;
  }

  // ── In-App Purchase ─────────────────────────────────────────────
  // Google Play: single subscription with 2 active base plans + yearly intro offer
  static const String googlePlaySubscriptionId = 'sudoq_premium';
  static const String basePlanWeekly = 'weekly';
  static const String basePlanYearly = 'yearly';

  // iOS App Store: separate subscription products (same subscription group)
  static const String iosWeeklyId = 'sudoq_premium_weekly';
  static const String iosYearlyId = 'sudoq_premium_yearly';
  static const Set<String> iosSubscriptionIds = {
    iosWeeklyId,
    iosYearlyId,
  };

  // All valid product IDs accepted by server-side verification
  static const Set<String> subscriptionIds = {
    googlePlaySubscriptionId,
    iosWeeklyId,
    iosYearlyId,
  };

  // Legacy (keep for backward compatibility)
  static const String adsFreeProductId = 'ads_free_purchase';

  // URLs
  static const String privacyPolicyUrl = 'https://gotips.web.tr/privacy-policy2.html';
  static const String termsOfServiceUrl = 'https://gotips.web.tr/terms-of-service-sudoq.html';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
