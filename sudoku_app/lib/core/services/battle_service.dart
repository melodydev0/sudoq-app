import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/battle_models.dart';
import 'auth_service.dart';
import 'local_duel_stats_service.dart';
import 'sudoku_generator.dart';

/// Connection status for real-time battles
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Service for managing online duel battles
/// Optimized for 100K+ concurrent users
class BattleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SudokuGenerator _generator = SudokuGenerator();

  // Collections
  static CollectionReference get _battles => _firestore.collection('battles');
  static CollectionReference get _matchmaking =>
      _firestore.collection('matchmaking');
  static CollectionReference get _duelLeaderboard =>
      _firestore.collection('duel_leaderboard');

  // Streams
  static StreamSubscription? _matchmakingSubscription;
  static StreamSubscription? _battleSubscription;
  static StreamSubscription? _connectionSubscription;

  // Current battle
  static String? _currentBattleId;
  static BattleRoom? _currentBattle;

  // Connection status
  static ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  static final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  static Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;
  static ConnectionStatus get connectionStatus => _connectionStatus;

  // Reconnection settings
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static int _reconnectAttempts = 0;
  static Timer? _reconnectTimer;

  // Timeouts
  static const Duration _matchmakingTimeout = Duration(minutes: 2);
  // ignore: unused_field - Reserved for future battle timeout feature
  static const Duration _battleTimeout = Duration(minutes: 30);
  static Timer? _matchmakingTimer;
  static Timer? _battleTimer;

  /// Get current battle ID
  static String? get currentBattleId => _currentBattleId;

  /// Get current battle
  static BattleRoom? get currentBattle => _currentBattle;

  /// Set connection status
  static void _setConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
    debugPrint('Connection status: $status');
  }

  // ==================== MATCHMAKING ====================

  /// Join matchmaking queue with timeout and reconnection support
  static Future<void> joinMatchmaking({
    Function(BattleRoom)? onMatchFound,
    Function(String)? onError,
    Function()? onTimeout,
  }) async {
    if (!AuthService.isSignedIn) {
      onError?.call('Not signed in');
      return;
    }

    _setConnectionStatus(ConnectionStatus.connecting);

    final oderId = AuthService.userId!;

    // Use local ELO - it's the source of truth
    await LocalDuelStatsService.init();
    final localElo = LocalDuelStatsService.elo;
    final division = LocalDuelStatsService.rank;

    // If signed in with Google, try to get cloud stats for comparison
    int elo = localElo;
    if (!AuthService.isAnonymous) {
      try {
        final profile = await AuthService.getUserProfile();
        final cloudElo = profile?['duelStats']?['elo'] as int? ??
            profile?['battleStats']?['elo'] as int? ??
            450;
        // Use higher of local or cloud (in case of sync issues)
        elo = localElo > cloudElo ? localElo : cloudElo;
      } catch (e) {
        debugPrint('Failed to fetch cloud stats, using local: $e');
      }
    }

    final entry = MatchmakingEntry(
      oderId: oderId,
      displayName: AuthService.displayName,
      photoUrl: AuthService.photoUrl,
      elo: elo,
      joinedAt: DateTime.now(),
    );

    try {
      // Add to matchmaking queue with division for optimized queries
      await _matchmaking.doc(oderId).set({
        ...entry.toMap(),
        'division': division,
        'status': 'searching',
      });
      debugPrint('Joined matchmaking queue (ELO: $elo, Division: $division)');

      _setConnectionStatus(ConnectionStatus.connected);

      // Start matchmaking timeout
      _matchmakingTimer?.cancel();
      _matchmakingTimer = Timer(_matchmakingTimeout, () {
        debugPrint('Matchmaking timed out');
        leaveMatchmaking();
        onTimeout?.call();
      });

      // Listen for match
      _matchmakingSubscription?.cancel();
      _matchmakingSubscription = _matchmaking.doc(oderId).snapshots().listen(
        (doc) async {
          if (!doc.exists) {
            // We were removed from queue - check if matched
            _matchmakingTimer?.cancel();
            final matchedBattleId = await _findMyBattle(oderId);
            if (matchedBattleId != null) {
              final battle = await getBattle(matchedBattleId);
              if (battle != null) {
                _currentBattleId = matchedBattleId;
                _currentBattle = battle;
                onMatchFound?.call(battle);
              }
            }
          }
        },
        onError: (e) {
          debugPrint('Matchmaking stream error: $e');
          _handleConnectionError(onError);
        },
      );

      // Try to find a match
      await _tryFindMatch(entry, onMatchFound, onError);
    } catch (e) {
      debugPrint('Matchmaking error: $e');
      _setConnectionStatus(ConnectionStatus.disconnected);
      onError?.call(e.toString());
    }
  }

  /// Handle connection errors with reconnection
  static void _handleConnectionError(Function(String)? onError) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setConnectionStatus(ConnectionStatus.disconnected);
      onError?.call('Connection lost. Please try again.');
      _reconnectAttempts = 0;
      return;
    }

    _setConnectionStatus(ConnectionStatus.reconnecting);
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      debugPrint(
          'Attempting reconnection ($_reconnectAttempts/$_maxReconnectAttempts)');
      // Reconnection logic would go here
    });
  }

  /// Try to find a match from the queue
  static Future<void> _tryFindMatch(
    MatchmakingEntry myEntry,
    Function(BattleRoom)? onMatchFound,
    Function(String)? onError,
  ) async {
    // Search parameters - expand ELO range over time
    const eloRangeExpansion = [100, 200, 300, 500, 1000];

    for (int i = 0; i < eloRangeExpansion.length; i++) {
      final eloRange = eloRangeExpansion[i];
      final minElo = myEntry.elo - eloRange;
      final maxElo = myEntry.elo + eloRange;

      // Query for potential opponents
      final query = await _matchmaking
          .where('elo', isGreaterThanOrEqualTo: minElo)
          .where('elo', isLessThanOrEqualTo: maxElo)
          .orderBy('elo')
          .orderBy('joinedAt')
          .limit(10)
          .get();

      for (final doc in query.docs) {
        if (doc.id == myEntry.oderId) continue; // Skip self

        final opponent = MatchmakingEntry.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Try to create match
        final success = await _createMatch(myEntry, opponent);
        if (success) {
          return; // Match created
        }
      }

      // Wait before expanding range
      if (i < eloRangeExpansion.length - 1) {
        await Future.delayed(const Duration(seconds: 5));

        // Check if still in queue
        final stillInQueue = await _matchmaking.doc(myEntry.oderId).get();
        if (!stillInQueue.exists) return; // We were matched by someone else
      }
    }
  }

  /// Create a match between two players
  static Future<bool> _createMatch(
    MatchmakingEntry player1Entry,
    MatchmakingEntry player2Entry,
  ) async {
    try {
      // Use transaction to prevent race conditions
      return await _firestore.runTransaction<bool>((transaction) async {
        // Check both players still in queue
        final p1Doc =
            await transaction.get(_matchmaking.doc(player1Entry.oderId));
        final p2Doc =
            await transaction.get(_matchmaking.doc(player2Entry.oderId));

        if (!p1Doc.exists || !p2Doc.exists) {
          return false; // One player already matched
        }

        // Calculate difficulty based on average ELO
        final avgElo = (player1Entry.elo + player2Entry.elo) / 2;
        final difficulty = _getDifficultyForElo(avgElo.toInt());

        // Generate puzzle
        final puzzleResult = _generator.generatePuzzle(
          difficulty: difficulty,
          gridSize: 9,
        );

        // Count empty cells
        int emptyCells = 0;
        for (final row in puzzleResult['puzzle']!) {
          for (final cell in row) {
            if (cell == 0) emptyCells++;
          }
        }

        // Create battle room
        final player1 = BattlePlayer(
          oderId: player1Entry.oderId,
          displayName: player1Entry.displayName,
          photoUrl: player1Entry.photoUrl,
          elo: player1Entry.elo,
          rank: AuthService.getRankDisplay(player1Entry.elo),
        );

        final player2 = BattlePlayer(
          oderId: player2Entry.oderId,
          displayName: player2Entry.displayName,
          photoUrl: player2Entry.photoUrl,
          elo: player2Entry.elo,
          rank: AuthService.getRankDisplay(player2Entry.elo),
        );

        final battleRef = _battles.doc();
        final battle = BattleRoom(
          id: battleRef.id,
          status: BattleStatus.countdown,
          difficulty: difficulty,
          createdAt: DateTime.now(),
          player1: player1,
          player2: player2,
          puzzle: puzzleResult['puzzle'],
          solution: puzzleResult['solution'],
          totalCells: emptyCells,
        );

        // Write battle
        transaction.set(battleRef, battle.toMap());

        // Remove both players from matchmaking
        transaction.delete(_matchmaking.doc(player1Entry.oderId));
        transaction.delete(_matchmaking.doc(player2Entry.oderId));

        debugPrint('Match created: ${battleRef.id}');
        return true;
      });
    } catch (e) {
      debugPrint('Create match error: $e');
      return false;
    }
  }

  /// Get difficulty based on average ELO
  static String _getDifficultyForElo(int elo) {
    if (elo < 600) return 'Easy';
    if (elo < 1000) return 'Medium';
    if (elo < 1400) return 'Hard';
    return 'Expert';
  }

  /// Leave matchmaking queue
  static Future<void> leaveMatchmaking() async {
    _matchmakingSubscription?.cancel();
    _matchmakingSubscription = null;
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    _setConnectionStatus(ConnectionStatus.disconnected);

    if (AuthService.isSignedIn) {
      try {
        await _matchmaking.doc(AuthService.userId).delete();
        debugPrint('Left matchmaking queue');
      } catch (e) {
        debugPrint('Leave matchmaking error: $e');
      }
    }
  }

  /// Find battle where I am a player
  static Future<String?> _findMyBattle(String oderId) async {
    try {
      // Check as player1
      var query = await _battles
          .where('player1.oderId', isEqualTo: oderId)
          .where('status', whereIn: ['countdown', 'playing'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      // Check as player2
      query = await _battles
          .where('player2.oderId', isEqualTo: oderId)
          .where('status', whereIn: ['countdown', 'playing'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      return null;
    } catch (e) {
      debugPrint('Find my battle error: $e');
      return null;
    }
  }

  // ==================== BATTLE MANAGEMENT ====================

  /// Get battle by ID
  static Future<BattleRoom?> getBattle(String battleId) async {
    try {
      final doc = await _battles.doc(battleId).get();
      if (doc.exists) {
        return BattleRoom.fromDoc(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get battle error: $e');
      return null;
    }
  }

  /// Listen to battle updates
  static Stream<BattleRoom?> battleStream(String battleId) {
    return _battles.doc(battleId).snapshots().map((doc) {
      if (doc.exists) {
        return BattleRoom.fromDoc(doc);
      }
      return null;
    });
  }

  /// Start battle (change status to playing)
  static Future<void> startBattle(String battleId) async {
    try {
      await _battles.doc(battleId).update({
        'status': BattleStatus.playing.name,
        'startedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Battle started: $battleId');
    } catch (e) {
      debugPrint('Start battle error: $e');
    }
  }

  /// Update player progress
  static Future<void> updateProgress({
    required String battleId,
    required int correctCells,
    required int totalCells,
    required int mistakes,
    List<List<int>>? currentGrid,
  }) async {
    if (!AuthService.isSignedIn) return;

    final oderId = AuthService.userId!;
    final progress =
        totalCells > 0 ? ((correctCells / totalCells) * 100).round() : 0;

    try {
      // Determine which player we are
      final battle = await getBattle(battleId);
      if (battle == null) return;

      String playerField;
      if (battle.player1?.oderId == oderId) {
        playerField = 'player1';
      } else if (battle.player2?.oderId == oderId) {
        playerField = 'player2';
      } else {
        return; // Not in this battle
      }

      await _battles.doc(battleId).update({
        '$playerField.progress': progress,
        '$playerField.correctCells': correctCells,
        '$playerField.mistakes': mistakes,
        if (currentGrid != null) '$playerField.currentGrid': currentGrid,
      });
    } catch (e) {
      debugPrint('Update progress error: $e');
    }
  }

  /// Finish battle for current player
  static Future<void> finishBattle(String battleId) async {
    if (!AuthService.isSignedIn) return;

    final oderId = AuthService.userId!;

    try {
      final battle = await getBattle(battleId);
      if (battle == null) return;

      String playerField;
      if (battle.player1?.oderId == oderId) {
        playerField = 'player1';
      } else if (battle.player2?.oderId == oderId) {
        playerField = 'player2';
      } else {
        return;
      }

      await _battles.doc(battleId).update({
        '$playerField.isFinished': true,
        '$playerField.finishedAt': FieldValue.serverTimestamp(),
        '$playerField.progress': 100,
      });

      // Check if both players finished or determine winner
      await _checkBattleEnd(battleId);
    } catch (e) {
      debugPrint('Finish battle error: $e');
    }
  }

  /// Check if battle should end
  static Future<void> _checkBattleEnd(String battleId) async {
    try {
      final battle = await getBattle(battleId);
      if (battle == null || battle.status == BattleStatus.finished) return;

      final p1Finished = battle.player1?.isFinished ?? false;
      final p2Finished = battle.player2?.isFinished ?? false;

      if (p1Finished || p2Finished) {
        // Someone finished - they win!
        String? winnerId;

        if (p1Finished && !p2Finished) {
          winnerId = battle.player1?.oderId;
        } else if (p2Finished && !p1Finished) {
          winnerId = battle.player2?.oderId;
        } else if (p1Finished && p2Finished) {
          // Both finished - compare times
          final p1Time = battle.player1?.finishedAt;
          final p2Time = battle.player2?.finishedAt;

          if (p1Time != null && p2Time != null) {
            winnerId = p1Time.isBefore(p2Time)
                ? battle.player1?.oderId
                : battle.player2?.oderId;
          }
        }

        await _battles.doc(battleId).update({
          'status': BattleStatus.finished.name,
          'winnerId': winnerId,
          'finishedAt': FieldValue.serverTimestamp(),
        });

        // Update player stats
        if (winnerId != null) {
          await _updatePlayerStats(battle, winnerId);
        }

        debugPrint('Battle finished: $battleId, winner: $winnerId');
      }
    } catch (e) {
      debugPrint('Check battle end error: $e');
    }
  }

  /// Update player stats after battle (both local and cloud if signed in)
  static Future<void> _updatePlayerStats(
      BattleRoom battle, String winnerId) async {
    final p1 = battle.player1;
    final p2 = battle.player2;

    if (p1 == null || p2 == null) return;

    final currentUserId = AuthService.userId;
    if (currentUserId == null) return;

    // Determine if current user won
    final isPlayer1 = currentUserId == p1.oderId;
    final myPlayer = isPlayer1 ? p1 : p2;
    final opponentPlayer = isPlayer1 ? p2 : p1;
    final won = currentUserId == winnerId;

    // Calculate ELO change
    final gamesPlayed = LocalDuelStatsService.totalGames;
    final newElo = EloCalculator.calculateNewElo(
      playerElo: myPlayer.elo,
      opponentElo: opponentPlayer.elo,
      won: won,
      gamesPlayed: gamesPlayed,
    );
    final eloChange = (newElo - myPlayer.elo).abs();

    // Calculate completion time
    final startTime = battle.startedAt ?? battle.createdAt;
    final endTime = myPlayer.finishedAt ?? DateTime.now();
    final completionTime = endTime.difference(startTime);

    // Always update local stats
    if (won) {
      await LocalDuelStatsService.recordWin(eloChange);
    } else {
      await LocalDuelStatsService.recordLoss(eloChange);
    }
    debugPrint('Local stats updated: won=$won, eloChange=$eloChange');

    // Save match history for current user
    await _saveMatchHistory(
      oderId: currentUserId,
      battle: battle,
      won: won,
      eloChange: eloChange,
      newElo: newElo,
      completionTime: completionTime,
      mistakes: myPlayer.mistakes,
    );

    // Update cloud stats if signed in with Google (not anonymous)
    if (AuthService.isSignedIn && !AuthService.isAnonymous) {
      await AuthService.updateBattleStats(
        won: won,
        eloChange: eloChange,
        newElo: newElo,
        completionTimeSeconds: completionTime.inSeconds,
      );
      await LocalDuelStatsService.markSynced();
      debugPrint('Cloud stats synced');
    }
  }

  /// Resign from battle
  static Future<void> resignBattle(String battleId) async {
    if (!AuthService.isSignedIn) return;

    final oderId = AuthService.userId!;

    try {
      final battle = await getBattle(battleId);
      if (battle == null) return;

      // Opponent wins
      final winnerId = battle.player1?.oderId == oderId
          ? battle.player2?.oderId
          : battle.player1?.oderId;

      await _battles.doc(battleId).update({
        'status': BattleStatus.finished.name,
        'winnerId': winnerId,
        'finishedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Resigned from battle: $battleId');
    } catch (e) {
      debugPrint('Resign battle error: $e');
    }
  }

  /// Clean up all resources
  static void dispose() {
    _matchmakingSubscription?.cancel();
    _battleSubscription?.cancel();
    _connectionSubscription?.cancel();
    _matchmakingTimer?.cancel();
    _battleTimer?.cancel();
    _reconnectTimer?.cancel();

    _matchmakingSubscription = null;
    _battleSubscription = null;
    _connectionSubscription = null;
    _matchmakingTimer = null;
    _battleTimer = null;
    _reconnectTimer = null;

    _currentBattleId = null;
    _currentBattle = null;
    _reconnectAttempts = 0;

    _setConnectionStatus(ConnectionStatus.disconnected);
  }

  /// Save match to user's duel history
  static Future<void> _saveMatchHistory({
    required String oderId,
    required BattleRoom battle,
    required bool won,
    required int eloChange,
    required int newElo,
    required Duration completionTime,
    required int mistakes,
  }) async {
    if (oderId.isEmpty) return;

    try {
      final opponent = battle.getOpponent(oderId);
      final historyRef = _firestore
          .collection('users')
          .doc(oderId)
          .collection('duel_history')
          .doc(battle.id);

      await historyRef.set({
        'oderId': oderId,
        'battleId': battle.id,
        'opponentId': opponent?.oderId,
        'opponentName': opponent?.displayName ?? 'Unknown',
        'opponentPhotoUrl': opponent?.photoUrl,
        'opponentElo': opponent?.elo ?? 0,
        'won': won,
        'eloChange': won ? eloChange : -eloChange,
        'newElo': newElo,
        'completionTimeSeconds': completionTime.inSeconds,
        'mistakes': mistakes,
        'difficulty': battle.difficulty,
        'isTestBattle': battle.isTestBattle,
        'playedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Match history saved for user $oderId');
    } catch (e) {
      debugPrint('Error saving match history: $e');
    }
  }

  /// Get user's duel history (paginated)
  static Future<List<Map<String, dynamic>>> getDuelHistory({
    required String oderId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(oderId)
          .collection('duel_history')
          .orderBy('playedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting duel history: $e');
      return [];
    }
  }

  /// Get duel leaderboard (paginated, by division or global)
  static Future<List<Map<String, dynamic>>> getDuelLeaderboard({
    String? division,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query =
          _duelLeaderboard.orderBy('elo', descending: true).limit(limit);

      if (division != null && division.isNotEmpty) {
        query = _duelLeaderboard
            .where('division', isEqualTo: division)
            .orderBy('elo', descending: true)
            .limit(limit);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting duel leaderboard: $e');
      return [];
    }
  }

  // ==================== TEST MODE ====================

  // In-memory test battle storage
  static BattleRoom? _localTestBattle;

  /// AI difficulty levels for Play Against AI mode
  static const Map<String, Map<String, dynamic>> aiDifficulties = {
    'easy': {
      'name': 'Rookie Bot 🤖',
      'minInterval': 8, // seconds
      'maxInterval': 11, // seconds
      'eloOffset': -100,
      'eloWin': 15, // ELO gained on win
      'eloLoss': 25, // ELO lost on loss
    },
    'medium': {
      'name': 'Pro Bot 🤖',
      'minInterval': 6,
      'maxInterval': 9,
      'eloOffset': 0,
      'eloWin': 25,
      'eloLoss': 20,
    },
    'hard': {
      'name': 'Master Bot 🤖',
      'minInterval': 7, // 7-10 seconds
      'maxInterval': 10,
      'eloOffset': 100,
      'eloWin': 40, // More ELO for beating hard bot
      'eloLoss': 15, // Less ELO lost against hard bot
    },
  };

  // Current AI difficulty for test battles
  static String _currentAiDifficulty = 'medium';
  static String get currentAiDifficulty => _currentAiDifficulty;

  /// Create a test battle with a bot opponent for testing (LOCAL - no Firebase needed)
  /// [aiDifficulty] can be 'easy', 'medium', or 'hard'
  static Future<BattleRoom?> createTestBattle(
      {String aiDifficulty = 'medium'}) async {
    debugPrint('[PlayAI] createTestBattle start: $aiDifficulty');
    try {
      _currentAiDifficulty = aiDifficulty;
      final aiConfig =
          aiDifficulties[aiDifficulty] ?? aiDifficulties['medium']!;

      await LocalDuelStatsService.init();
      final playerElo = LocalDuelStatsService.elo;

      // Create player (use local ID if not signed in)
      final oderId = AuthService.userId ??
          'local_player_${DateTime.now().millisecondsSinceEpoch}';
      final player1 = BattlePlayer(
        oderId: oderId,
        displayName: AuthService.isSignedIn ? AuthService.displayName : 'You',
        photoUrl: AuthService.photoUrl,
        elo: playerElo,
        rank: LocalDuelStatsService.getRankDisplay(playerElo),
      );

      // Create bot opponent with difficulty-based ELO
      final botElo = playerElo + (aiConfig['eloOffset'] as int);
      final player2 = BattlePlayer(
        oderId: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        displayName: aiConfig['name'] as String,
        photoUrl: null,
        elo: botElo.clamp(100, 2000),
        rank: LocalDuelStatsService.getRankDisplay(botElo.clamp(100, 2000)),
      );

      // Generate puzzle based on AI difficulty
      final String difficulty;
      switch (aiDifficulty) {
        case 'easy':
          difficulty = 'Easy';
          break;
        case 'hard':
          difficulty = 'Hard'; // Master Bot = Hard puzzle
          break;
        case 'medium':
        default:
          difficulty = 'Medium';
      }
      final puzzleResult = _generator.generatePuzzle(
        difficulty: difficulty,
        gridSize: 9,
      );

      // Count empty cells
      int emptyCells = 0;
      for (final row in puzzleResult['puzzle']!) {
        for (final cell in row) {
          if (cell == 0) emptyCells++;
        }
      }

      // Create LOCAL battle room (no Firestore needed)
      final battleId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final battle = BattleRoom(
        id: battleId,
        status: BattleStatus.playing,
        difficulty: difficulty,
        createdAt: DateTime.now(),
        startedAt: DateTime.now(),
        player1: player1,
        player2: player2,
        puzzle: puzzleResult['puzzle'],
        solution: puzzleResult['solution'],
        totalCells: emptyCells,
        isTestBattle: true,
      );

      // Store locally (not in Firestore)
      _localTestBattle = battle;
      _currentBattleId = battleId;
      _currentBattle = battle;

      debugPrint('Local test battle created: $battleId');
      return battle;
    } catch (e, st) {
      debugPrint('Create test battle error: $e');
      debugPrint('[PlayAI] createTestBattle stack: $st');
      return null;
    }
  }

  /// Get test battle (for local testing)
  static BattleRoom? getLocalTestBattle() => _localTestBattle;

  /// Get bot move interval based on AI difficulty (returns random seconds in range)
  static int getBotMoveInterval() {
    final aiConfig =
        aiDifficulties[_currentAiDifficulty] ?? aiDifficulties['medium']!;
    final minInterval = aiConfig['minInterval'] as int;
    final maxInterval = aiConfig['maxInterval'] as int;

    // Random interval between min and max (inclusive)
    final random =
        DateTime.now().millisecondsSinceEpoch % (maxInterval - minInterval + 1);
    return minInterval + random;
  }

  /// Update local test battle
  static void updateLocalTestBattle(BattleRoom battle) {
    _localTestBattle = battle;
    _currentBattle = battle;
  }

  /// Simulate bot progress (call periodically during test battle)
  static Future<void> simulateBotProgress(String battleId) async {
    try {
      final battle = await getBattle(battleId);
      if (battle == null || battle.status != BattleStatus.playing) return;

      final botPlayer = battle.player2;
      if (botPlayer == null || !botPlayer.oderId.startsWith('bot_')) return;

      // Get current bot progress
      final currentProgress = botPlayer.progress;
      final currentCorrect = botPlayer.correctCells;

      // Bot makes slow progress (1-3 cells per update)
      if (currentProgress < 95) {
        final newCorrect = currentCorrect + 1;
        final totalCells = battle.totalCells;
        final newProgress =
            totalCells > 0 ? ((newCorrect / totalCells) * 100).round() : 0;

        await _battles.doc(battleId).update({
          'player2.progress':
              newProgress.clamp(0, 95), // Bot never wins automatically
          'player2.correctCells': newCorrect,
        });
      }
    } catch (e) {
      debugPrint('Simulate bot progress error: $e');
    }
  }
}
