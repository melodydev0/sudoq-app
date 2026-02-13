import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../models/statistics.dart';
import '../models/achievement.dart';
import '../services/storage_service.dart';
import '../services/sudoku_generator.dart';
import '../services/achievement_service.dart';

/// Sudoku generator provider
final sudokuGeneratorProvider = Provider<SudokuGenerator>((ref) {
  return SudokuGenerator();
});

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(StorageService.getSettings());

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    await StorageService.saveSettings(settings);
  }

  Future<void> toggleDarkMode() async {
    final newSettings = state.copyWith(isDarkMode: !state.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> toggleSound() async {
    final newSettings = state.copyWith(soundEnabled: !state.soundEnabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleVibration() async {
    final newSettings =
        state.copyWith(vibrationEnabled: !state.vibrationEnabled);
    await updateSettings(newSettings);
  }

  Future<void> setDefaultDifficulty(String difficulty) async {
    final newSettings = state.copyWith(defaultDifficulty: difficulty);
    await updateSettings(newSettings);
  }
}

/// Statistics provider
final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, Statistics>((ref) {
  return StatisticsNotifier();
});

class StatisticsNotifier extends StateNotifier<Statistics> {
  StatisticsNotifier() : super(StorageService.getStatistics());

  Future<void> updateStatistics(Statistics stats) async {
    state = stats;
    await StorageService.saveStatistics(stats);
  }

  Future<void> recordGameWon({
    required String difficulty,
    required int time,
    required int score,
    required int mistakes,
    bool isDailyChallenge = false,
  }) async {
    final isPerfect = mistakes == 0;
    final diffStats = state.difficultyStats[difficulty] ?? DifficultyStats();

    final newDiffStats = diffStats.copyWith(
      gamesPlayed: diffStats.gamesPlayed + 1,
      gamesWon: diffStats.gamesWon + 1,
      bestTime: diffStats.bestTime == 0
          ? time
          : (time < diffStats.bestTime ? time : diffStats.bestTime),
      bestScore: score > diffStats.bestScore ? score : diffStats.bestScore,
      averageTime: ((diffStats.averageTime * diffStats.gamesWon) + time) ~/
          (diffStats.gamesWon + 1),
    );

    // Track unique days played
    final today = _getTodayString();
    final uniqueDays = List<String>.from(state.uniqueDaysPlayed);
    if (!uniqueDays.contains(today)) {
      uniqueDays.add(today);
    }

    // Track daily challenges completed
    final dailyChallengesCompleted = isDailyChallenge
        ? state.totalDailyChallengesCompleted + 1
        : state.totalDailyChallengesCompleted;

    final newStats = state.copyWith(
      totalGamesPlayed: state.totalGamesPlayed + 1,
      totalGamesWon: state.totalGamesWon + 1,
      currentStreak: state.currentStreak + 1,
      bestStreak: (state.currentStreak + 1) > state.bestStreak
          ? state.currentStreak + 1
          : state.bestStreak,
      totalPlayTime: state.totalPlayTime + time,
      perfectGames: isPerfect ? state.perfectGames + 1 : state.perfectGames,
      lastPlayedDate: DateTime.now(),
      difficultyStats: {
        ...state.difficultyStats,
        difficulty: newDiffStats,
      },
      uniqueDaysPlayed: uniqueDays,
      totalDailyChallengesCompleted: dailyChallengesCompleted,
    );

    await updateStatistics(newStats);
  }

  /// Get today's date as a string (YYYY-MM-DD) for tracking unique days
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> recordGameLost({
    required String difficulty,
    required int time,
  }) async {
    final diffStats = state.difficultyStats[difficulty] ?? DifficultyStats();

    final newDiffStats = diffStats.copyWith(
      gamesPlayed: diffStats.gamesPlayed + 1,
    );

    // Track unique days played (even on loss)
    final today = _getTodayString();
    final uniqueDays = List<String>.from(state.uniqueDaysPlayed);
    if (!uniqueDays.contains(today)) {
      uniqueDays.add(today);
    }

    final newStats = state.copyWith(
      totalGamesPlayed: state.totalGamesPlayed + 1,
      totalGamesLost: state.totalGamesLost + 1,
      currentStreak: 0,
      totalPlayTime: state.totalPlayTime + time,
      lastPlayedDate: DateTime.now(),
      difficultyStats: {
        ...state.difficultyStats,
        difficulty: newDiffStats,
      },
      uniqueDaysPlayed: uniqueDays,
    );

    await updateStatistics(newStats);
  }

  Future<void> recordHintUsed() async {
    final newStats = state.copyWith(
      totalHintsUsed: state.totalHintsUsed + 1,
    );
    await updateStatistics(newStats);
  }

  /// Reset all statistics to default
  Future<void> reset() async {
    state = Statistics();
    await StorageService.saveStatistics(state);
  }
}

/// Ads-free status provider
final adsFreeProvider = StateProvider<bool>((ref) {
  return StorageService.isAdsFree();
});

/// First launch provider
final firstLaunchProvider = StateProvider<bool>((ref) {
  return StorageService.isFirstLaunch();
});

/// Experience level provider
final experienceLevelProvider = StateProvider<String?>((ref) {
  return StorageService.getExperienceLevel();
});

/// Selected cosmetic providers for real-time updates
final selectedFrameProvider = StateProvider<String>((ref) {
  return 'frame_basic';
});

final selectedThemeProvider = StateProvider<String>((ref) {
  return 'theme_default';
});

final selectedEffectProvider = StateProvider<String>((ref) {
  return 'effect_none';
});

/// Achievements data provider for real-time UI updates
/// Holds actual unlocked achievement IDs for consistent display across screens
final achievementsDataProvider =
    StateNotifierProvider<AchievementsNotifier, Set<String>>((ref) {
  return AchievementsNotifier();
});

class AchievementsNotifier extends StateNotifier<Set<String>> {
  AchievementsNotifier() : super({}) {
    // Initialize with current data
    refresh();
  }

  /// Refresh from AchievementService
  void refresh() {
    state = AchievementService.data.unlockedIds.toSet();
  }

  /// Add newly unlocked achievements
  void addUnlocked(List<String> ids) {
    state = {...state, ...ids};
  }

  /// Reset all
  void reset() {
    state = {};
  }

  /// Get unlocked count for available achievements
  int getUnlockedCount(List<Achievement> availableAchievements) {
    final availableIds = availableAchievements.map((a) => a.id).toSet();
    return state.where((id) => availableIds.contains(id)).length;
  }
}
