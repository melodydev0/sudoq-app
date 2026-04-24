import 'package:sudoku_app/core/models/game_state.dart';
import 'package:sudoku_app/core/services/storage_service.dart';
import 'game_repository.dart';

/// Concrete implementation of [GameRepository] backed by [StorageService].
///
/// [StorageService] maintains a single "current game" slot.
/// The [difficulty] parameter is used to verify the saved game matches
/// the requested difficulty before returning it.
class GameRepositoryImpl implements GameRepository {
  const GameRepositoryImpl();

  @override
  Future<GameState?> loadSavedGame(String difficulty) async {
    final game = StorageService.getCurrentGame();
    if (game == null || game.difficulty != difficulty) return null;
    return game;
  }

  @override
  Future<void> saveGame(String difficulty, GameState gameState) async {
    await StorageService.saveCurrentGame(gameState);
  }

  @override
  Future<void> deleteSavedGame(String difficulty) async {
    await StorageService.clearCurrentGame();
  }

  @override
  Future<bool> hasSavedGame(String difficulty) async {
    final game = StorageService.getCurrentGame();
    return game != null && game.difficulty == difficulty;
  }

  @override
  Future<int> getSavedElapsedSeconds(String difficulty) async {
    final game = StorageService.getCurrentGame();
    if (game == null || game.difficulty != difficulty) return 0;
    return game.elapsedTime.inSeconds;
  }

  @override
  Future<void> saveElapsedSeconds(String difficulty, int seconds) async {
    final game = StorageService.getCurrentGame();
    if (game == null || game.difficulty != difficulty) return;
    final updated = game.copyWith(elapsedTime: Duration(seconds: seconds));
    await StorageService.saveCurrentGame(updated);
  }
}
