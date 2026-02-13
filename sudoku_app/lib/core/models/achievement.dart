import 'dart:ui' show Color;

/// Achievement categories based on XP tiers
enum AchievementCategory {
  seedling, // 25-50 XP - Beginner tier
  rising, // 75-100 XP - Intermediate tier
  skilled, // 150-200 XP - Advanced tier
  elite, // 250-350 XP - Expert tier
  legendary, // 500-1000 XP - Master tier
  duel, // ⚔️ Duel achievements - High XP rewards!
}

/// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final bool isComingSoon;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 0,
    this.isComingSoon = false,
  });

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  /// Backwards compatibility - returns title
  String get nameKey => title;

  /// Get color based on XP reward tier
  Color get color {
    if (xpReward >= 500) return const Color(0xFFFFD700); // Gold
    if (xpReward >= 200) return const Color(0xFF9C27B0); // Purple
    if (xpReward >= 100) return const Color(0xFF2196F3); // Blue
    if (xpReward >= 50) return const Color(0xFF4CAF50); // Green
    return const Color(0xFF607D8B); // Grey-blue
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementCategory? category,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    bool? isComingSoon,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      isComingSoon: isComingSoon ?? this.isComingSoon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
      'isComingSoon': isComingSoon,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: AchievementCategory.values.byName(json['category'] as String),
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      xpReward: json['xpReward'] as int? ?? 0,
      isComingSoon: json['isComingSoon'] as bool? ?? false,
    );
  }
}

/// Predefined achievements organized by XP tiers
class Achievements {
  static List<Achievement> getDefaultAchievements() {
    return [
      // ============ SEEDLING TIER (25-50 XP) - Easy achievements ============
      // First Win
      Achievement(
        id: 'first_win',
        title: 'First Victory',
        description: 'Win your first game',
        icon: '🎯',
        category: AchievementCategory.seedling,
        targetValue: 1,
        xpReward: 25,
      ),
      Achievement(
        id: 'easy_5',
        title: 'First Steps',
        description: 'Complete 5 easy puzzles',
        icon: '🌱',
        category: AchievementCategory.seedling,
        targetValue: 5,
        xpReward: 30,
      ),
      Achievement(
        id: 'easy_10',
        title: 'Getting Warmed Up',
        description: 'Complete 10 easy puzzles',
        icon: '🎯',
        category: AchievementCategory.seedling,
        targetValue: 10,
        xpReward: 50,
      ),
      Achievement(
        id: 'medium_5',
        title: 'Rising Star',
        description: 'Complete 5 medium puzzles',
        icon: '⭐',
        category: AchievementCategory.seedling,
        targetValue: 5,
        xpReward: 40,
      ),
      Achievement(
        id: 'hints_10',
        title: 'Hint Seeker',
        description: 'Use 10 hints total',
        icon: '💡',
        category: AchievementCategory.seedling,
        targetValue: 10,
        xpReward: 30,
      ),
      // Win Streak
      Achievement(
        id: 'streak_3',
        title: 'Hot Streak',
        description: 'Win 3 games in a row',
        icon: '🔥',
        category: AchievementCategory.seedling,
        targetValue: 3,
        xpReward: 30,
      ),
      // Speed Achievement
      Achievement(
        id: 'speed_easy_3min',
        title: 'Speed Demon',
        description: 'Complete easy puzzle under 3 minutes',
        icon: '⚡',
        category: AchievementCategory.seedling,
        targetValue: 1,
        xpReward: 40,
      ),

      // ============ RISING TIER (75-100 XP) - Intermediate achievements ============
      // Wins
      Achievement(
        id: 'win_10',
        title: 'Dedicated Player',
        description: 'Win 10 games',
        icon: '🏅',
        category: AchievementCategory.rising,
        targetValue: 10,
        xpReward: 50,
      ),
      // First Perfect
      Achievement(
        id: 'first_perfect',
        title: 'Flawless',
        description: 'Complete a game without mistakes',
        icon: '✨',
        category: AchievementCategory.rising,
        targetValue: 1,
        xpReward: 50,
      ),
      // Win Streak
      Achievement(
        id: 'streak_7',
        title: 'On Fire',
        description: 'Win 7 games in a row',
        icon: '🔥',
        category: AchievementCategory.rising,
        targetValue: 7,
        xpReward: 75,
      ),
      // Speed
      Achievement(
        id: 'speed_medium_8min',
        title: 'Quick Thinker',
        description: 'Complete medium puzzle under 8 minutes',
        icon: '⚡',
        category: AchievementCategory.rising,
        targetValue: 1,
        xpReward: 75,
      ),
      Achievement(
        id: 'easy_50',
        title: 'Easy Breezy',
        description: 'Complete 50 easy puzzles',
        icon: '🌟',
        category: AchievementCategory.rising,
        targetValue: 50,
        xpReward: 100,
      ),
      Achievement(
        id: 'medium_10',
        title: 'Steady Progress',
        description: 'Complete 10 medium puzzles',
        icon: '🧩',
        category: AchievementCategory.rising,
        targetValue: 10,
        xpReward: 80,
      ),
      Achievement(
        id: 'hard_5',
        title: 'Brave Heart',
        description: 'Complete 5 hard puzzles',
        icon: '💪',
        category: AchievementCategory.rising,
        targetValue: 5,
        xpReward: 75,
      ),
      Achievement(
        id: 'days_7',
        title: 'Week Warrior',
        description: 'Play for 7 different days',
        icon: '📅',
        category: AchievementCategory.rising,
        targetValue: 7,
        xpReward: 85,
      ),
      Achievement(
        id: 'daily_first',
        title: 'First Challenge',
        description: 'Complete your first daily challenge',
        icon: '📅',
        category: AchievementCategory.seedling,
        targetValue: 1,
        xpReward: 25,
      ),
      Achievement(
        id: 'daily_7',
        title: 'Daily Devotee',
        description: 'Complete 7 daily challenges',
        icon: '📆',
        category: AchievementCategory.rising,
        targetValue: 7,
        xpReward: 75,
      ),
      Achievement(
        id: 'daily_14',
        title: 'Two Week Streak',
        description: 'Complete 14 daily challenges',
        icon: '🏅',
        category: AchievementCategory.skilled,
        targetValue: 14,
        xpReward: 150,
      ),
      Achievement(
        id: 'hints_100',
        title: 'Wisdom Gatherer',
        description: 'Use 100 hints total',
        icon: '🔮',
        category: AchievementCategory.rising,
        targetValue: 100,
        xpReward: 90,
      ),

      // ============ SKILLED TIER (150-200 XP) - Advanced achievements ============
      // Wins
      Achievement(
        id: 'win_50',
        title: 'Experienced Player',
        description: 'Win 50 games',
        icon: '🥈',
        category: AchievementCategory.skilled,
        targetValue: 50,
        xpReward: 100,
      ),
      Achievement(
        id: 'win_100',
        title: 'Veteran Player',
        description: 'Win 100 games',
        icon: '🥇',
        category: AchievementCategory.skilled,
        targetValue: 100,
        xpReward: 200,
      ),
      // Perfect Games
      Achievement(
        id: 'perfect_10',
        title: 'Perfectionist',
        description: 'Complete 10 games without mistakes',
        icon: '✨',
        category: AchievementCategory.skilled,
        targetValue: 10,
        xpReward: 100,
      ),
      // Win Streak
      Achievement(
        id: 'streak_14',
        title: 'Unstoppable',
        description: 'Win 14 games in a row',
        icon: '🔥',
        category: AchievementCategory.skilled,
        targetValue: 14,
        xpReward: 150,
      ),
      // Speed
      Achievement(
        id: 'speed_hard_15min',
        title: 'Speed Master',
        description: 'Complete hard puzzle under 15 minutes',
        icon: '⚡',
        category: AchievementCategory.skilled,
        targetValue: 1,
        xpReward: 125,
      ),
      // Difficulty Master
      Achievement(
        id: 'easy_master',
        title: 'Easy Master',
        description: 'Complete 200 easy puzzles',
        icon: '🌱',
        category: AchievementCategory.skilled,
        targetValue: 200,
        xpReward: 150,
      ),
      Achievement(
        id: 'easy_100',
        title: 'Beginner Champion',
        description: 'Complete 100 easy puzzles',
        icon: '🏅',
        category: AchievementCategory.skilled,
        targetValue: 100,
        xpReward: 175,
      ),
      Achievement(
        id: 'medium_50',
        title: 'Puzzle Enthusiast',
        description: 'Complete 50 medium puzzles',
        icon: '🔥',
        category: AchievementCategory.skilled,
        targetValue: 50,
        xpReward: 180,
      ),
      Achievement(
        id: 'hard_20',
        title: 'Fearless Solver',
        description: 'Complete 20 hard puzzles',
        icon: '🦁',
        category: AchievementCategory.skilled,
        targetValue: 20,
        xpReward: 200,
      ),
      Achievement(
        id: 'expert_10',
        title: 'Mind Master',
        description: 'Complete 10 expert puzzles',
        icon: '🏆',
        category: AchievementCategory.skilled,
        targetValue: 10,
        xpReward: 200,
      ),
      Achievement(
        id: 'hints_500',
        title: 'Knowledge Hunter',
        description: 'Use 500 hints total',
        icon: '📚',
        category: AchievementCategory.skilled,
        targetValue: 500,
        xpReward: 175,
      ),

      // ============ ELITE TIER (250-350 XP) - Expert achievements ============
      // Perfect Games
      Achievement(
        id: 'perfect_50',
        title: 'Flawless Master',
        description: 'Complete 50 games without mistakes',
        icon: '✨',
        category: AchievementCategory.elite,
        targetValue: 50,
        xpReward: 200,
      ),
      // Win Streak
      Achievement(
        id: 'streak_30',
        title: 'Legendary Streak',
        description: 'Win 30 games in a row',
        icon: '🔥',
        category: AchievementCategory.elite,
        targetValue: 30,
        xpReward: 300,
      ),
      // Speed
      Achievement(
        id: 'speed_expert_25min',
        title: 'Lightning Expert',
        description: 'Complete expert puzzle under 25 minutes',
        icon: '⚡',
        category: AchievementCategory.elite,
        targetValue: 1,
        xpReward: 200,
      ),
      // Difficulty Masters
      Achievement(
        id: 'medium_master',
        title: 'Medium Master',
        description: 'Complete 200 medium puzzles',
        icon: '⭐',
        category: AchievementCategory.elite,
        targetValue: 200,
        xpReward: 250,
      ),
      Achievement(
        id: 'hard_master',
        title: 'Hard Master',
        description: 'Complete 100 hard puzzles',
        icon: '💪',
        category: AchievementCategory.elite,
        targetValue: 100,
        xpReward: 350,
      ),
      Achievement(
        id: 'expert_perfect',
        title: 'Expert Perfectionist',
        description: 'Complete expert puzzle without mistakes',
        icon: '💎',
        category: AchievementCategory.elite,
        targetValue: 1,
        xpReward: 300,
      ),
      Achievement(
        id: 'days_30',
        title: 'Monthly Master',
        description: 'Play for 30 different days',
        icon: '🗓️',
        category: AchievementCategory.elite,
        targetValue: 30,
        xpReward: 275,
      ),
      Achievement(
        id: 'daily_30',
        title: 'Challenge Conqueror',
        description: 'Complete 30 daily challenges',
        icon: '🏆',
        category: AchievementCategory.elite,
        targetValue: 30,
        xpReward: 300,
      ),
      Achievement(
        id: 'hints_1000',
        title: 'Enlightened One',
        description: 'Use 1000 hints total',
        icon: '🌌',
        category: AchievementCategory.elite,
        targetValue: 1000,
        xpReward: 300,
      ),

      // ============ LEGENDARY TIER (500-1500 XP) - Master achievements ============
      // Wins
      Achievement(
        id: 'win_500',
        title: 'Grandmaster',
        description: 'Win 500 games',
        icon: '🏆',
        category: AchievementCategory.legendary,
        targetValue: 500,
        xpReward: 500,
      ),
      // Perfect Games
      Achievement(
        id: 'perfect_100',
        title: 'Perfection Incarnate',
        description: 'Complete 100 games without mistakes',
        icon: '💫',
        category: AchievementCategory.legendary,
        targetValue: 100,
        xpReward: 400,
      ),
      // Expert Master
      Achievement(
        id: 'expert_master',
        title: 'Expert Master',
        description: 'Complete 50 expert puzzles',
        icon: '👑',
        category: AchievementCategory.legendary,
        targetValue: 50,
        xpReward: 500,
      ),
      Achievement(
        id: 'days_365',
        title: 'Year-Round Legend',
        description: 'Play for a whole year',
        icon: '🌠',
        category: AchievementCategory.legendary,
        targetValue: 365,
        xpReward: 1500,
      ),

      // ============ DUEL TIER ⚔️ - High XP rewards! ============
      // Duel Win Achievements
      Achievement(
        id: 'duel_first_win',
        title: 'Duel Rookie',
        description: 'Win your first duel',
        icon: '⚔️',
        category: AchievementCategory.duel,
        targetValue: 1,
        xpReward: 50,
      ),
      Achievement(
        id: 'duel_win_10',
        title: 'Duel Fighter',
        description: 'Win 10 duels',
        icon: '🗡️',
        category: AchievementCategory.duel,
        targetValue: 10,
        xpReward: 100,
      ),
      Achievement(
        id: 'duel_win_50',
        title: 'Duel Warrior',
        description: 'Win 50 duels',
        icon: '⚔️',
        category: AchievementCategory.duel,
        targetValue: 50,
        xpReward: 250,
      ),
      Achievement(
        id: 'duel_win_100',
        title: 'Duel Veteran',
        description: 'Win 100 duels',
        icon: '🏅',
        category: AchievementCategory.duel,
        targetValue: 100,
        xpReward: 500,
      ),
      Achievement(
        id: 'duel_win_500',
        title: 'Duel Legend',
        description: 'Win 500 duels',
        icon: '🏆',
        category: AchievementCategory.duel,
        targetValue: 500,
        xpReward: 1500,
      ),
      // Duel Win Streak
      Achievement(
        id: 'duel_streak_3',
        title: 'Duel Hot Streak',
        description: 'Win 3 duels in a row',
        icon: '🔥',
        category: AchievementCategory.duel,
        targetValue: 3,
        xpReward: 60,
      ),
      Achievement(
        id: 'duel_streak_5',
        title: 'Duel On Fire',
        description: 'Win 5 duels in a row',
        icon: '🔥',
        category: AchievementCategory.duel,
        targetValue: 5,
        xpReward: 120,
      ),
      Achievement(
        id: 'duel_streak_10',
        title: 'Duel Unstoppable',
        description: 'Win 10 duels in a row',
        icon: '🔥',
        category: AchievementCategory.duel,
        targetValue: 10,
        xpReward: 300,
      ),
      // Division Achievements (ELO-based)
      Achievement(
        id: 'duel_silver',
        title: 'Silver Division',
        description: 'Reach Silver (500 ELO)',
        icon: '🥈',
        category: AchievementCategory.duel,
        targetValue: 500,
        xpReward: 100,
      ),
      Achievement(
        id: 'duel_gold',
        title: 'Gold Division',
        description: 'Reach Gold (800 ELO)',
        icon: '🥇',
        category: AchievementCategory.duel,
        targetValue: 800,
        xpReward: 150,
      ),
      Achievement(
        id: 'duel_platinum',
        title: 'Platinum Division',
        description: 'Reach Platinum (1100 ELO)',
        icon: '💠',
        category: AchievementCategory.duel,
        targetValue: 1100,
        xpReward: 250,
      ),
      Achievement(
        id: 'duel_diamond',
        title: 'Diamond Division',
        description: 'Reach Diamond (1400 ELO)',
        icon: '💎',
        category: AchievementCategory.duel,
        targetValue: 1400,
        xpReward: 400,
      ),
      Achievement(
        id: 'duel_master',
        title: 'Master Division',
        description: 'Reach Master (1700 ELO)',
        icon: '👑',
        category: AchievementCategory.duel,
        targetValue: 1700,
        xpReward: 600,
      ),
      Achievement(
        id: 'duel_grandmaster',
        title: 'Grandmaster Division',
        description: 'Reach Grandmaster (2000 ELO)',
        icon: '🔮',
        category: AchievementCategory.duel,
        targetValue: 2000,
        xpReward: 1000,
      ),
      Achievement(
        id: 'duel_champion',
        title: 'Champion Division',
        description: 'Reach Champion (2300 ELO)',
        icon: '🏆',
        category: AchievementCategory.duel,
        targetValue: 2300,
        xpReward: 2000,
      ),
    ];
  }

  /// Get total available achievements (excluding coming soon)
  static int get totalAvailable {
    return getDefaultAchievements().where((a) => !a.isComingSoon).length;
  }

  /// Get all achievements
  static List<Achievement> get all => getDefaultAchievements();

  /// Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return getDefaultAchievements().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get achievements by category filter
  static List<Achievement> getByIds(List<String> ids) {
    return getDefaultAchievements().where((a) => ids.contains(a.id)).toList();
  }

  /// Win achievements
  static List<Achievement> get winAchievements => getDefaultAchievements()
      .where((a) => ['first_win', 'win_10', 'win_50', 'win_100', 'win_500']
          .contains(a.id))
      .toList();

  /// Perfect game achievements
  static List<Achievement> get perfectAchievements => getDefaultAchievements()
      .where((a) => ['first_perfect', 'perfect_10', 'perfect_50', 'perfect_100']
          .contains(a.id))
      .toList();

  /// Win streak achievements
  static List<Achievement> get streakAchievements => getDefaultAchievements()
      .where((a) =>
          ['streak_3', 'streak_7', 'streak_14', 'streak_30'].contains(a.id))
      .toList();

  /// Daily challenge achievements
  static List<Achievement> get dailyAchievements => getDefaultAchievements()
      .where((a) =>
          ['daily_first', 'daily_7', 'daily_14', 'daily_30'].contains(a.id))
      .toList();
}

/// User's unlocked achievements data
class UserAchievements {
  final List<String> unlockedIds;
  final int totalDailyCompleted;
  final Map<String, int> fastestTimes; // difficulty -> time in seconds
  final Map<String, int> difficultyWins; // difficulty -> win count
  final int expertPerfectWins;

  const UserAchievements({
    this.unlockedIds = const [],
    this.totalDailyCompleted = 0,
    this.fastestTimes = const {},
    this.difficultyWins = const {},
    this.expertPerfectWins = 0,
  });

  UserAchievements copyWith({
    List<String>? unlockedIds,
    int? totalDailyCompleted,
    Map<String, int>? fastestTimes,
    Map<String, int>? difficultyWins,
    int? expertPerfectWins,
  }) {
    return UserAchievements(
      unlockedIds: unlockedIds ?? this.unlockedIds,
      totalDailyCompleted: totalDailyCompleted ?? this.totalDailyCompleted,
      fastestTimes: fastestTimes ?? this.fastestTimes,
      difficultyWins: difficultyWins ?? this.difficultyWins,
      expertPerfectWins: expertPerfectWins ?? this.expertPerfectWins,
    );
  }

  Map<String, dynamic> toJson() => {
        'unlockedIds': unlockedIds,
        'totalDailyCompleted': totalDailyCompleted,
        'fastestTimes': fastestTimes,
        'difficultyWins': difficultyWins,
        'expertPerfectWins': expertPerfectWins,
      };

  factory UserAchievements.fromJson(Map<String, dynamic> json) {
    return UserAchievements(
      unlockedIds: (json['unlockedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalDailyCompleted: json['totalDailyCompleted'] as int? ?? 0,
      fastestTimes: (json['fastestTimes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      difficultyWins: (json['difficultyWins'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      expertPerfectWins: json['expertPerfectWins'] as int? ?? 0,
    );
  }
}

/// Result of checking achievements
class AchievementCheckResult {
  final List<Achievement> newlyUnlocked;
  final int totalXpBonus;
  final UserAchievements updatedData;

  const AchievementCheckResult({
    required this.newlyUnlocked,
    required this.totalXpBonus,
    required this.updatedData,
  });
}
