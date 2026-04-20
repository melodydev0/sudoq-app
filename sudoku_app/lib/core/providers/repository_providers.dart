import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/data/repositories/game_repository.dart';
import '../../features/game/data/repositories/game_repository_impl.dart';

/// Provider for [GameRepository].
///
/// Screens that need to read/write game state should use this provider
/// instead of calling [StorageService] directly.
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return const GameRepositoryImpl();
});

// Note: BattleRepository and LeaderboardRepository concrete implementations
// wrap the existing BattleService / GlobalStatsService.
// They are provided as abstract interfaces so implementations can be swapped
// (e.g., for testing) without touching UI code.
