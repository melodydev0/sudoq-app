import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge_system.dart';
import 'global_stats_service.dart';
import 'level_service.dart';

/// Service for managing daily challenges
class DailyChallengeService {
  static const String _dataKey = 'user_daily_data';

  static SharedPreferences? _prefs;
  static UserDailyData? _cachedData;

  /// Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
  }

  static Future<void> _loadData() async {
    final jsonStr = _prefs?.getString(_dataKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedData = UserDailyData.fromJson(json);
      } catch (e) {
        _cachedData = const UserDailyData();
      }
    } else {
      _cachedData = const UserDailyData();
    }
  }

  static Future<void> _saveData() async {
    if (_cachedData != null) {
      final jsonStr = jsonEncode(_cachedData!.toJson());
      await _prefs?.setString(_dataKey, jsonStr);
    }
  }

  /// Get current data
  static UserDailyData get data => _cachedData ?? const UserDailyData();

  /// Record a daily challenge completion
  static Future<DailyCompletionResult> recordCompletion({
    required DateTime date,
    required int completionTimeSeconds,
    required int mistakes,
    required int score,
  }) async {
    final currentData = _cachedData ?? const UserDailyData();

    // Create completion record
    final dateKey = _dateKey(date);
    final completion = DailyCompletion(
      date: date,
      completed: true,
      completionTimeSeconds: completionTimeSeconds,
      mistakes: mistakes,
      score: score,
    );

    // Update completed days map
    final newCompletedDays =
        Map<String, DailyCompletion>.from(currentData.completedDays);
    newCompletedDays[dateKey] = completion;

    // Calculate new streak
    int newStreak = _calculateStreak(newCompletedDays, date);
    int newBestStreak =
        newStreak > currentData.bestStreak ? newStreak : currentData.bestStreak;

    // Count total completed
    int totalCompleted =
        newCompletedDays.values.where((c) => c.completed).length;

    // Check if month badge should be awarded
    MonthlyBadge? newBadge;
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final completedInMonth =
        _countCompletedInMonth(newCompletedDays, date.year, date.month);

    List<MonthlyBadge> newBadges = List.from(currentData.earnedBadges);

    // Check if this completes the month
    if (completedInMonth == daysInMonth) {
      final existingBadge = newBadges
          .indexWhere((b) => b.year == date.year && b.month == date.month);
      if (existingBadge == -1) {
        newBadge = MonthlyBadge(
          year: date.year,
          month: date.month,
          completedDays: completedInMonth,
          totalDays: daysInMonth,
          isComplete: true,
          earnedAt: DateTime.now(),
        );
        newBadges.add(newBadge);
      }
    }

    // Update data
    _cachedData = currentData.copyWith(
      completedDays: newCompletedDays,
      earnedBadges: newBadges,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      totalDaysCompleted: totalCompleted,
    );

    await _saveData();

    // Report to global stats service
    await GlobalStatsService.instance.reportCompletion(
      date: date,
      completionTimeSeconds: completionTimeSeconds,
      mistakes: mistakes,
      score: score,
    );

    // Check for new achievements
    final newAchievements = _checkAchievements(currentData, _cachedData!);

    // Unlock frame/title rewards from achievements and badge
    await _unlockRewards(newBadge, newAchievements);

    return DailyCompletionResult(
      completion: completion,
      newStreak: newStreak,
      isNewBestStreak: newStreak > currentData.bestStreak,
      newBadge: newBadge,
      newAchievements: newAchievements,
      totalXpEarned: _calculateXpEarned(newBadge, newAchievements),
    );
  }

  /// Calculate current streak from completed days
  static int _calculateStreak(
      Map<String, DailyCompletion> completedDays, DateTime fromDate) {
    int streak = 0;
    DateTime checkDate = DateTime(fromDate.year, fromDate.month, fromDate.day);

    while (true) {
      final key = _dateKey(checkDate);
      if (completedDays[key]?.completed == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Count completed days in a month
  static int _countCompletedInMonth(
      Map<String, DailyCompletion> completedDays, int year, int month) {
    int count = 0;
    completedDays.forEach((key, completion) {
      if (completion.completed &&
          completion.date.year == year &&
          completion.date.month == month) {
        count++;
      }
    });
    return count;
  }

  /// Check for new achievements
  static List<DailyAchievementDef> _checkAchievements(
      UserDailyData oldData, UserDailyData newData) {
    final newAchievements = <DailyAchievementDef>[];

    for (var achievement in DailyAchievements.all) {
      // Skip if already unlocked (would need to track this in a separate list)

      bool wasUnlocked = false;
      bool isNowUnlocked = false;

      switch (achievement.category) {
        case DailyAchievementCategory.streak:
          wasUnlocked = oldData.bestStreak >= achievement.requirement;
          isNowUnlocked = newData.bestStreak >= achievement.requirement;
          break;
        case DailyAchievementCategory.total:
          wasUnlocked = oldData.totalDaysCompleted >= achievement.requirement;
          isNowUnlocked = newData.totalDaysCompleted >= achievement.requirement;
          break;
        case DailyAchievementCategory.badges:
          wasUnlocked =
              oldData.earnedBadges.where((b) => b.isComplete).length >=
                  achievement.requirement;
          isNowUnlocked =
              newData.earnedBadges.where((b) => b.isComplete).length >=
                  achievement.requirement;
          break;
      }

      if (!wasUnlocked && isNowUnlocked) {
        newAchievements.add(achievement);
      }
    }

    return newAchievements;
  }

  /// Calculate XP earned from completion
  static int _calculateXpEarned(
      MonthlyBadge? newBadge, List<DailyAchievementDef> achievements) {
    int xp = 0;

    // XP from badge
    if (newBadge != null) {
      final badgeInfo = MonthBadgeInfo.getForMonth(newBadge.month);
      xp += badgeInfo.xpReward;
    }

    // XP from achievements
    for (var achievement in achievements) {
      xp += achievement.xpReward;
    }

    return xp;
  }

  /// Get days in a month
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get month progress
  static MonthProgress getMonthProgress(int year, int month) {
    final data = _cachedData ?? const UserDailyData();
    final daysInMonth = getDaysInMonth(year, month);
    final completedDays = data.getCompletedDaysInMonth(year, month);
    final badge = data.getBadge(year, month);

    return MonthProgress(
      year: year,
      month: month,
      totalDays: daysInMonth,
      completedDays: completedDays,
      isComplete: completedDays == daysInMonth,
      badge: badge,
    );
  }

  /// Check if a date can be played (not in the future and not before 2025)
  static bool canPlayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    final minDate = DateTime(2025, 1, 1);
    return !checkDate.isAfter(today) && !checkDate.isBefore(minDate);
  }

  /// Check if a date was completed
  static bool isDateCompleted(DateTime date) {
    return data.isDayCompleted(date);
  }

  /// Get all earned badges (only 2025 and onwards)
  static List<MonthlyBadge> get earnedBadges =>
      data.earnedBadges.where((b) => b.year >= 2025).toList();

  /// Get current streak
  static int get currentStreak => data.currentStreak;

  /// Get best streak
  static int get bestStreak => data.bestStreak;

  /// Get total days completed
  static int get totalDaysCompleted => data.totalDaysCompleted;

  /// Import full daily data from a JSON map (for cross-device sync)
  static Future<void> importFromJson(Map<String, dynamic> json) async {
    try {
      final imported = UserDailyData.fromJson(json);
      _cachedData = imported;
      await _saveData();
    } catch (e) {
      // Silently ignore malformed data
    }
  }

  /// Reset all data (for testing)
  static Future<void> reset() async {
    _cachedData = const UserDailyData();
    await _saveData();
  }

  /// Set max progress for testing
  static Future<void> setMaxProgress() async {
    final now = DateTime.now();
    final completedDays = <String, DailyCompletion>{};
    final badges = <MonthlyBadge>[];

    // Complete all days from January 2025 until today
    final startDate = DateTime(2025, 1, 1);
    DateTime date = startDate;

    while (!date.isAfter(now)) {
      final key = _dateKey(date);
      completedDays[key] = DailyCompletion(
        date: date,
        completed: true,
        completionTimeSeconds: 180,
        mistakes: 0,
        score: 1000,
      );
      date = date.add(const Duration(days: 1));
    }

    // Add badges for 2025 (all 12 months completed)
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = getDaysInMonth(2025, month);
      badges.add(MonthlyBadge(
        year: 2025,
        month: month,
        completedDays: daysInMonth,
        totalDays: daysInMonth,
        isComplete: true,
        earnedAt: DateTime(2025, month, daysInMonth),
      ));
    }

    _cachedData = UserDailyData(
      completedDays: completedDays,
      earnedBadges: badges,
      currentStreak: 100,
      bestStreak: 100,
      totalDaysCompleted: completedDays.length,
    );

    await _saveData();
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Unlock cosmetic frame/title rewards from badge completions and achievements.
  /// Adds the reward IDs to LevelService.unlockedRewards so they appear in
  /// RewardsScreen and can be equipped.
  static Future<void> _unlockRewards(
    MonthlyBadge? newBadge,
    List<DailyAchievementDef> newAchievements,
  ) async {
    final toUnlock = <String>[];

    // Frame from monthly badge (e.g. daily_frame_spring)
    if (newBadge != null) {
      final badgeInfo = MonthBadgeInfo.getForMonth(newBadge.month);
      if (badgeInfo.frameRewardId != null) {
        toUnlock.add(badgeInfo.frameRewardId!);
      }
    }

    // Frame/title from daily achievement (e.g. daily_frame_dedicated, badgeMaster)
    for (final achievement in newAchievements) {
      if (achievement.frameRewardId != null) {
        toUnlock.add(achievement.frameRewardId!);
      }
    }

    if (toUnlock.isNotEmpty) {
      await LevelService.addUnlockedRewards(toUnlock);
    }
  }
}

/// Result of a daily completion
class DailyCompletionResult {
  final DailyCompletion completion;
  final int newStreak;
  final bool isNewBestStreak;
  final MonthlyBadge? newBadge;
  final List<DailyAchievementDef> newAchievements;
  final int totalXpEarned;

  const DailyCompletionResult({
    required this.completion,
    required this.newStreak,
    required this.isNewBestStreak,
    this.newBadge,
    this.newAchievements = const [],
    this.totalXpEarned = 0,
  });
}

/// Month progress info
class MonthProgress {
  final int year;
  final int month;
  final int totalDays;
  final int completedDays;
  final bool isComplete;
  final MonthlyBadge? badge;

  const MonthProgress({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.completedDays,
    required this.isComplete,
    this.badge,
  });

  double get progress => totalDays > 0 ? completedDays / totalDays : 0.0;
}
