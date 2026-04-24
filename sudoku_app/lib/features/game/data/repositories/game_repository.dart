import 'package:sudoku_app/core/models/game_state.dart';

/// Defines the contract for game data persistence and retrieval.
///
/// All game state reads/writes should go through this interface rather than
/// directly calling [StorageService] from UI layers.
abstract class GameRepository {
  /// Load a saved game for the given [difficulty].
  /// Returns `null` if no saved game exists.
  Future<GameState?> loadSavedGame(String difficulty);

  /// Save the current [gameState] for the given [difficulty].
  Future<void> saveGame(String difficulty, GameState gameState);

  /// Delete the saved game for the given [difficulty].
  Future<void> deleteSavedGame(String difficulty);

  /// Check whether a saved game exists for [difficulty].
  Future<bool> hasSavedGame(String difficulty);

  /// Returns the elapsed time in seconds for a saved game, if any.
  Future<int> getSavedElapsedSeconds(String difficulty);

  /// Save the elapsed time for a game in progress.
  Future<void> saveElapsedSeconds(String difficulty, int seconds);
}
