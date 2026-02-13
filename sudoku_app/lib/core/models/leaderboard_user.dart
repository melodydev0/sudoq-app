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
      level: json['level'] as int,
      totalXp: json['totalXp'] as int,
      rank: json['rank'] as int,
      gamesWon: json['gamesWon'] as int,
      perfectGames: json['perfectGames'] as int,
      winRate: (json['winRate'] as num).toDouble(),
      rankedPoints: json['rankedPoints'] as int,
      division: json['division'] as String?,
      unlockedAchievementIds:
          List<String>.from(json['unlockedAchievementIds'] ?? []),
      equippedBadgeIds: List<String>.from(json['equippedBadgeIds'] ?? []),
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
      'joinedAt': joinedAt.toIso8601String(),
      'isOnline': isOnline,
    };
  }
}

/// Mock data generator for demo purposes
class MockLeaderboardData {
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'username': 'SudokuMaster',
      'country': 'JP',
      'level': 87,
      'xp': 125000,
      'wins': 1523,
      'perfect': 342,
      'rate': 94.5,
      'rp': 2850,
      'div': 'Champion',
      'avatar': 'S'
    },
    {
      'username': 'PuzzleKing',
      'country': 'US',
      'level': 82,
      'xp': 118000,
      'wins': 1402,
      'perfect': 298,
      'rate': 92.1,
      'rp': 2720,
      'div': 'Champion',
      'avatar': 'P'
    },
    {
      'username': 'NumberNinja',
      'country': 'KR',
      'level': 79,
      'xp': 112000,
      'wins': 1356,
      'perfect': 287,
      'rate': 91.8,
      'rp': 2650,
      'div': 'Grandmaster',
      'avatar': 'N'
    },
    {
      'username': 'GridGenius',
      'country': 'DE',
      'level': 75,
      'xp': 105000,
      'wins': 1289,
      'perfect': 265,
      'rate': 90.2,
      'rp': 2580,
      'div': 'Grandmaster',
      'avatar': 'G'
    },
    {
      'username': 'LogicLord',
      'country': 'GB',
      'level': 72,
      'xp': 98000,
      'wins': 1198,
      'perfect': 241,
      'rate': 89.5,
      'rp': 2490,
      'div': 'Grandmaster',
      'avatar': 'L'
    },
    {
      'username': 'BrainStorm',
      'country': 'FR',
      'level': 68,
      'xp': 92000,
      'wins': 1087,
      'perfect': 218,
      'rate': 88.3,
      'rp': 2350,
      'div': 'Master',
      'avatar': 'B'
    },
    {
      'username': 'MindMaze',
      'country': 'BR',
      'level': 65,
      'xp': 87000,
      'wins': 1023,
      'perfect': 195,
      'rate': 87.1,
      'rp': 2280,
      'div': 'Master',
      'avatar': 'M'
    },
    {
      'username': 'CellSolver',
      'country': 'CA',
      'level': 62,
      'xp': 82000,
      'wins': 956,
      'perfect': 178,
      'rate': 86.4,
      'rp': 2150,
      'div': 'Master',
      'avatar': 'C'
    },
    {
      'username': 'DigitDancer',
      'country': 'AU',
      'level': 58,
      'xp': 76000,
      'wins': 892,
      'perfect': 162,
      'rate': 85.2,
      'rp': 2050,
      'div': 'Diamond',
      'avatar': 'D'
    },
    {
      'username': 'RowRuler',
      'country': 'IN',
      'level': 55,
      'xp': 71000,
      'wins': 834,
      'perfect': 148,
      'rate': 84.0,
      'rp': 1920,
      'div': 'Diamond',
      'avatar': 'R'
    },
    {
      'username': 'BoxBuster',
      'country': 'TR',
      'level': 52,
      'xp': 66000,
      'wins': 778,
      'perfect': 135,
      'rate': 83.1,
      'rp': 1850,
      'div': 'Diamond',
      'avatar': 'B'
    },
    {
      'username': 'NineNinja',
      'country': 'ES',
      'level': 48,
      'xp': 61000,
      'wins': 712,
      'perfect': 121,
      'rate': 82.3,
      'rp': 1720,
      'div': 'Platinum',
      'avatar': 'N'
    },
    {
      'username': 'ColumnChamp',
      'country': 'IT',
      'level': 45,
      'xp': 56000,
      'wins': 658,
      'perfect': 108,
      'rate': 81.5,
      'rp': 1650,
      'div': 'Platinum',
      'avatar': 'C'
    },
    {
      'username': 'QuadQueen',
      'country': 'MX',
      'level': 42,
      'xp': 52000,
      'wins': 602,
      'perfect': 95,
      'rate': 80.2,
      'rp': 1520,
      'div': 'Platinum',
      'avatar': 'Q'
    },
    {
      'username': 'SolveStreak',
      'country': 'NL',
      'level': 39,
      'xp': 47000,
      'wins': 548,
      'perfect': 82,
      'rate': 79.4,
      'rp': 1420,
      'div': 'Gold',
      'avatar': 'S'
    },
    {
      'username': 'PencilPro',
      'country': 'SE',
      'level': 36,
      'xp': 43000,
      'wins': 495,
      'perfect': 71,
      'rate': 78.1,
      'rp': 1320,
      'div': 'Gold',
      'avatar': 'P'
    },
    {
      'username': 'HintHero',
      'country': 'PL',
      'level': 33,
      'xp': 39000,
      'wins': 442,
      'perfect': 59,
      'rate': 77.0,
      'rp': 1180,
      'div': 'Gold',
      'avatar': 'H'
    },
    {
      'username': 'GridGuru',
      'country': 'RU',
      'level': 30,
      'xp': 35000,
      'wins': 398,
      'perfect': 48,
      'rate': 75.8,
      'rp': 1080,
      'div': 'Silver',
      'avatar': 'G'
    },
    {
      'username': 'CellSeeker',
      'country': 'CN',
      'level': 27,
      'xp': 31000,
      'wins': 352,
      'perfect': 38,
      'rate': 74.5,
      'rp': 950,
      'div': 'Silver',
      'avatar': 'C'
    },
    {
      'username': 'NumNovice',
      'country': 'AR',
      'level': 24,
      'xp': 27000,
      'wins': 305,
      'perfect': 28,
      'rate': 73.2,
      'rp': 820,
      'div': 'Silver',
      'avatar': 'N'
    },
    {
      'username': 'PuzzlePal',
      'country': 'PT',
      'level': 21,
      'xp': 23000,
      'wins': 262,
      'perfect': 19,
      'rate': 71.8,
      'rp': 680,
      'div': 'Bronze',
      'avatar': 'P'
    },
    {
      'username': 'SudokuStar',
      'country': 'BE',
      'level': 18,
      'xp': 19500,
      'wins': 218,
      'perfect': 12,
      'rate': 70.1,
      'rp': 550,
      'div': 'Bronze',
      'avatar': 'S'
    },
    {
      'username': 'LogicLearner',
      'country': 'CH',
      'level': 15,
      'xp': 16000,
      'wins': 175,
      'perfect': 7,
      'rate': 68.5,
      'rp': 420,
      'div': 'Bronze',
      'avatar': 'L'
    },
    {
      'username': 'GridNewbie',
      'country': 'AT',
      'level': 12,
      'xp': 12500,
      'wins': 132,
      'perfect': 3,
      'rate': 66.0,
      'rp': 280,
      'div': 'Iron',
      'avatar': 'G'
    },
    {
      'username': 'CellStarter',
      'country': 'NO',
      'level': 8,
      'xp': 8000,
      'wins': 89,
      'perfect': 1,
      'rate': 62.5,
      'rp': 150,
      'div': 'Iron',
      'avatar': 'C'
    },
  ];

  static List<LeaderboardUser> getLevelLeaderboard() {
    final users = <LeaderboardUser>[];
    for (int i = 0; i < _mockUsers.length; i++) {
      final m = _mockUsers[i];
      users.add(LeaderboardUser(
        id: 'user_${i + 1}',
        username: m['username'] as String,
        avatarUrl: m['avatar'] as String?,
        countryCode: m['country'] as String,
        level: m['level'] as int,
        totalXp: m['xp'] as int,
        rank: i + 1,
        gamesWon: m['wins'] as int,
        perfectGames: m['perfect'] as int,
        winRate: m['rate'] as double,
        rankedPoints: m['rp'] as int,
        division: m['div'] as String,
        unlockedAchievementIds: _generateRandomAchievements(m['level'] as int),
        equippedBadgeIds: _generateRandomBadges(m['level'] as int),
        equippedFrame: _getFrameForLevel(m['level'] as int),
        joinedAt: DateTime.now().subtract(Duration(days: 30 + i * 15)),
        isOnline: i < 5 || i % 3 == 0,
      ));
    }
    return users;
  }

  static String? _getFrameForLevel(int level) {
    if (level >= 100) return 'frame_legendary';
    if (level >= 85) return 'frame_obsidian';
    if (level >= 70) return 'frame_crystal';
    if (level >= 55) return 'frame_ruby';
    if (level >= 45) return 'frame_sapphire';
    if (level >= 35) return 'frame_emerald';
    if (level >= 25) return 'frame_platinum';
    if (level >= 15) return 'frame_gold';
    if (level >= 5) return 'frame_silver';
    return null;
  }

  static List<LeaderboardUser> getRankedLeaderboard() {
    final users = getLevelLeaderboard();
    users.sort((a, b) => b.rankedPoints.compareTo(a.rankedPoints));
    for (int i = 0; i < users.length; i++) {
      users[i] = LeaderboardUser(
        id: users[i].id,
        username: users[i].username,
        avatarUrl: users[i].avatarUrl,
        countryCode: users[i].countryCode,
        level: users[i].level,
        totalXp: users[i].totalXp,
        rank: i + 1,
        gamesWon: users[i].gamesWon,
        perfectGames: users[i].perfectGames,
        winRate: users[i].winRate,
        rankedPoints: users[i].rankedPoints,
        division: users[i].division,
        unlockedAchievementIds: users[i].unlockedAchievementIds,
        equippedBadgeIds: users[i].equippedBadgeIds,
        equippedFrame: users[i].equippedFrame,
        joinedAt: users[i].joinedAt,
        isOnline: users[i].isOnline,
      );
    }
    return users;
  }

  static List<String> _generateRandomAchievements(int level) {
    final allAchievements = [
      'easy_5',
      'easy_10',
      'easy_50',
      'easy_100',
      'medium_5',
      'medium_10',
      'medium_50',
      'hard_5',
      'hard_20',
      'expert_10',
      'days_7',
      'days_30',
      'daily_7',
      'daily_30',
      'hints_10',
      'hints_100',
      'hints_500',
    ];
    final count = (level / 5).clamp(1, allAchievements.length).toInt();
    return allAchievements.take(count).toList();
  }

  static List<String> _generateRandomBadges(int level) {
    final badges = <String>[];
    if (level >= 10) badges.add('early_bird');
    if (level >= 25) badges.add('week_warrior');
    if (level >= 40) badges.add('puzzle_master');
    if (level >= 60) badges.add('legend');
    if (level >= 80) badges.add('champion');
    return badges;
  }

  /// Get current user's position in leaderboard (mock)
  static int getCurrentUserRank() => 47;

  /// Get current user data (mock)
  static LeaderboardUser getCurrentUser() {
    return LeaderboardUser(
      id: 'current_user',
      username: 'You',
      countryCode: 'TR',
      level: 5,
      totalXp: 1250,
      rank: 47,
      gamesWon: 23,
      perfectGames: 2,
      winRate: 65.0,
      rankedPoints: 380,
      division: 'Iron',
      unlockedAchievementIds: ['easy_5', 'hints_10'],
      equippedBadgeIds: [],
      joinedAt: DateTime.now().subtract(const Duration(days: 7)),
      isOnline: true,
    );
  }
}
