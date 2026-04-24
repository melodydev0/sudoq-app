import 'package:sudoku_app/core/models/battle_models.dart';

/// Defines the contract for battle/duel data operations.
///
/// Screens should access battle data only through this interface,
/// keeping Firebase dependencies isolated in the data layer.
abstract class BattleRepository {
  /// Join the matchmaking queue and wait for a match.
  ///
  /// Calls [onMatchFound] when a [BattleRoom] is ready, or [onError] on failure.
  Future<void> joinMatchmaking({
    required void Function(BattleRoom battle) onMatchFound,
    required void Function(String error) onError,
  });

  /// Cancel/leave the matchmaking queue.
  Future<void> leaveMatchmaking();

  /// Create a test battle against an AI bot of [difficulty].
  Future<BattleRoom> createAiBattle(String difficulty);

  /// Subscribe to real-time updates for a battle room by [battleId].
  Stream<BattleRoom?> watchBattle(String battleId);

  /// Update the current player's progress in a battle.
  Future<void> updateProgress({
    required String battleId,
    required String userId,
    required int progress,
    required int mistakes,
  });

  /// Mark a battle as finished with an optional [result].
  Future<void> finishBattle({
    required String battleId,
    required String userId,
    String? result,
  });
}
