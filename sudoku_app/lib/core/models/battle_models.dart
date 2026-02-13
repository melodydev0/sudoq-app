import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int elo;
  final String rank;

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
    required this.elo,
    required this.rank,
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
      elo: map['elo'] ?? 800,
      rank: map['rank'] ?? 'Row',
      progress: map['progress'] ?? 0,
      mistakes: map['mistakes'] ?? 0,
      correctCells: map['correctCells'] ?? 0,
      isFinished: map['isFinished'] ?? false,
      finishedAt: map['finishedAt'] != null
          ? (map['finishedAt'] as Timestamp).toDate()
          : null,
      currentGrid: map['currentGrid'] != null
          ? (map['currentGrid'] as List)
              .map((row) => (row as List).map((cell) => cell as int).toList())
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oderId': oderId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'elo': elo,
      'rank': rank,
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
    int? elo,
    String? rank,
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
      elo: elo ?? this.elo,
      rank: rank ?? this.rank,
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
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      finishedAt: map['finishedAt'] != null
          ? (map['finishedAt'] as Timestamp).toDate()
          : null,
      player1:
          map['player1'] != null ? BattlePlayer.fromMap(map['player1']) : null,
      player2:
          map['player2'] != null ? BattlePlayer.fromMap(map['player2']) : null,
      puzzle: map['puzzle'] != null
          ? (map['puzzle'] as List)
              .map((row) => (row as List).map((cell) => cell as int).toList())
              .toList()
          : null,
      solution: map['solution'] != null
          ? (map['solution'] as List)
              .map((row) => (row as List).map((cell) => cell as int).toList())
              .toList()
          : null,
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
  final int elo;
  final String division;
  final DateTime joinedAt;
  final String status;

  const MatchmakingEntry({
    required this.oderId,
    required this.displayName,
    this.photoUrl,
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

    // Calculate new ELO
    final change = (k * (actual - expected)).round();
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
  }) {
    final newElo = calculateNewElo(
      playerElo: playerElo,
      opponentElo: opponentElo,
      won: won,
      gamesPlayed: gamesPlayed,
      isDraw: isDraw,
    );
    return newElo - playerElo;
  }
}
