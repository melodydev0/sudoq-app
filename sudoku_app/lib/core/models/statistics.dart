import 'dart:convert';

/// User statistics model
class Statistics {
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalGamesLost;
  final int currentStreak;
  final int bestStreak;
  final int totalPlayTime; // in seconds
  final Map<String, DifficultyStats> difficultyStats;
  final int totalHintsUsed;
  final int perfectGames; // Games completed without mistakes
  final DateTime? lastPlayedDate;
  final List<String>
      uniqueDaysPlayed; // List of dates (YYYY-MM-DD) when user played
  final int totalDailyChallengesCompleted; // Total daily challenges completed

  Statistics({
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalGamesLost = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalPlayTime = 0,
    Map<String, DifficultyStats>? difficultyStats,
    this.totalHintsUsed = 0,
    this.perfectGames = 0,
    this.lastPlayedDate,
    List<String>? uniqueDaysPlayed,
    this.totalDailyChallengesCompleted = 0,
  })  : difficultyStats = difficultyStats ?? {},
        uniqueDaysPlayed = uniqueDaysPlayed ?? [];

  /// Get total unique days played
  int get daysPlayed => uniqueDaysPlayed.length;

  double get winRate =>
      totalGamesPlayed > 0 ? (totalGamesWon / totalGamesPlayed) * 100 : 0;

  Statistics copyWith({
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalGamesLost,
    int? currentStreak,
    int? bestStreak,
    int? totalPlayTime,
    Map<String, DifficultyStats>? difficultyStats,
    int? totalHintsUsed,
    int? perfectGames,
    DateTime? lastPlayedDate,
    List<String>? uniqueDaysPlayed,
    int? totalDailyChallengesCompleted,
  }) {
    return Statistics(
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      totalGamesLost: totalGamesLost ?? this.totalGamesLost,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      difficultyStats: difficultyStats ?? this.difficultyStats,
      totalHintsUsed: totalHintsUsed ?? this.totalHintsUsed,
      perfectGames: perfectGames ?? this.perfectGames,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      uniqueDaysPlayed: uniqueDaysPlayed ?? this.uniqueDaysPlayed,
      totalDailyChallengesCompleted:
          totalDailyChallengesCompleted ?? this.totalDailyChallengesCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'totalGamesLost': totalGamesLost,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalPlayTime': totalPlayTime,
      'difficultyStats': difficultyStats.map((k, v) => MapEntry(k, v.toJson())),
      'totalHintsUsed': totalHintsUsed,
      'perfectGames': perfectGames,
      'lastPlayedDate': lastPlayedDate?.toIso8601String(),
      'uniqueDaysPlayed': uniqueDaysPlayed,
      'totalDailyChallengesCompleted': totalDailyChallengesCompleted,
    };
  }

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalGamesWon: json['totalGamesWon'] as int? ?? 0,
      totalGamesLost: json['totalGamesLost'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      totalPlayTime: json['totalPlayTime'] as int? ?? 0,
      difficultyStats: (json['difficultyStats'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
                k, DifficultyStats.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      totalHintsUsed: json['totalHintsUsed'] as int? ?? 0,
      perfectGames: json['perfectGames'] as int? ?? 0,
      lastPlayedDate: json['lastPlayedDate'] != null
          ? DateTime.parse(json['lastPlayedDate'] as String)
          : null,
      uniqueDaysPlayed: (json['uniqueDaysPlayed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalDailyChallengesCompleted:
          json['totalDailyChallengesCompleted'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Statistics.fromJsonString(String jsonString) =>
      Statistics.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// Statistics per difficulty level
class DifficultyStats {
  final int gamesPlayed;
  final int gamesWon;
  final int bestTime; // in seconds
  final int averageTime; // in seconds
  final int bestScore;

  DifficultyStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.bestTime = 0,
    this.averageTime = 0,
    this.bestScore = 0,
  });

  DifficultyStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? bestTime,
    int? averageTime,
    int? bestScore,
  }) {
    return DifficultyStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      bestTime: bestTime ?? this.bestTime,
      averageTime: averageTime ?? this.averageTime,
      bestScore: bestScore ?? this.bestScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'bestTime': bestTime,
      'averageTime': averageTime,
      'bestScore': bestScore,
    };
  }

  factory DifficultyStats.fromJson(Map<String, dynamic> json) {
    return DifficultyStats(
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      bestTime: json['bestTime'] as int? ?? 0,
      averageTime: json['averageTime'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
    );
  }
}
