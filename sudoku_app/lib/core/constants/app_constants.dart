/// Application constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Classic Sudoku';
  static const String appVersion = '1.0.0';

  // Grid sizes
  static const int gridSize9x9 = 9;
  static const int gridSize16x16 = 16;
  static const int boxSize3x3 = 3;
  static const int boxSize4x4 = 4;

  // Game settings
  static const int maxMistakes = 3;
  static const int maxHints = 2; // Free hints reduced to 2
  static const int scorePerCell = 10;
  static const int scorePerHint = -50;
  static const int scorePerfectGame = 500;

  // Ad rewards
  static const int adsForHint = 1; // Watch 1 ad for extra hint
  static const int adsForFastPencil = 1; // Watch 1 ad to unlock fast pencil
  static const int adsForSecondChance = 3; // Watch 3 ads for second chance

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

  // AdMob IDs (Test IDs - Replace with real ones before release)
  static const String admobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // In-App Purchase IDs (Replace before release)
  // These IDs must match EXACTLY with Google Play Console & App Store Connect
  static const String subscriptionWeeklyId = 'sudoku_premium_weekly';
  static const String subscriptionMonthlyId = 'sudoku_premium_monthly';
  static const String subscriptionYearlyId = 'sudoku_premium_yearly';

  // All subscription product IDs
  static const Set<String> subscriptionIds = {
    subscriptionWeeklyId,
    subscriptionMonthlyId,
    subscriptionYearlyId,
  };

  // Legacy (keep for backward compatibility)
  static const String adsFreeProductId = 'ads_free_purchase';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
