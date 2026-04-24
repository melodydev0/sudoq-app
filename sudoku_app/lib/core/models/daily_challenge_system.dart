import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

/// Daily Challenge completion data for a single day
class DailyCompletion {
  final DateTime date;
  final bool completed;
  final int? completionTimeSeconds;
  final int? mistakes;
  final int? score;

  const DailyCompletion({
    required this.date,
    required this.completed,
    this.completionTimeSeconds,
    this.mistakes,
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'completed': completed,
        'completionTimeSeconds': completionTimeSeconds,
        'mistakes': mistakes,
        'score': score,
      };

  factory DailyCompletion.fromJson(Map<String, dynamic> json) =>
      DailyCompletion(
        date: DateTime.parse(json['date']),
        completed: json['completed'] ?? false,
        completionTimeSeconds: json['completionTimeSeconds'],
        mistakes: json['mistakes'],
        score: json['score'],
      );
}

/// Monthly badge data
class MonthlyBadge {
  final int year;
  final int month;
  final int completedDays;
  final int totalDays;
  final bool isComplete;
  final DateTime? earnedAt;

  const MonthlyBadge({
    required this.year,
    required this.month,
    required this.completedDays,
    required this.totalDays,
    required this.isComplete,
    this.earnedAt,
  });

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  double get progress => totalDays > 0 ? completedDays / totalDays : 0.0;

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'completedDays': completedDays,
        'totalDays': totalDays,
        'isComplete': isComplete,
        'earnedAt': earnedAt?.toIso8601String(),
      };

  factory MonthlyBadge.fromJson(Map<String, dynamic> json) => MonthlyBadge(
        year: json['year'],
        month: json['month'],
        completedDays: json['completedDays'] ?? 0,
        totalDays: json['totalDays'] ?? 30,
        isComplete: json['isComplete'] ?? false,
        earnedAt:
            json['earnedAt'] != null ? DateTime.parse(json['earnedAt']) : null,
      );
}

/// Badge visual data for each month
class MonthBadgeInfo {
  final int month;
  final String nameKey;
  final IconData icon;
  final List<Color> gradientColors;
  final String emoji;
  final int xpReward;
  final String? frameRewardId;
  final String? titleRewardKey;

  const MonthBadgeInfo({
    required this.month,
    required this.nameKey,
    required this.icon,
    required this.gradientColors,
    required this.emoji,
    required this.xpReward,
    this.frameRewardId,
    this.titleRewardKey,
  });

  static const List<MonthBadgeInfo> allMonths = [
    // January - New Year / Rocket Launch
    MonthBadgeInfo(
      month: 1,
      nameKey: 'january',
      icon: Bootstrap.rocket_takeoff_fill,
      gradientColors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
      emoji: '🚀',
      xpReward: 500,
      titleRewardKey: 'newYearChampion',
    ),
    // February - Love / Heart
    MonthBadgeInfo(
      month: 2,
      nameKey: 'february',
      icon: Bootstrap.heart_fill,
      gradientColors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
      emoji: '💝',
      xpReward: 450,
    ),
    // March - Spring / Flower
    MonthBadgeInfo(
      month: 3,
      nameKey: 'march',
      icon: Bootstrap.flower1,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF81C784)],
      emoji: '🌸',
      xpReward: 500,
      frameRewardId: 'daily_frame_spring',
    ),
    // April - Rain / Diamond
    MonthBadgeInfo(
      month: 4,
      nameKey: 'april',
      icon: Bootstrap.gem,
      gradientColors: [Color(0xFF00BCD4), Color(0xFF80DEEA)],
      emoji: '💎',
      xpReward: 500,
    ),
    // May - Sun / Star
    MonthBadgeInfo(
      month: 5,
      nameKey: 'may',
      icon: Bootstrap.stars,
      gradientColors: [Color(0xFFFFEB3B), Color(0xFFFFF59D)],
      emoji: '⭐',
      xpReward: 500,
    ),
    // June - Summer / Fire
    MonthBadgeInfo(
      month: 6,
      nameKey: 'june',
      icon: Bootstrap.fire,
      gradientColors: [Color(0xFFFF5722), Color(0xFFFFAB91)],
      emoji: '🔥',
      xpReward: 500,
      titleRewardKey: 'summerWarrior',
      frameRewardId: 'daily_frame_summer',
    ),
    // July - Trophy
    MonthBadgeInfo(
      month: 7,
      nameKey: 'july',
      icon: Bootstrap.trophy_fill,
      gradientColors: [Color(0xFFFFD700), Color(0xFFFFE082)],
      emoji: '🏆',
      xpReward: 500,
    ),
    // August - Crown
    MonthBadgeInfo(
      month: 8,
      nameKey: 'august',
      icon: FontAwesome.crown_solid,
      gradientColors: [Color(0xFF9C27B0), Color(0xFFCE93D8)],
      emoji: '👑',
      xpReward: 500,
    ),
    // September - Leaf / Autumn
    MonthBadgeInfo(
      month: 9,
      nameKey: 'september',
      icon: Bootstrap.tree_fill,
      gradientColors: [Color(0xFFFF9800), Color(0xFFFFCC80)],
      emoji: '🍂',
      xpReward: 500,
      frameRewardId: 'daily_frame_autumn',
    ),
    // October - Moon / Halloween
    MonthBadgeInfo(
      month: 10,
      nameKey: 'october',
      icon: Bootstrap.moon_stars_fill,
      gradientColors: [Color(0xFF673AB7), Color(0xFFB39DDB)],
      emoji: '🎃',
      xpReward: 500,
    ),
    // November - Shield
    MonthBadgeInfo(
      month: 11,
      nameKey: 'november',
      icon: FontAwesome.shield_halved_solid,
      gradientColors: [Color(0xFF795548), Color(0xFFBCAAA4)],
      emoji: '🛡️',
      xpReward: 500,
    ),
    // December - Snowflake / Winter
    MonthBadgeInfo(
      month: 12,
      nameKey: 'december',
      icon: Bootstrap.snow2,
      gradientColors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
      emoji: '❄️',
      xpReward: 600,
      titleRewardKey: 'winterLegend',
      frameRewardId: 'daily_frame_winter',
    ),
  ];

  static MonthBadgeInfo getForMonth(int month) {
    return allMonths.firstWhere((b) => b.month == month,
        orElse: () => allMonths[0]);
  }
}

/// User's daily challenge data
class UserDailyData {
  final Map<String, DailyCompletion> completedDays; // key: "yyyy-MM-dd"
  final List<MonthlyBadge> earnedBadges;
  final int currentStreak;
  final int bestStreak;
  final int totalDaysCompleted;

  const UserDailyData({
    this.completedDays = const {},
    this.earnedBadges = const [],
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalDaysCompleted = 0,
  });

  /// Check if a specific day was completed
  bool isDayCompleted(DateTime date) {
    final key = _dateKey(date);
    return completedDays[key]?.completed ?? false;
  }

  /// Get completion for a specific day
  DailyCompletion? getCompletion(DateTime date) {
    final key = _dateKey(date);
    return completedDays[key];
  }

  /// Get completed days count for a month
  int getCompletedDaysInMonth(int year, int month) {
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

  /// Check if a month badge is earned
  bool hasMonthBadge(int year, int month) {
    return earnedBadges
        .any((b) => b.year == year && b.month == month && b.isComplete);
  }

  /// Get badge for specific month (safe: never throws)
  MonthlyBadge? getBadge(int year, int month) {
    for (final b in earnedBadges) {
      if (b.year == year && b.month == month) return b;
    }
    return null;
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  UserDailyData copyWith({
    Map<String, DailyCompletion>? completedDays,
    List<MonthlyBadge>? earnedBadges,
    int? currentStreak,
    int? bestStreak,
    int? totalDaysCompleted,
  }) {
    return UserDailyData(
      completedDays: completedDays ?? this.completedDays,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalDaysCompleted: totalDaysCompleted ?? this.totalDaysCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'completedDays': completedDays.map((k, v) => MapEntry(k, v.toJson())),
        'earnedBadges': earnedBadges.map((b) => b.toJson()).toList(),
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'totalDaysCompleted': totalDaysCompleted,
      };

  factory UserDailyData.fromJson(Map<String, dynamic> json) {
    final completedDaysMap = <String, DailyCompletion>{};
    if (json['completedDays'] != null) {
      (json['completedDays'] as Map<String, dynamic>).forEach((k, v) {
        completedDaysMap[k] = DailyCompletion.fromJson(v);
      });
    }

    final badges = <MonthlyBadge>[];
    if (json['earnedBadges'] != null) {
      for (var b in json['earnedBadges']) {
        badges.add(MonthlyBadge.fromJson(b));
      }
    }

    return UserDailyData(
      completedDays: completedDaysMap,
      earnedBadges: badges,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      totalDaysCompleted: json['totalDaysCompleted'] ?? 0,
    );
  }
}

/// Daily achievements
class DailyAchievements {
  static const List<DailyAchievementDef> all = [
    // Streak achievements
    DailyAchievementDef(
      id: 'daily_streak_3',
      titleKey: 'dailyStreak3',
      descriptionKey: 'dailyStreak3Desc',
      requirement: 3,
      xpReward: 30,
      category: DailyAchievementCategory.streak,
    ),
    DailyAchievementDef(
      id: 'daily_streak_7',
      titleKey: 'dailyStreak7',
      descriptionKey: 'dailyStreak7Desc',
      requirement: 7,
      xpReward: 70,
      category: DailyAchievementCategory.streak,
    ),
    DailyAchievementDef(
      id: 'daily_streak_14',
      titleKey: 'dailyStreak14',
      descriptionKey: 'dailyStreak14Desc',
      requirement: 14,
      xpReward: 150,
      category: DailyAchievementCategory.streak,
    ),
    DailyAchievementDef(
      id: 'daily_streak_30',
      titleKey: 'dailyStreak30',
      descriptionKey: 'dailyStreak30Desc',
      requirement: 30,
      xpReward: 300,
      category: DailyAchievementCategory.streak,
      frameRewardId: 'daily_frame_dedicated',
    ),
    DailyAchievementDef(
      id: 'daily_streak_60',
      titleKey: 'dailyStreak60',
      descriptionKey: 'dailyStreak60Desc',
      requirement: 60,
      xpReward: 600,
      category: DailyAchievementCategory.streak,
    ),
    DailyAchievementDef(
      id: 'daily_streak_100',
      titleKey: 'dailyStreak100',
      descriptionKey: 'dailyStreak100Desc',
      requirement: 100,
      xpReward: 1000,
      category: DailyAchievementCategory.streak,
      titleRewardKey: 'dailyLegend',
      frameRewardId: 'daily_frame_legend',
    ),

    // Total completion achievements
    DailyAchievementDef(
      id: 'daily_total_10',
      titleKey: 'dailyTotal10',
      descriptionKey: 'dailyTotal10Desc',
      requirement: 10,
      xpReward: 50,
      category: DailyAchievementCategory.total,
    ),
    DailyAchievementDef(
      id: 'daily_total_30',
      titleKey: 'dailyTotal30',
      descriptionKey: 'dailyTotal30Desc',
      requirement: 30,
      xpReward: 150,
      category: DailyAchievementCategory.total,
    ),
    DailyAchievementDef(
      id: 'daily_total_100',
      titleKey: 'dailyTotal100',
      descriptionKey: 'dailyTotal100Desc',
      requirement: 100,
      xpReward: 500,
      category: DailyAchievementCategory.total,
    ),
    DailyAchievementDef(
      id: 'daily_total_365',
      titleKey: 'dailyTotal365',
      descriptionKey: 'dailyTotal365Desc',
      requirement: 365,
      xpReward: 2000,
      category: DailyAchievementCategory.total,
      titleRewardKey: 'yearRoundPlayer',
      frameRewardId: 'daily_frame_yearly',
    ),

    // Monthly badge achievements
    DailyAchievementDef(
      id: 'daily_badges_1',
      titleKey: 'dailyBadges1',
      descriptionKey: 'dailyBadges1Desc',
      requirement: 1,
      xpReward: 100,
      category: DailyAchievementCategory.badges,
    ),
    DailyAchievementDef(
      id: 'daily_badges_3',
      titleKey: 'dailyBadges3',
      descriptionKey: 'dailyBadges3Desc',
      requirement: 3,
      xpReward: 300,
      category: DailyAchievementCategory.badges,
    ),
    DailyAchievementDef(
      id: 'daily_badges_6',
      titleKey: 'dailyBadges6',
      descriptionKey: 'dailyBadges6Desc',
      requirement: 6,
      xpReward: 600,
      category: DailyAchievementCategory.badges,
      frameRewardId: 'daily_frame_collector',
    ),
    DailyAchievementDef(
      id: 'daily_badges_12',
      titleKey: 'dailyBadges12',
      descriptionKey: 'dailyBadges12Desc',
      requirement: 12,
      xpReward: 1500,
      category: DailyAchievementCategory.badges,
      titleRewardKey: 'badgeMaster',
      frameRewardId: 'daily_frame_master',
    ),
  ];

  static DailyAchievementDef? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

enum DailyAchievementCategory { streak, total, badges }

class DailyAchievementDef {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final int requirement;
  final int xpReward;
  final DailyAchievementCategory category;
  final String? frameRewardId;
  final String? titleRewardKey;

  const DailyAchievementDef({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.requirement,
    required this.xpReward,
    required this.category,
    this.frameRewardId,
    this.titleRewardKey,
  });
}
