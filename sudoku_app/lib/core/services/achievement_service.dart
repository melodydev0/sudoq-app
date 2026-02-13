import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/statistics.dart';
import 'local_duel_stats_service.dart';

/// Service for managing achievements
class AchievementService {
  static const String _achievementsKey = 'user_achievements';

  static SharedPreferences? _prefs;
  static UserAchievements? _cachedData;

  /// Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
  }

  static Future<void> _loadData() async {
    final jsonStr = _prefs?.getString(_achievementsKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedData = UserAchievements.fromJson(json);
      } catch (e) {
        _cachedData = const UserAchievements();
      }
    } else {
      _cachedData = const UserAchievements();
    }
  }

  static Future<void> _saveData() async {
    if (_cachedData != null) {
      final jsonStr = jsonEncode(_cachedData!.toJson());
      await _prefs?.setString(_achievementsKey, jsonStr);
    }
  }

  /// Get current achievements data
  static UserAchievements get data => _cachedData ?? const UserAchievements();

  /// Check if an achievement is unlocked
  static bool isUnlocked(String achievementId) {
    return data.unlockedIds.contains(achievementId);
  }

  /// Check and unlock achievements after a game win
  static Future<AchievementCheckResult> checkAfterWin({
    required Statistics stats,
    required String difficulty,
    required int completionTimeSeconds,
    required bool isPerfect,
    required bool isDailyChallenge,
    bool isDuel = false, // Whether this is a duel game
  }) async {
    final newlyUnlocked = <Achievement>[];
    var currentData = _cachedData ?? const UserAchievements();

    // Update difficulty wins
    final diffWins = Map<String, int>.from(currentData.difficultyWins);
    diffWins[difficulty] = (diffWins[difficulty] ?? 0) + 1;

    // Update fastest times
    final fastestTimes = Map<String, int>.from(currentData.fastestTimes);
    final currentFastest = fastestTimes[difficulty] ?? 999999;
    if (completionTimeSeconds < currentFastest) {
      fastestTimes[difficulty] = completionTimeSeconds;
    }

    // Update daily completed
    int dailyCompleted = currentData.totalDailyCompleted;
    if (isDailyChallenge) {
      dailyCompleted++;
    }

    // Update expert perfect wins
    int expertPerfect = currentData.expertPerfectWins;
    if (difficulty == 'Expert' && isPerfect) {
      expertPerfect++;
    }

    currentData = currentData.copyWith(
      difficultyWins: diffWins,
      fastestTimes: fastestTimes,
      totalDailyCompleted: dailyCompleted,
      expertPerfectWins: expertPerfect,
    );

    // Check WIN achievements
    for (var achievement in Achievements.winAchievements) {
      if (!currentData.unlockedIds.contains(achievement.id) &&
          stats.totalGamesWon >= achievement.targetValue) {
        newlyUnlocked.add(achievement);
      }
    }

    // Check PERFECT achievements
    for (var achievement in Achievements.perfectAchievements) {
      if (!currentData.unlockedIds.contains(achievement.id) &&
          stats.perfectGames >= achievement.targetValue) {
        newlyUnlocked.add(achievement);
      }
    }

    // Check STREAK achievements
    for (var achievement in Achievements.streakAchievements) {
      if (!currentData.unlockedIds.contains(achievement.id) &&
          stats.bestStreak >= achievement.targetValue) {
        newlyUnlocked.add(achievement);
      }
    }

    // Check SPEED achievements
    _checkSpeedAchievement(
        newlyUnlocked, currentData, 'Easy', 'speed_easy_3min', fastestTimes);
    _checkSpeedAchievement(newlyUnlocked, currentData, 'Medium',
        'speed_medium_8min', fastestTimes);
    _checkSpeedAchievement(
        newlyUnlocked, currentData, 'Hard', 'speed_hard_15min', fastestTimes);
    _checkSpeedAchievement(newlyUnlocked, currentData, 'Expert',
        'speed_expert_25min', fastestTimes);

    // Check ALL difficulty-based achievements (easy_5, easy_10, expert_10, expert_master, etc.)
    const difficultyAchievementIds = [
      'easy_5',
      'easy_10',
      'easy_50',
      'easy_100',
      'easy_master',
      'medium_5',
      'medium_10',
      'medium_50',
      'medium_master',
      'hard_5',
      'hard_20',
      'hard_master',
      'expert_10',
      'expert_master',
    ];
    for (final achievementId in difficultyAchievementIds) {
      _checkDifficultyMaster(newlyUnlocked, currentData,
          _difficultyFromAchievementId(achievementId), achievementId, diffWins);
    }

    // Check expert perfect achievement
    if (!currentData.unlockedIds.contains('expert_perfect') &&
        expertPerfect >= 1) {
      final achievement = Achievements.getById('expert_perfect');
      if (achievement != null) {
        newlyUnlocked.add(achievement);
      }
    }

    // Check DAILY achievements
    for (var achievement in Achievements.dailyAchievements) {
      if (!currentData.unlockedIds.contains(achievement.id) &&
          dailyCompleted >= achievement.targetValue) {
        newlyUnlocked.add(achievement);
      }
    }

    // Calculate total XP bonus
    int totalXpBonus = 0;
    final updatedUnlockedIds = List<String>.from(currentData.unlockedIds);

    for (var achievement in newlyUnlocked) {
      totalXpBonus += achievement.xpReward;
      updatedUnlockedIds.add(achievement.id);
    }

    // Update and save data
    final updatedData = currentData.copyWith(unlockedIds: updatedUnlockedIds);
    _cachedData = updatedData;
    await _saveData();

    return AchievementCheckResult(
      newlyUnlocked: newlyUnlocked,
      totalXpBonus: totalXpBonus,
      updatedData: updatedData,
    );
  }

  /// Max time in seconds for speed achievements (e.g. 25 min = 1500)
  static int? _speedAchievementMaxSeconds(String achievementId) {
    switch (achievementId) {
      case 'speed_easy_3min':
        return 180;
      case 'speed_medium_8min':
        return 480;
      case 'speed_hard_15min':
        return 900;
      case 'speed_expert_25min':
        return 1500;
      default:
        return null;
    }
  }

  static void _checkSpeedAchievement(
    List<Achievement> newlyUnlocked,
    UserAchievements data,
    String difficulty,
    String achievementId,
    Map<String, int> fastestTimes,
  ) {
    if (data.unlockedIds.contains(achievementId)) return;

    final achievement = Achievements.getById(achievementId);
    if (achievement == null) return;

    final maxSeconds = _speedAchievementMaxSeconds(achievementId);
    if (maxSeconds == null) return;

    final fastestTime = fastestTimes[difficulty];
    if (fastestTime != null && fastestTime <= maxSeconds) {
      newlyUnlocked.add(achievement);
    }
  }

  static String _difficultyFromAchievementId(String achievementId) {
    if (achievementId.startsWith('easy_')) return 'Easy';
    if (achievementId.startsWith('medium_')) return 'Medium';
    if (achievementId.startsWith('hard_')) return 'Hard';
    if (achievementId.startsWith('expert_')) return 'Expert';
    return 'Easy';
  }

  static void _checkDifficultyMaster(
    List<Achievement> newlyUnlocked,
    UserAchievements data,
    String difficulty,
    String achievementId,
    Map<String, int> diffWins,
  ) {
    if (data.unlockedIds.contains(achievementId)) return;

    final achievement = Achievements.getById(achievementId);
    if (achievement == null) return;

    final wins = diffWins[difficulty] ?? 0;
    if (wins >= achievement.targetValue) {
      newlyUnlocked.add(achievement);
    }
  }

  /// Get progress for an achievement (0.0 to 1.0)
  static double getProgress(Achievement achievement, Statistics stats) {
    final id = achievement.id;

    // Win achievements
    if (id.startsWith('first_win') || id.startsWith('win_')) {
      return (stats.totalGamesWon / achievement.targetValue).clamp(0.0, 1.0);
    }
    // Perfect game achievements
    if (id.startsWith('first_perfect') || id.startsWith('perfect_')) {
      return (stats.perfectGames / achievement.targetValue).clamp(0.0, 1.0);
    }
    // Streak achievements
    if (id.startsWith('streak_')) {
      return (stats.bestStreak / achievement.targetValue).clamp(0.0, 1.0);
    }
    // Daily achievements
    if (id.startsWith('daily_')) {
      return (data.totalDailyCompleted / achievement.targetValue)
          .clamp(0.0, 1.0);
    }
    // Difficulty achievements (easy_5, medium_10, etc.)
    if (id.startsWith('easy_') ||
        id.startsWith('medium_') ||
        id.startsWith('hard_') ||
        id.startsWith('expert_')) {
      final wins = data.difficultyWins[_getDifficultyForAchievement(id)] ?? 0;
      return (wins / achievement.targetValue).clamp(0.0, 1.0);
    }
    // Speed achievements
    if (id.startsWith('speed_')) {
      final fastestTime = data.fastestTimes[_getDifficultyForAchievement(id)];
      if (fastestTime == null) return 0.0;
      if (fastestTime <= achievement.targetValue) return 1.0;
      return (achievement.targetValue / fastestTime).clamp(0.0, 1.0);
    }

    return 0.0;
  }

  static String _getDifficultyForAchievement(String achievementId) {
    if (achievementId.contains('easy')) return 'Easy';
    if (achievementId.contains('medium')) return 'Medium';
    if (achievementId.contains('hard')) return 'Hard';
    if (achievementId.contains('expert')) return 'Expert';
    return 'Easy';
  }

  /// Get list of unlocked achievement IDs (for cloud sync)
  static List<String> get unlockedAchievementIds => data.unlockedIds;

  /// Get all progress data (for cloud sync)
  static Map<String, dynamic> getAllProgress() {
    return {
      'difficultyWins': data.difficultyWins,
      'fastestTimes': data.fastestTimes,
      'totalDailyCompleted': data.totalDailyCompleted,
      'expertPerfectWins': data.expertPerfectWins,
    };
  }

  /// Unlock a specific achievement by ID (for cloud sync import)
  static Future<void> unlockAchievement(String achievementId) async {
    if (data.unlockedIds.contains(achievementId)) return;

    final updatedIds = List<String>.from(data.unlockedIds)..add(achievementId);
    _cachedData = data.copyWith(unlockedIds: updatedIds);
    await _saveData();
  }

  /// Check and unlock duel achievements after a duel win
  static Future<AchievementCheckResult> checkAfterDuelWin() async {
    final newlyUnlocked = <Achievement>[];
    var currentData = _cachedData ?? const UserAchievements();

    // Get duel stats
    final duelWins = LocalDuelStatsService.wins;
    final duelStreak = LocalDuelStatsService.winStreak;
    final duelBestStreak = LocalDuelStatsService.bestStreak;
    final duelElo = LocalDuelStatsService.elo;

    // Check DUEL WIN achievements
    final duelWinAchievements = [
      'duel_first_win',
      'duel_win_10',
      'duel_win_50',
      'duel_win_100',
      'duel_win_500'
    ];
    for (var achievementId in duelWinAchievements) {
      if (!currentData.unlockedIds.contains(achievementId)) {
        final achievement = Achievements.getById(achievementId);
        if (achievement != null && duelWins >= achievement.targetValue) {
          newlyUnlocked.add(achievement);
        }
      }
    }

    // Check DUEL STREAK achievements
    final duelStreakAchievements = [
      'duel_streak_3',
      'duel_streak_5',
      'duel_streak_10'
    ];
    final streakToCheck =
        duelBestStreak > duelStreak ? duelBestStreak : duelStreak;
    for (var achievementId in duelStreakAchievements) {
      if (!currentData.unlockedIds.contains(achievementId)) {
        final achievement = Achievements.getById(achievementId);
        if (achievement != null && streakToCheck >= achievement.targetValue) {
          newlyUnlocked.add(achievement);
        }
      }
    }

    // Check DIVISION achievements (ELO-based)
    final divisionAchievements = [
      'duel_silver',
      'duel_gold',
      'duel_platinum',
      'duel_diamond',
      'duel_master',
      'duel_grandmaster',
      'duel_champion'
    ];
    for (var achievementId in divisionAchievements) {
      if (!currentData.unlockedIds.contains(achievementId)) {
        final achievement = Achievements.getById(achievementId);
        if (achievement != null && duelElo >= achievement.targetValue) {
          newlyUnlocked.add(achievement);
        }
      }
    }

    // Calculate total XP bonus
    int totalXpBonus = 0;
    final updatedUnlockedIds = List<String>.from(currentData.unlockedIds);

    for (var achievement in newlyUnlocked) {
      totalXpBonus += achievement.xpReward;
      updatedUnlockedIds.add(achievement.id);
    }

    // Update and save data
    final updatedData = currentData.copyWith(unlockedIds: updatedUnlockedIds);
    _cachedData = updatedData;
    await _saveData();

    return AchievementCheckResult(
      newlyUnlocked: newlyUnlocked,
      totalXpBonus: totalXpBonus,
      updatedData: updatedData,
    );
  }

  /// Get duel achievement progress
  static double getDuelProgress(Achievement achievement) {
    final id = achievement.id;

    // Duel win achievements
    if (id.startsWith('duel_win') || id == 'duel_first_win') {
      return (LocalDuelStatsService.wins / achievement.targetValue)
          .clamp(0.0, 1.0);
    }
    // Duel streak achievements
    if (id.startsWith('duel_streak')) {
      final bestStreak = LocalDuelStatsService.bestStreak;
      return (bestStreak / achievement.targetValue).clamp(0.0, 1.0);
    }
    // Division achievements (ELO-based)
    if (id.startsWith('duel_') &&
        (id.contains('silver') ||
            id.contains('gold') ||
            id.contains('platinum') ||
            id.contains('diamond') ||
            id.contains('master') ||
            id.contains('grandmaster') ||
            id.contains('champion'))) {
      return (LocalDuelStatsService.elo / achievement.targetValue)
          .clamp(0.0, 1.0);
    }

    return 0.0;
  }

  /// Reset all achievements (for testing)
  static Future<void> reset() async {
    _cachedData = const UserAchievements();
    await _saveData();
  }

  /// Unlock all achievements (for testing)
  static Future<void> unlockAll() async {
    // Use Achievements.all - same list used by checkAfterWin
    final availableIds = Achievements.all.map((a) => a.id).toList();

    _cachedData = UserAchievements(
      unlockedIds: availableIds,
      totalDailyCompleted: 100,
      fastestTimes: {
        'Easy': 60, // 1 min
        'Medium': 180, // 3 min
        'Hard': 300, // 5 min
        'Expert': 600, // 10 min
      },
      difficultyWins: {
        'Easy': 100,
        'Medium': 100,
        'Hard': 100,
        'Expert': 100,
      },
      expertPerfectWins: 50,
    );
    await _saveData();
  }
}
