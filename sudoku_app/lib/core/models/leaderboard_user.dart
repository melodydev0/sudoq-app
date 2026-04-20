/// Model for leaderboard user data
class LeaderboardUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String countryCode;
  final int level;
  final int totalXp;
  final int rank;
  final int gamesWon;
  final int perfectGames;
  final double winRate;
  final int rankedPoints;
  final String? division;
  final List<String> unlockedAchievementIds;
  final List<String> equippedBadgeIds;
  final String? equippedFrame;
  final DateTime joinedAt;
  final bool isOnline;

  LeaderboardUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.countryCode,
    required this.level,
    required this.totalXp,
    required this.rank,
    required this.gamesWon,
    required this.perfectGames,
    required this.winRate,
    required this.rankedPoints,
    this.division,
    required this.unlockedAchievementIds,
    required this.equippedBadgeIds,
    this.equippedFrame,
    required this.joinedAt,
    this.isOnline = false,
  });

  /// Get country flag emoji from country code
  String get countryFlag {
    if (countryCode.length != 2) return '🌍';
    final firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([firstLetter, secondLetter]);
  }

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      countryCode: json['countryCode'] as String,
      level: (json['level'] as num).toInt(),
      totalXp: (json['totalXp'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      gamesWon: (json['gamesWon'] as num).toInt(),
      perfectGames: (json['perfectGames'] as num).toInt(),
      winRate: (json['winRate'] as num).toDouble(),
      rankedPoints: (json['rankedPoints'] as num).toInt(),
      division: json['division'] as String?,
      unlockedAchievementIds:
          List<String>.from(json['unlockedAchievementIds'] ?? []),
      equippedBadgeIds: List<String>.from(json['equippedBadgeIds'] ?? []),
      equippedFrame: json['equippedFrame'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'countryCode': countryCode,
      'level': level,
      'totalXp': totalXp,
      'rank': rank,
      'gamesWon': gamesWon,
      'perfectGames': perfectGames,
      'winRate': winRate,
      'rankedPoints': rankedPoints,
      'division': division,
      'unlockedAchievementIds': unlockedAchievementIds,
      'equippedBadgeIds': equippedBadgeIds,
      'equippedFrame': equippedFrame,
      'joinedAt': joinedAt.toIso8601String(),
      'isOnline': isOnline,
    };
  }
}
