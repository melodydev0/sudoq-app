import 'dart:convert';

/// Daily challenge model
class DailyChallenge {
  final DateTime date;
  final String difficulty;
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final bool isCompleted;
  final int? completionTime; // in seconds
  final int? score;
  final int? mistakes;

  DailyChallenge({
    required this.date,
    required this.difficulty,
    required this.puzzle,
    required this.solution,
    this.isCompleted = false,
    this.completionTime,
    this.score,
    this.mistakes,
  });

  /// Get the date string in format YYYY-MM-DD
  String get dateString =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Get formatted date for display
  String get displayDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  DailyChallenge copyWith({
    DateTime? date,
    String? difficulty,
    List<List<int>>? puzzle,
    List<List<int>>? solution,
    bool? isCompleted,
    int? completionTime,
    int? score,
    int? mistakes,
  }) {
    return DailyChallenge(
      date: date ?? this.date,
      difficulty: difficulty ?? this.difficulty,
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      isCompleted: isCompleted ?? this.isCompleted,
      completionTime: completionTime ?? this.completionTime,
      score: score ?? this.score,
      mistakes: mistakes ?? this.mistakes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': dateString,
      'difficulty': difficulty,
      'puzzle': puzzle.map((row) => row.toList()).toList(),
      'solution': solution.map((row) => row.toList()).toList(),
      'isCompleted': isCompleted,
      'completionTime': completionTime,
      'score': score,
      'mistakes': mistakes,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      date: DateTime.parse(json['date'] as String),
      difficulty: json['difficulty'] as String,
      puzzle: (json['puzzle'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList(),
      solution: (json['solution'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completionTime: json['completionTime'] as int?,
      score: json['score'] as int?,
      mistakes: json['mistakes'] as int?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory DailyChallenge.fromJsonString(String jsonString) =>
      DailyChallenge.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// History of daily challenges
class DailyChallengeHistory {
  final Map<String, DailyChallenge> challenges;
  final int totalCompleted;
  final int currentStreak;
  final int bestStreak;

  DailyChallengeHistory({
    Map<String, DailyChallenge>? challenges,
    this.totalCompleted = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  }) : challenges = challenges ?? {};

  DailyChallengeHistory copyWith({
    Map<String, DailyChallenge>? challenges,
    int? totalCompleted,
    int? currentStreak,
    int? bestStreak,
  }) {
    return DailyChallengeHistory(
      challenges: challenges ?? this.challenges,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challenges': challenges.map((k, v) => MapEntry(k, v.toJson())),
      'totalCompleted': totalCompleted,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }

  factory DailyChallengeHistory.fromJson(Map<String, dynamic> json) {
    return DailyChallengeHistory(
      challenges: (json['challenges'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, DailyChallenge.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory DailyChallengeHistory.fromJsonString(String jsonString) =>
      DailyChallengeHistory.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);
}
