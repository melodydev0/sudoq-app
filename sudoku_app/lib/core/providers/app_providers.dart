import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../models/statistics.dart';
import '../models/achievement.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/sudoku_generator.dart';
import '../services/achievement_service.dart';

/// Sudoku generator provider
final sudokuGeneratorProvider = Provider<SudokuGenerator>((ref) {
  return SudokuGenerator();
});

// ===== SETTINGS =====

/// Settings notifier — Riverpod 2.x Notifier
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => StorageService.getSettings();

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    await StorageService.saveSettings(settings);
  }

  Future<void> toggleDarkMode() async {
    await updateSettings(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  Future<void> toggleSound() async {
    final newEnabled = !state.soundEnabled;
    await updateSettings(state.copyWith(soundEnabled: newEnabled));
    await SoundService().setSoundEnabled(newEnabled);
  }

  Future<void> toggleVibration() async {
    await updateSettings(
        state.copyWith(vibrationEnabled: !state.vibrationEnabled));
  }

  Future<void> setDefaultDifficulty(String difficulty) async {
    await updateSettings(state.copyWith(defaultDifficulty: difficulty));
  }

  Future<void> setLanguage(String languageCode) async {
    await updateSettings(state.copyWith(languageCode: languageCode));
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ===== STATISTICS =====

/// Statistics notifier — Riverpod 2.x Notifier
class StatisticsNotifier extends Notifier<Statistics> {
  @override
  Statistics build() => StorageService.getStatistics();

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

    final today = _todayString();
    final uniqueDays = List<String>.from(state.uniqueDaysPlayed);
    if (!uniqueDays.contains(today)) uniqueDays.add(today);

    await updateStatistics(state.copyWith(
      totalGamesPlayed: state.totalGamesPlayed + 1,
      totalGamesWon: state.totalGamesWon + 1,
      currentStreak: state.currentStreak + 1,
      bestStreak: (state.currentStreak + 1) > state.bestStreak
          ? state.currentStreak + 1
          : state.bestStreak,
      totalPlayTime: state.totalPlayTime + time,
      perfectGames: isPerfect ? state.perfectGames + 1 : state.perfectGames,
      lastPlayedDate: DateTime.now(),
      difficultyStats: {...state.difficultyStats, difficulty: newDiffStats},
      uniqueDaysPlayed: uniqueDays,
      totalDailyChallengesCompleted: isDailyChallenge
          ? state.totalDailyChallengesCompleted + 1
          : state.totalDailyChallengesCompleted,
    ));
  }

  Future<void> recordGameLost({
    required String difficulty,
    required int time,
  }) async {
    final diffStats = state.difficultyStats[difficulty] ?? DifficultyStats();
    final today = _todayString();
    final uniqueDays = List<String>.from(state.uniqueDaysPlayed);
    if (!uniqueDays.contains(today)) uniqueDays.add(today);

    await updateStatistics(state.copyWith(
      totalGamesPlayed: state.totalGamesPlayed + 1,
      totalGamesLost: state.totalGamesLost + 1,
      currentStreak: 0,
      totalPlayTime: state.totalPlayTime + time,
      lastPlayedDate: DateTime.now(),
      difficultyStats: {
        ...state.difficultyStats,
        difficulty: diffStats.copyWith(gamesPlayed: diffStats.gamesPlayed + 1),
      },
      uniqueDaysPlayed: uniqueDays,
    ));
  }

  Future<void> recordHintUsed() async {
    await updateStatistics(
        state.copyWith(totalHintsUsed: state.totalHintsUsed + 1));
  }

  Future<void> reset() async {
    state = Statistics();
    await StorageService.saveStatistics(state);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final statisticsProvider =
    NotifierProvider<StatisticsNotifier, Statistics>(StatisticsNotifier.new);

// ===== SIMPLE STATE PROVIDERS =====

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
final selectedFrameProvider =
    StateProvider<String>((ref) => 'frame_basic');

final selectedThemeProvider =
    StateProvider<String>((ref) => 'theme_default');

final selectedEffectProvider =
    StateProvider<String>((ref) => 'effect_none');

// ===== ACHIEVEMENTS =====

/// Achievements notifier — Riverpod 2.x Notifier
class AchievementsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final ids = AchievementService.data.unlockedIds.toSet();
    return ids;
  }

  void refresh() {
    state = AchievementService.data.unlockedIds.toSet();
  }

  void addUnlocked(List<String> ids) {
    state = {...state, ...ids};
  }

  void reset() {
    state = {};
  }

  int getUnlockedCount(List<Achievement> availableAchievements) {
    final availableIds = availableAchievements.map((a) => a.id).toSet();
    return state.where((id) => availableIds.contains(id)).length;
  }
}

final achievementsDataProvider =
    NotifierProvider<AchievementsNotifier, Set<String>>(
        AchievementsNotifier.new);
