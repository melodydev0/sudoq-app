/// XP and Level System Constants
class LevelConstants {
  static const int maxLevel = 100;
  static const int seasonDurationDays = 90; // 3 months

  /// XP required for each level (progressive)
  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    if (level == 1) return 0;
    // Formula: 100 * level * (1 + level/10)
    // Level 2: 220 XP, Level 10: 2000 XP, Level 50: 27500 XP, Level 100: 110000 XP
    return (100 * level * (1 + level / 10)).round();
  }

  /// Total XP needed to reach a level
  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  /// Calculate level from total XP
  static int levelFromXp(int totalXp) {
    int level = 1;
    int accumulated = 0;
    while (level < maxLevel) {
      int needed = xpForLevel(level + 1);
      if (accumulated + needed > totalXp) break;
      accumulated += needed;
      level++;
    }
    return level;
  }

  /// XP progress within current level (0.0 to 1.0)
  static double progressInLevel(int totalXp) {
    int level = levelFromXp(totalXp);
    if (level >= maxLevel) return 1.0;

    int xpAtLevelStart = totalXpForLevel(level);
    int xpForNext = xpForLevel(level + 1);
    int currentProgress = totalXp - xpAtLevelStart;

    return (currentProgress / xpForNext).clamp(0.0, 1.0);
  }
}

/// XP Multipliers for different game modes and bonuses
class XpMultipliers {
  // Base XP by difficulty (minimum XP) – balanced so Easy doesn't over-reward
  static const Map<String, int> baseXp = {
    'Beginner': 3,
    'Easy': 6,
    'Medium': 18,
    'Hard': 35,
    'Expert': 55,
    'Extreme': 75,
  };

  // Max XP by difficulty (~1.5x base for perfect performance)
  static const Map<String, int> maxXp = {
    'Beginner': 6,
    'Easy': 12,
    'Medium': 30,
    'Hard': 55,
    'Expert': 90,
    'Extreme': 120,
  };

  // Target scores for max performance (based on ~45 correct cells)
  static const Map<String, int> targetScores = {
    'Beginner': 500,
    'Easy': 600, // ~45 cells * 10pts * 1.3 avg multiplier
    'Medium': 700,
    'Hard': 800,
    'Expert': 900,
    'Extreme': 1000,
  };

  // Bonus multipliers
  static const double dailyChallengeMultiplier = 1.3;
  static const double rankedMultiplier = 1.2;

  // Daily streak reward: 50 + streakDays * 10, capped at 500 XP
  static const int _streakRewardBase = 50;
  static const int _streakRewardPerDay = 10;
  static const int _streakRewardCap = 500;

  /// Calculate once-per-day streak reward based on consecutive days.
  static int calculateDailyStreakXp(int streakDays) {
    final reward = _streakRewardBase + streakDays * _streakRewardPerDay;
    return reward.clamp(_streakRewardBase, _streakRewardCap);
  }

  // Target times for each difficulty (in seconds) - used for time bonus display
  static const Map<String, int> targetTimes = {
    'Beginner': 180, // 3 min
    'Easy': 300, // 5 min
    'Medium': 600, // 10 min
    'Hard': 1200, // 20 min
    'Expert': 1800, // 30 min
    'Extreme': 2400, // 40 min
  };

  // Time bonus (faster completion = small bonus) - used for UI display
  static double timeBonus(String difficulty, Duration completionTime) {
    int target = targetTimes[difficulty] ?? 600;
    int actual = completionTime.inSeconds;

    if (actual <= target * 0.5) return 1.15; // 50% faster = +15%
    if (actual <= target * 0.75) return 1.08; // 25% faster = +8%
    if (actual <= target) return 1.04; // On time = +4%
    return 1.0; // Over time = no bonus
  }

  /// Calculate performance rating (0.0 to 1.0)
  /// Based on score, combo, mistakes, and time
  static double calculatePerformance({
    required String difficulty,
    required int score,
    required int maxCombo,
    required int fastSolves,
    required int mistakes,
    required Duration completionTime,
  }) {
    double performance = 0.0;

    // Score contribution (40%)
    int targetScore = targetScores[difficulty] ?? 600;
    double scoreRatio = (score / targetScore).clamp(0.0, 1.5);
    performance += scoreRatio * 0.4;

    // Combo contribution (25%) - max combo of 10+ is excellent
    double comboRatio = (maxCombo / 10.0).clamp(0.0, 1.0);
    performance += comboRatio * 0.25;

    // Fast solves contribution (15%) - 10+ fast solves is excellent
    double fastRatio = (fastSolves / 10.0).clamp(0.0, 1.0);
    performance += fastRatio * 0.15;

    // Mistakes penalty (20%) - 0 mistakes = full, 3 mistakes = 0
    double mistakePenalty = 1.0 - (mistakes / 3.0).clamp(0.0, 1.0);
    performance += mistakePenalty * 0.2;

    return performance.clamp(0.0, 1.0);
  }

  /// Calculate total XP earned based on performance
  static int calculateXp({
    required String difficulty,
    required Duration completionTime,
    required int mistakes,
    required bool isDailyChallenge,
    required bool isRanked,
    required int streakDays,
    int score = 0,
    int maxCombo = 0,
    int fastSolves = 0,
  }) {
    // Get base and max XP for difficulty
    int base = baseXp[difficulty] ?? 15;
    int max = maxXp[difficulty] ?? 30;

    // Calculate performance rating
    double performance = calculatePerformance(
      difficulty: difficulty,
      score: score,
      maxCombo: maxCombo,
      fastSolves: fastSolves,
      mistakes: mistakes,
      completionTime: completionTime,
    );

    // Interpolate between base and max XP based on performance
    int earnedXp = (base + (max - base) * performance).round();

    // Apply additional multipliers
    double multiplier = 1.0;

    // Daily challenge bonus
    if (isDailyChallenge) {
      multiplier *= dailyChallengeMultiplier;
    }

    // Ranked mode bonus
    if (isRanked) {
      multiplier *= rankedMultiplier;
    }

    return (earnedXp * multiplier).round();
  }

  /// Breakdown of game XP for result screen (difficulty base, performance, daily, ranked).
  static List<GameXpBreakdownEntry> getXpBreakdown({
    required String difficulty,
    required Duration completionTime,
    required int mistakes,
    required bool isDailyChallenge,
    required bool isRanked,
    required int streakDays,
    int score = 0,
    int maxCombo = 0,
    int fastSolves = 0,
  }) {
    int base = baseXp[difficulty] ?? 15;
    int max = maxXp[difficulty] ?? 30;
    double performance = calculatePerformance(
      difficulty: difficulty,
      score: score,
      maxCombo: maxCombo,
      fastSolves: fastSolves,
      mistakes: mistakes,
      completionTime: completionTime,
    );
    int performanceXp = ((max - base) * performance).round();
    int baseGame = base + performanceXp;
    double dailyMult = isDailyChallenge ? dailyChallengeMultiplier : 1.0;
    double rankedMult = isRanked ? rankedMultiplier : 1.0;
    final list = <GameXpBreakdownEntry>[];
    list.add(GameXpBreakdownEntry('difficulty', base));
    if (performanceXp > 0) {
      list.add(GameXpBreakdownEntry('performance', performanceXp));
    }
    if (isDailyChallenge) {
      list.add(GameXpBreakdownEntry(
          'daily', (baseGame * (dailyMult - 1)).round()));
    }
    if (isRanked) {
      list.add(GameXpBreakdownEntry(
          'ranked', (baseGame * dailyMult * (rankedMult - 1)).round()));
    }
    return list;
  }
}

/// Single row for XP breakdown on result screen
class GameXpBreakdownEntry {
  final String label;
  final int xp;

  const GameXpBreakdownEntry(this.label, this.xp);
}

/// User Rank/Title based on level
enum UserRank {
  novice, // 1-5
  amateur, // 6-15
  talented, // 16-30
  expert, // 31-50
  master, // 51-75
  legend, // 76-99
  sudokuKing, // 100
}

class RankInfo {
  final UserRank rank;
  final String icon;
  final int minLevel;
  final int maxLevel;
  final String? imagePath;

  const RankInfo({
    required this.rank,
    required this.icon,
    required this.minLevel,
    required this.maxLevel,
    this.imagePath,
  });

  static const List<RankInfo> ranks = [
    RankInfo(rank: UserRank.novice, icon: '🌱', minLevel: 1, maxLevel: 5, imagePath: 'assets/ranks/novice.png'),
    RankInfo(rank: UserRank.amateur, icon: '🎯', minLevel: 6, maxLevel: 15, imagePath: 'assets/ranks/amateur.png'),
    RankInfo(rank: UserRank.talented, icon: '🧩', minLevel: 16, maxLevel: 30, imagePath: 'assets/ranks/talented.png'),
    RankInfo(rank: UserRank.expert, icon: '💪', minLevel: 31, maxLevel: 50, imagePath: 'assets/ranks/expert.png'),
    RankInfo(rank: UserRank.master, icon: '🏅', minLevel: 51, maxLevel: 75, imagePath: 'assets/ranks/master.png'),
    RankInfo(rank: UserRank.legend, icon: '👑', minLevel: 76, maxLevel: 99, imagePath: 'assets/ranks/legend.png'),
    RankInfo(rank: UserRank.sudokuKing, icon: '🎖️', minLevel: 100, maxLevel: 100, imagePath: 'assets/ranks/sudoku_king.png'),
  ];

  static RankInfo fromLevel(int level) {
    for (var rank in ranks.reversed) {
      if (level >= rank.minLevel) return rank;
    }
    return ranks.first;
  }
}

/// Season model
class Season {
  final int seasonNumber;
  final DateTime startDate;
  final DateTime endDate;

  Season({
    required this.seasonNumber,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive =>
      DateTime.now().isBefore(endDate) && DateTime.now().isAfter(startDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  double get progress {
    final total = endDate.difference(startDate).inDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Create current season based on app launch date (Jan 1, 2026)
  static Season getCurrentSeason() {
    final now = DateTime.now();
    final appLaunchDate = DateTime(2026, 1, 1);

    // Calculate which season we're in
    int daysSinceLaunch = now.difference(appLaunchDate).inDays;
    int seasonNumber =
        (daysSinceLaunch / LevelConstants.seasonDurationDays).floor() + 1;

    // Calculate season dates
    DateTime seasonStart = appLaunchDate.add(
        Duration(days: (seasonNumber - 1) * LevelConstants.seasonDurationDays));
    DateTime seasonEnd = seasonStart
        .add(const Duration(days: LevelConstants.seasonDurationDays));

    return Season(
      seasonNumber: seasonNumber,
      startDate: seasonStart,
      endDate: seasonEnd,
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonNumber': seasonNumber,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

  factory Season.fromJson(Map<String, dynamic> json) => Season(
        seasonNumber: json['seasonNumber'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
      );
}

/// User Level Data
class UserLevelData {
  final int totalXp;
  final int seasonXp;
  final int seasonNumber;
  final int streakDays;
  final DateTime? lastPlayedDate;
  final DateTime? lastStreakRewardDate;
  final List<String> unlockedRewards;

  UserLevelData({
    this.totalXp = 0,
    this.seasonXp = 0,
    this.seasonNumber = 1,
    this.streakDays = 0,
    this.lastPlayedDate,
    this.lastStreakRewardDate,
    this.unlockedRewards = const [],
  });

  int get level => LevelConstants.levelFromXp(totalXp);
  int get seasonLevel => LevelConstants.levelFromXp(seasonXp);
  double get levelProgress => LevelConstants.progressInLevel(totalXp);
  double get seasonLevelProgress => LevelConstants.progressInLevel(seasonXp);
  RankInfo get rank => RankInfo.fromLevel(level);
  RankInfo get seasonRank => RankInfo.fromLevel(seasonLevel);

  int get xpToNextLevel {
    if (level >= LevelConstants.maxLevel) return 0;
    final nextLevelXp = LevelConstants.totalXpForLevel(level + 1);
    return nextLevelXp - totalXp;
  }

  UserLevelData copyWith({
    int? totalXp,
    int? seasonXp,
    int? seasonNumber,
    int? streakDays,
    DateTime? lastPlayedDate,
    DateTime? lastStreakRewardDate,
    List<String>? unlockedRewards,
  }) {
    return UserLevelData(
      totalXp: totalXp ?? this.totalXp,
      seasonXp: seasonXp ?? this.seasonXp,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      lastStreakRewardDate: lastStreakRewardDate ?? this.lastStreakRewardDate,
      unlockedRewards: unlockedRewards ?? this.unlockedRewards,
    );
  }

  /// Returns true if the daily streak reward has not yet been claimed today.
  bool get isStreakRewardAvailableToday {
    if (lastStreakRewardDate == null) return true;
    final now = DateTime.now();
    return !(lastStreakRewardDate!.year == now.year &&
        lastStreakRewardDate!.month == now.month &&
        lastStreakRewardDate!.day == now.day);
  }

  /// Add XP and check for streak
  UserLevelData addXp(int xp, {bool updateStreak = true}) {
    final now = DateTime.now();
    int newStreak = streakDays;

    if (updateStreak && lastPlayedDate != null) {
      final daysSinceLastPlay = now.difference(lastPlayedDate!).inDays;
      if (daysSinceLastPlay == 1) {
        // Consecutive day - increase streak
        newStreak = streakDays + 1;
      } else if (daysSinceLastPlay > 1) {
        // Missed a day - reset streak
        newStreak = 1;
      }
      // Same day - keep streak
    } else if (updateStreak) {
      newStreak = 1; // First play
    }

    return copyWith(
      totalXp: totalXp + xp,
      seasonXp: seasonXp + xp,
      streakDays: newStreak,
      lastPlayedDate: now,
    );
  }

  /// Reset for new season
  UserLevelData resetForNewSeason(int newSeasonNumber) {
    return copyWith(
      seasonXp: 0,
      seasonNumber: newSeasonNumber,
      // Keep total XP and streak
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'seasonXp': seasonXp,
        'seasonNumber': seasonNumber,
        'streakDays': streakDays,
        'lastPlayedDate': lastPlayedDate?.toIso8601String(),
        'lastStreakRewardDate': lastStreakRewardDate?.toIso8601String(),
        'unlockedRewards': unlockedRewards,
      };

  factory UserLevelData.fromJson(Map<String, dynamic> json) => UserLevelData(
        totalXp: json['totalXp'] as int? ?? 0,
        seasonXp: json['seasonXp'] as int? ?? 0,
        seasonNumber: json['seasonNumber'] as int? ?? 1,
        streakDays: json['streakDays'] as int? ?? 0,
        lastPlayedDate: json['lastPlayedDate'] != null
            ? DateTime.parse(json['lastPlayedDate'] as String)
            : null,
        lastStreakRewardDate: json['lastStreakRewardDate'] != null
            ? DateTime.parse(json['lastStreakRewardDate'] as String)
            : null,
        unlockedRewards: (json['unlockedRewards'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
