import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely parse DateTime from Firestore (Timestamp, DateTime, or String)
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Helper to parse 2D array from Firestore (handles both JSON string and List)
List<List<int>>? _parse2DArray(dynamic value) {
  if (value == null) return null;
  
  List<dynamic> list;
  if (value is String) {
    list = jsonDecode(value) as List<dynamic>;
  } else if (value is List) {
    list = value;
  } else {
    return null;
  }
  
  return list
      .map((row) => (row as List).map((cell) => (cell as num).toInt()).toList())
      .toList();
}

/// Battle room status
enum BattleStatus {
  waiting, // Waiting for opponent
  matched, // Both players found, preparing game
  countdown, // Countdown before game starts
  playing, // Game in progress
  finished, // Game finished
  cancelled, // Game cancelled
}

/// Player in a battle
class BattlePlayer {
  final String oderId;
  final String displayName;
  final String? photoUrl;
  final String? equippedFrame;
  final int elo;
  final String rank;
  final String? countryCode;
  final String? avatarAsset;

  // Game state
  final int progress; // 0-100 percentage
  final int mistakes;
  final int correctCells;
  final bool isFinished;
  final DateTime? finishedAt;
  final List<List<int>>? currentGrid;

  const BattlePlayer({
    required this.oderId,
    required this.displayName,
    this.photoUrl,
    this.equippedFrame,
    required this.elo,
    required this.rank,
    this.countryCode,
    this.avatarAsset,
    this.progress = 0,
    this.mistakes = 0,
    this.correctCells = 0,
    this.isFinished = false,
    this.finishedAt,
    this.currentGrid,
  });

  factory BattlePlayer.fromMap(Map<String, dynamic> map) {
    return BattlePlayer(
      oderId: map['oderId'] ?? '',
      displayName: map['displayName'] ?? 'Player',
      photoUrl: map['photoUrl'],
      equippedFrame: map['equippedFrame'] as String?,
      elo: map['elo'] ?? 450,
      rank: map['rank'] ?? 'Rookie',
      countryCode: map['countryCode'],
      avatarAsset: map['avatarAsset'],
      progress: map['progress'] ?? 0,
      mistakes: map['mistakes'] ?? 0,
      correctCells: map['correctCells'] ?? 0,
      isFinished: map['isFinished'] ?? false,
      finishedAt: map['finishedAt'] != null
          ? _parseDateTime(map['finishedAt'])
          : null,
      currentGrid: map['currentGrid'] != null
          ? (map['currentGrid'] as List)
              .map((row) => (row as List).map((cell) => (cell as num).toInt()).toList())
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oderId': oderId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'equippedFrame': equippedFrame,
      'elo': elo,
      'rank': rank,
      'countryCode': countryCode,
      'avatarAsset': avatarAsset,
      'progress': progress,
      'mistakes': mistakes,
      'correctCells': correctCells,
      'isFinished': isFinished,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'currentGrid': currentGrid,
    };
  }

  BattlePlayer copyWith({
    String? oderId,
    String? displayName,
    String? photoUrl,
    String? equippedFrame,
    int? elo,
    String? rank,
    String? countryCode,
    String? avatarAsset,
    int? progress,
    int? mistakes,
    int? correctCells,
    bool? isFinished,
    DateTime? finishedAt,
    List<List<int>>? currentGrid,
  }) {
    return BattlePlayer(
      oderId: oderId ?? this.oderId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      equippedFrame: equippedFrame ?? this.equippedFrame,
      elo: elo ?? this.elo,
      rank: rank ?? this.rank,
      countryCode: countryCode ?? this.countryCode,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      progress: progress ?? this.progress,
      mistakes: mistakes ?? this.mistakes,
      correctCells: correctCells ?? this.correctCells,
      isFinished: isFinished ?? this.isFinished,
      finishedAt: finishedAt ?? this.finishedAt,
      currentGrid: currentGrid ?? this.currentGrid,
    );
  }
}

/// Battle room data
class BattleRoom {
  final String id;
  final BattleStatus status;
  final String difficulty;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  final BattlePlayer? player1;
  final BattlePlayer? player2;

  final List<List<int>>? puzzle;
  final List<List<int>>? solution;

  final String? winnerId;
  final int totalCells; // Total cells to fill
  final bool isTestBattle; // Flag for test/bot battles

  const BattleRoom({
    required this.id,
    required this.status,
    required this.difficulty,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.player1,
    this.player2,
    this.puzzle,
    this.solution,
    this.winnerId,
    this.totalCells = 0,
    this.isTestBattle = false,
  });

  factory BattleRoom.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BattleRoom.fromMap(data, doc.id);
  }

  factory BattleRoom.fromMap(Map<String, dynamic> map, String id) {
    return BattleRoom(
      id: id,
      status: BattleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BattleStatus.waiting,
      ),
      difficulty: map['difficulty'] ?? 'Medium',
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      startedAt: map['startedAt'] != null
          ? _parseDateTime(map['startedAt'])
          : null,
      finishedAt: map['finishedAt'] != null
          ? _parseDateTime(map['finishedAt'])
          : null,
      player1:
          map['player1'] != null ? BattlePlayer.fromMap(map['player1']) : null,
      player2:
          map['player2'] != null ? BattlePlayer.fromMap(map['player2']) : null,
      puzzle: _parse2DArray(map['puzzle']),
      solution: _parse2DArray(map['solution']),
      winnerId: map['winnerId'],
      totalCells: map['totalCells'] ?? 0,
      isTestBattle: map['isTestBattle'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'difficulty': difficulty,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'player1': player1?.toMap(),
      'player2': player2?.toMap(),
      'puzzle': puzzle,
      'solution': solution,
      'winnerId': winnerId,
      'totalCells': totalCells,
      'isTestBattle': isTestBattle,
    };
  }

  /// Check if room is full
  bool get isFull => player1 != null && player2 != null;

  /// Check if game is in progress
  bool get isPlaying => status == BattleStatus.playing;

  /// Check if game is finished
  bool get isFinished => status == BattleStatus.finished;

  /// Get opponent for a player
  BattlePlayer? getOpponent(String oderId) {
    if (player1?.oderId == oderId) return player2;
    if (player2?.oderId == oderId) return player1;
    return null;
  }

  /// Get self player data
  BattlePlayer? getSelf(String oderId) {
    if (player1?.oderId == oderId) return player1;
    if (player2?.oderId == oderId) return player2;
    return null;
  }

  /// Check if player is in this room
  bool hasPlayer(String oderId) {
    return player1?.oderId == oderId || player2?.oderId == oderId;
  }
}

/// Matchmaking queue entry
class MatchmakingEntry {
  final String oderId;
  final String displayName;
  final String? photoUrl;
  final String? equippedFrame;
  final int elo;
  final String division;
  final DateTime joinedAt;
  final String status;

  const MatchmakingEntry({
    required this.oderId,
    required this.displayName,
    this.photoUrl,
    this.equippedFrame,
    required this.elo,
    this.division = 'Bronze',
    required this.joinedAt,
    this.status = 'searching',
  });

  factory MatchmakingEntry.fromMap(Map<String, dynamic> map, String oderId) {
    return MatchmakingEntry(
      oderId: oderId,
      displayName: map['displayName'] ?? 'Player',
      photoUrl: map['photoUrl'],
      equippedFrame: map['equippedFrame'] as String?,
      elo: map['elo'] ?? 450,
      division: map['division'] ?? 'Bronze',
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'searching',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'equippedFrame': equippedFrame,
      'elo': elo,
      'division': division,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
    };
  }
}

/// Battle result for display
class BattleResult {
  final bool won;
  final bool isDraw;
  final int eloChange;
  final int newElo;
  final int xpEarned;
  final Duration completionTime;
  final int mistakes;
  final BattlePlayer? opponent;
  final String? newRank;
  final bool rankChanged;

  const BattleResult({
    required this.won,
    this.isDraw = false,
    required this.eloChange,
    required this.newElo,
    required this.xpEarned,
    required this.completionTime,
    required this.mistakes,
    this.opponent,
    this.newRank,
    this.rankChanged = false,
  });
}

/// ELO Calculator
class EloCalculator {
  /// K factor for ELO calculation
  /// Higher K = more volatile ratings
  static const int kFactorNew = 40; // New players (< 30 games)
  static const int kFactorNormal = 32; // Normal players
  static const int kFactorMaster = 24; // High rated players (> 2000)

  // ────────────────────── ELO gain / loss bounds ──────────────────────
  //
  // The raw Elo formula (K * (actual - expected)) produces very small gains
  // and very large losses once the player's rating starts to pull away from
  // the matchmaking pool. For example at 600 ELO facing a 100 ELO opponent
  // with K=32 and a 2× online multiplier, the raw win is only ~3 ELO while
  // a loss is ~-61 ELO. The bounds below:
  //
  //  • guarantee that a win always feels like progress (minWin = 15),
  //  • cap huge swings on both sides (max 50 win / 25 loss),
  //  • make the system asymmetric in favour of winning so that climbing the
  //    ladder stays rewarding even as matchmaking thins out the opponent
  //    pool.
  //
  // Floors/ceilings are applied AFTER the multiplier, so the online duel
  // vs bot match bonus still affects mid-range results but extremes stay
  // bounded.

  /// Minimum ELO gained on a win.
  static const int minEloWin = 15;

  /// Maximum ELO gained on a win.
  static const int maxEloWin = 50;

  /// Minimum ELO lost on a loss (i.e. you always lose at least this many).
  static const int minEloLoss = 5;

  /// Maximum ELO lost on a single loss.
  static const int maxEloLoss = 25;

  /// Maximum ELO swing on a draw (rarely used in this app).
  static const int maxEloDraw = 10;

  /// Calculate expected score
  static double expectedScore(int playerElo, int opponentElo) {
    return 1.0 / (1.0 + pow(10.0, (opponentElo - playerElo) / 400.0));
  }

  /// Calculate new ELO after a game
  static int calculateNewElo({
    required int playerElo,
    required int opponentElo,
    required bool won,
    required int gamesPlayed,
    bool isDraw = false,
    double multiplier = 1.0,
  }) {
    // Determine K factor
    int k;
    if (gamesPlayed < 30) {
      k = kFactorNew;
    } else if (playerElo > 2000) {
      k = kFactorMaster;
    } else {
      k = kFactorNormal;
    }

    // Calculate expected and actual scores
    final expected = expectedScore(playerElo, opponentElo);
    final actual = isDraw ? 0.5 : (won ? 1.0 : 0.0);

    // Calculate raw ELO change (multiplier allows online duels to give more ELO).
    int change = (k * multiplier * (actual - expected)).round();

    // Apply gain/loss bounds so that:
    //  - winning always gives at least `minEloWin`, capped at `maxEloWin`
    //  - losing never costs more than `maxEloLoss`, but always at least
    //    `minEloLoss` so wins remain meaningful vs losses
    if (isDraw) {
      if (change > maxEloDraw) change = maxEloDraw;
      if (change < -maxEloDraw) change = -maxEloDraw;
    } else if (won) {
      if (change < minEloWin) change = minEloWin;
      if (change > maxEloWin) change = maxEloWin;
    } else {
      // `change` is negative on a loss (or near zero for big underdogs).
      if (change > -minEloLoss) change = -minEloLoss;
      if (change < -maxEloLoss) change = -maxEloLoss;
    }

    final newElo = playerElo + change;

    // Minimum ELO is 0
    return newElo.clamp(0, 9999);
  }

  /// Calculate ELO change (for display)
  static int calculateEloChange({
    required int playerElo,
    required int opponentElo,
    required bool won,
    required int gamesPlayed,
    bool isDraw = false,
    double multiplier = 1.0,
  }) {
    final newElo = calculateNewElo(
      playerElo: playerElo,
      opponentElo: opponentElo,
      won: won,
      gamesPlayed: gamesPlayed,
      isDraw: isDraw,
      multiplier: multiplier,
    );
    return newElo - playerElo;
  }
}
