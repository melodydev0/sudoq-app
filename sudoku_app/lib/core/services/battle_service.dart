import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/battle_models.dart';
import 'auth_service.dart';
import 'level_service.dart';
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
  static FirebaseFirestore? _firestoreInstance;
  static FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
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
  static StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  static Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  static void _ensureControllerOpen() {
    if (_connectionStatusController.isClosed) {
      _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
    }
  }
  static ConnectionStatus get connectionStatus => _connectionStatus;

  // Reconnection settings
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static int _reconnectAttempts = 0;
  static Timer? _reconnectTimer;

  // Cancellation flag for active matchmaking search
  static bool _matchmakingCancelled = false;

  // Timeouts
  static const Duration _matchmakingTimeout = Duration(minutes: 2);
  static const Duration _matchmakingHeartbeat = Duration(seconds: 12);
  static const Duration _entryTtl = Duration(minutes: 2);
  // ignore: unused_field - Reserved for future battle timeout feature
  static const Duration _battleTimeout = Duration(minutes: 30);
  static Timer? _matchmakingTimer;
  static Timer? _matchmakingHeartbeatTimer;
  static Timer? _battleTimer;

  /// Get current battle ID
  static String? get currentBattleId => _currentBattleId;

  /// Get current battle
  static BattleRoom? get currentBattle => _currentBattle;

  /// Set connection status
  static void _setConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
    debugPrint('Connection status: $status');
  }

  // ==================== MATCHMAKING ====================

  /// Join matchmaking queue with timeout and reconnection support
  static Future<void> joinMatchmaking({
    Function(BattleRoom)? onMatchFound,
    Function(String)? onError,
    Function()? onTimeout,
  }) async {
    // Auth is normally kicked off at app startup (fire-and-forget anonymous
    // sign-in in main.dart). But that call can silently fail (no network at
    // launch, Firebase init race, cold-start timeout), leaving the user
    // permanently stuck on "Connecting to server…". Re-trigger sign-in here
    // if needed. `signInAnonymously()` is re-entrancy-safe: it returns the
    // in-flight future if one is already running.
    if (!AuthService.isSignedIn) {
      try {
        await AuthService.signInAnonymously()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('[BattleService] anonymous sign-in during joinMatchmaking failed: $e');
      }
    }

    // Give Firebase a brief moment to propagate the new auth state to the
    // local user object (authStateChanges is asynchronous).
    if (!AuthService.isSignedIn) {
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (AuthService.isSignedIn) break;
      }
    }

    if (!AuthService.isSignedIn) {
      onError?.call('Could not connect to server. Please check your internet and try again.');
      return;
    }

    _ensureControllerOpen();
    _setConnectionStatus(ConnectionStatus.connecting);
    _matchmakingCancelled = false;

    final oderId = AuthService.userId!;

    // Use local ELO - it's the source of truth
    await LocalDuelStatsService.init();
    final localElo = LocalDuelStatsService.elo;
    final division = LocalDuelStatsService.rank;

    // If signed in with Google, try to get cloud stats for comparison
    // Timeout prevents freeze when Firestore is slow/unreachable
    int elo = localElo;
    if (!AuthService.isAnonymous) {
      try {
        final profile = await AuthService.getUserProfile()
            .timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('getUserProfile timeout - using local ELO');
          return null;
        });
        if (profile != null) {
          final cloudElo = profile['duelStats']?['elo'] as int? ??
              profile['battleStats']?['elo'] as int? ??
              450;
          elo = localElo > cloudElo ? localElo : cloudElo;
        }
      } catch (e) {
        debugPrint('Failed to fetch cloud stats, using local: $e');
      }
    }

    final playerCountryCode = AuthService.getCountryCode();

    final entry = MatchmakingEntry(
      oderId: oderId,
      displayName: AuthService.displayName,
      photoUrl: AuthService.photoUrl,
      equippedFrame: LevelService.selectedFrameId,
      elo: elo,
      joinedAt: DateTime.now(),
    );

    try {
      // Clean up any stale matchmaking entry from a previous session
      // to avoid Firestore update rule conflicts (e.g. ELO mismatch)
      try {
        await _matchmaking.doc(oderId).delete();
      } catch (_) {}

      // Add queue entry and keep it fresh with heartbeat.
      await _matchmaking.doc(oderId).set({
        ...entry.toMap(),
        'division': division,
        'countryCode': playerCountryCode,
        'status': 'searching',
        'lastSeen': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(_entryTtl)),
      });
      debugPrint('Joined matchmaking queue (ELO: $elo, Division: $division)');

      _setConnectionStatus(ConnectionStatus.connected);
      _startMatchmakingHeartbeat(oderId);

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
          if (_matchmakingCancelled) return;
          if (!doc.exists) {
            // Stale cleanup or manual removal. Timeout handler will surface UX.
            return;
          }

          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = data['status'] as String? ?? 'searching';
          if (status != 'matched') return;

          final battleId = data['battleId'] as String?;
          if (battleId == null || battleId.isEmpty) return;

          _matchmakingTimer?.cancel();
          _matchmakingHeartbeatTimer?.cancel();

          final battle = await _getBattleWithRetry(battleId);
          if (battle != null) {
            _currentBattleId = battleId;
            _currentBattle = battle;
            onMatchFound?.call(battle);
          } else {
            onError?.call('Matched but battle sync failed. Please retry.');
          }
        },
        onError: (e) {
          debugPrint('Matchmaking stream error: $e');
          _handleConnectionError(onError);
        },
      );
    } catch (e) {
      debugPrint('Matchmaking error: $e');
      _setConnectionStatus(ConnectionStatus.disconnected);
      onError?.call(e.toString());
    }
  }

  static void _startMatchmakingHeartbeat(String oderId) {
    _matchmakingHeartbeatTimer?.cancel();
    _matchmakingHeartbeatTimer =
        Timer.periodic(_matchmakingHeartbeat, (timer) async {
      if (_matchmakingCancelled) return;
      try {
        await _matchmaking.doc(oderId).update({
          'lastSeen': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(_entryTtl)),
        });
      } catch (e) {
        debugPrint('Matchmaking heartbeat error: $e');
      }
    });
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

  // Match creation is server-authoritative (Cloud Functions).

  /// Leave matchmaking queue
  static Future<void> leaveMatchmaking() async {
    _matchmakingCancelled = true;
    _matchmakingSubscription?.cancel();
    _matchmakingSubscription = null;
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    _matchmakingHeartbeatTimer?.cancel();
    _matchmakingHeartbeatTimer = null;
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

  static Future<BattleRoom?> _getBattleWithRetry(
    String battleId, {
    int maxAttempts = 20,
    Duration delay = const Duration(milliseconds: 400),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (_matchmakingCancelled) return null;
      final battle = await getBattle(battleId);
      if (battle != null) return battle;
      if (i < maxAttempts - 1) {
        await Future.delayed(delay);
      }
    }
    return null;
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
    debugPrint('[BattleService] Starting battleStream for: $battleId');
    return _battles.doc(battleId).snapshots().map((doc) {
      debugPrint('[BattleService] Snapshot received - exists: ${doc.exists}');
      if (doc.exists) {
        try {
          final battle = BattleRoom.fromDoc(doc);
          debugPrint('[BattleService] Parsed battle - status: ${battle.status}, '
              'p1Progress: ${battle.player1?.progress}, p1Mistakes: ${battle.player1?.mistakes}, '
              'p2Progress: ${battle.player2?.progress}, p2Mistakes: ${battle.player2?.mistakes}');
          return battle;
        } catch (e) {
          debugPrint('[BattleService] Error parsing battle: $e');
          return null;
        }
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

  // Throttle for updateProgress: avoid writing every keystroke to Firestore
  static DateTime? _lastProgressUpdate;
  static const Duration _progressThrottle = Duration(seconds: 1); // Reduced for better real-time sync

  /// Update player progress (throttled: max once per 3s except on finish)
  static Future<void> updateProgress({
    required String battleId,
    required int correctCells,
    required int totalCells,
    required int mistakes,
    List<List<int>>? currentGrid,
    bool forceWrite = false,
  }) async {
    if (!AuthService.isSignedIn) {
      debugPrint('[BattleService] updateProgress - not signed in');
      return;
    }

    final now = DateTime.now();
    if (!forceWrite &&
        _lastProgressUpdate != null &&
        now.difference(_lastProgressUpdate!) < _progressThrottle) {
      debugPrint('[BattleService] updateProgress - throttled');
      return; // Throttled – skip this write
    }
    _lastProgressUpdate = now;

    final oderId = AuthService.userId!;
    final progress =
        totalCells > 0 ? ((correctCells / totalCells) * 100).round() : 0;

    debugPrint('[BattleService] updateProgress - progress: $progress, mistakes: $mistakes, forceWrite: $forceWrite');

    try {
      // Determine which player we are
      final battle = await getBattle(battleId);
      if (battle == null) {
        debugPrint('[BattleService] updateProgress - battle not found');
        return;
      }

      String playerField;
      if (battle.player1?.oderId == oderId) {
        playerField = 'player1';
      } else if (battle.player2?.oderId == oderId) {
        playerField = 'player2';
      } else {
        debugPrint('[BattleService] updateProgress - user not in battle');
        return; // Not in this battle
      }

      debugPrint('[BattleService] updateProgress - writing to $playerField');
      await _battles.doc(battleId).update({
        '$playerField.progress': progress,
        '$playerField.correctCells': correctCells,
        '$playerField.mistakes': mistakes,
        if (currentGrid != null) '$playerField.currentGrid': currentGrid,
      });
      debugPrint('[BattleService] updateProgress - SUCCESS');
    } catch (e) {
      debugPrint('[BattleService] updateProgress ERROR: $e');
    }
  }

  /// Finish battle for current player
  static Future<void> finishBattle(String battleId) async {
    if (!AuthService.isSignedIn) return;

    final oderId = AuthService.userId!;
    _lastProgressUpdate = null; // Force next progress write on next battle

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

    // Calculate ELO change (2x multiplier for online duels vs AI)
    final gamesPlayed = LocalDuelStatsService.totalGames;
    final newElo = EloCalculator.calculateNewElo(
      playerElo: myPlayer.elo,
      opponentElo: opponentPlayer.elo,
      won: won,
      gamesPlayed: gamesPlayed,
      multiplier: 2.0,
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

  /// Update current user's stats based on final battle result.
  /// Use when the battle ended due to the opponent's action (stream notification).
  static Future<void> updateMyBattleStats(String battleId) async {
    try {
      final battle = await getBattle(battleId);
      if (battle == null || battle.winnerId == null) return;
      await _updatePlayerStats(battle, battle.winnerId!);
    } catch (e) {
      debugPrint('updateMyBattleStats error: $e');
    }
  }

  /// Resign from battle
  static Future<void> resignBattle(String battleId) async {
    debugPrint('[BattleService] resignBattle called for: $battleId');
    if (!AuthService.isSignedIn) {
      debugPrint('[BattleService] resignBattle - not signed in');
      return;
    }

    final oderId = AuthService.userId!;

    try {
      final battle = await getBattle(battleId);
      if (battle == null) {
        debugPrint('[BattleService] resignBattle - battle not found');
        return;
      }

      // Opponent wins
      final winnerId = battle.player1?.oderId == oderId
          ? battle.player2?.oderId
          : battle.player1?.oderId;

      debugPrint('[BattleService] resignBattle - setting winnerId: $winnerId, status: finished');
      await _battles.doc(battleId).update({
        'status': BattleStatus.finished.name,
        'winnerId': winnerId,
        'finishedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[BattleService] resignBattle - Firestore update SUCCESS');

      // Update player stats (ELO decrease for resigning player)
      if (winnerId != null) {
        await _updatePlayerStats(battle, winnerId);
      }

      debugPrint('[BattleService] Resigned from battle: $battleId, winner: $winnerId');
    } catch (e) {
      debugPrint('[BattleService] resignBattle ERROR: $e');
    }
  }

  /// Clean up all resources
  static void dispose() {
    _matchmakingSubscription?.cancel();
    _battleSubscription?.cancel();
    _connectionSubscription?.cancel();
    _matchmakingTimer?.cancel();
    _matchmakingHeartbeatTimer?.cancel();
    _battleTimer?.cancel();
    _reconnectTimer?.cancel();

    _matchmakingSubscription = null;
    _battleSubscription = null;
    _connectionSubscription = null;
    _matchmakingTimer = null;
    _matchmakingHeartbeatTimer = null;
    _battleTimer = null;
    _reconnectTimer = null;

    _currentBattleId = null;
    _currentBattle = null;
    _reconnectAttempts = 0;
    _lastProgressUpdate = null;

    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
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
      'avatar': 'assets/bots/easy_bot.png',
      'minInterval': 8, // seconds
      'maxInterval': 11,
      'eloOffset': -100,
      'eloWin': 15, // ELO gained on win
      'eloLoss': 25, // ELO lost on loss
    },
    'medium': {
      'name': 'Pro Bot 🤖',
      'avatar': 'assets/bots/pro_bot.png',
      'minInterval': 6,
      'maxInterval': 9,
      'eloOffset': 0,
      'eloWin': 25,
      'eloLoss': 20,
    },
    'hard': {
      'name': 'Master Bot 🤖',
      'avatar': 'assets/bots/master_bot.png',
      'minInterval': 6,
      'maxInterval': 9,
      'eloOffset': 100,
      'eloWin': 40,
      'eloLoss': 15,
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
        equippedFrame: LevelService.selectedFrameId,
        elo: playerElo,
        rank: LocalDuelStatsService.getRankDisplay(playerElo),
        countryCode: AuthService.getCountryCode(),
      );

      // Create bot opponent with difficulty-based ELO
      final botElo = playerElo + (aiConfig['eloOffset'] as int);
      final player2 = BattlePlayer(
        oderId: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        displayName: aiConfig['name'] as String,
        photoUrl: null,
        elo: botElo.clamp(100, 2000),
        rank: LocalDuelStatsService.getRankDisplay(botElo.clamp(100, 2000)),
        avatarAsset: aiConfig['avatar'] as String?,
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

  static final math.Random _random = math.Random();

  /// Get bot move interval based on AI difficulty (returns random seconds in range)
  static int getBotMoveInterval() {
    final aiConfig =
        aiDifficulties[_currentAiDifficulty] ?? aiDifficulties['medium']!;
    final minInterval = aiConfig['minInterval'] as int;
    final maxInterval = aiConfig['maxInterval'] as int;
    return minInterval + _random.nextInt(maxInterval - minInterval + 1);
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
