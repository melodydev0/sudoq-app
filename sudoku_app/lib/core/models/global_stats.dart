/// Global statistics for daily challenges
/// This model represents aggregated data from all players
class GlobalDailyStats {
  /// Total number of players who completed a specific date's challenge
  final int playersCompleted;

  /// Average completion time in seconds for this challenge
  final int avgCompletionTimeSeconds;

  /// Average mistakes made
  final double avgMistakes;

  /// Total attempts on this challenge
  final int totalAttempts;

  /// Success rate (completed / attempts)
  final double successRate;

  /// Last updated timestamp
  final DateTime? lastUpdated;

  const GlobalDailyStats({
    this.playersCompleted = 0,
    this.avgCompletionTimeSeconds = 0,
    this.avgMistakes = 0,
    this.totalAttempts = 0,
    this.successRate = 0,
    this.lastUpdated,
  });

  factory GlobalDailyStats.fromJson(Map<String, dynamic> json) {
    return GlobalDailyStats(
      playersCompleted: json['playersCompleted'] as int? ?? 0,
      avgCompletionTimeSeconds: json['avgCompletionTimeSeconds'] as int? ?? 0,
      avgMistakes: (json['avgMistakes'] as num?)?.toDouble() ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playersCompleted': playersCompleted,
      'avgCompletionTimeSeconds': avgCompletionTimeSeconds,
      'avgMistakes': avgMistakes,
      'totalAttempts': totalAttempts,
      'successRate': successRate,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  GlobalDailyStats copyWith({
    int? playersCompleted,
    int? avgCompletionTimeSeconds,
    double? avgMistakes,
    int? totalAttempts,
    double? successRate,
    DateTime? lastUpdated,
  }) {
    return GlobalDailyStats(
      playersCompleted: playersCompleted ?? this.playersCompleted,
      avgCompletionTimeSeconds:
          avgCompletionTimeSeconds ?? this.avgCompletionTimeSeconds,
      avgMistakes: avgMistakes ?? this.avgMistakes,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successRate: successRate ?? this.successRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Global statistics for a month's challenges
class GlobalMonthStats {
  final int year;
  final int month;

  /// Total unique players who attempted any challenge this month
  final int totalPlayers;

  /// Players who completed all days
  final int fullMonthCompleters;

  /// Average completion rate (days completed / total days)
  final double avgCompletionRate;

  /// Map of day number to stats
  final Map<int, GlobalDailyStats> dailyStats;

  const GlobalMonthStats({
    required this.year,
    required this.month,
    this.totalPlayers = 0,
    this.fullMonthCompleters = 0,
    this.avgCompletionRate = 0,
    this.dailyStats = const {},
  });

  /// Get stats for a specific day
  GlobalDailyStats? getStatsForDay(int day) => dailyStats[day];

  factory GlobalMonthStats.fromJson(Map<String, dynamic> json) {
    final dailyStatsJson = json['dailyStats'] as Map<String, dynamic>? ?? {};
    final dailyStats = <int, GlobalDailyStats>{};

    dailyStatsJson.forEach((key, value) {
      dailyStats[int.parse(key)] =
          GlobalDailyStats.fromJson(value as Map<String, dynamic>);
    });

    return GlobalMonthStats(
      year: json['year'] as int,
      month: json['month'] as int,
      totalPlayers: json['totalPlayers'] as int? ?? 0,
      fullMonthCompleters: json['fullMonthCompleters'] as int? ?? 0,
      avgCompletionRate: (json['avgCompletionRate'] as num?)?.toDouble() ?? 0,
      dailyStats: dailyStats,
    );
  }

  Map<String, dynamic> toJson() {
    final dailyStatsJson = <String, dynamic>{};
    dailyStats.forEach((key, value) {
      dailyStatsJson[key.toString()] = value.toJson();
    });

    return {
      'year': year,
      'month': month,
      'totalPlayers': totalPlayers,
      'fullMonthCompleters': fullMonthCompleters,
      'avgCompletionRate': avgCompletionRate,
      'dailyStats': dailyStatsJson,
    };
  }
}
