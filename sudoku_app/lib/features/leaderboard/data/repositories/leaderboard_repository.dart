import 'package:sudoku_app/core/models/leaderboard_user.dart';

/// Defines the contract for leaderboard data operations.
///
/// Abstracts Firestore calls so leaderboard screens have no direct
/// dependency on the cloud backend.
abstract class LeaderboardRepository {
  /// Fetch the global leaderboard, ordered by [field] (e.g. 'score', 'elo').
  /// Returns at most [limit] entries.
  Future<List<LeaderboardUser>> getGlobalLeaderboard({
    String field = 'score',
    int limit = 100,
  });

  /// Fetch the weekly leaderboard.
  Future<List<LeaderboardUser>> getWeeklyLeaderboard({int limit = 100});

  /// Fetch a single user's public profile by [userId].
  Future<LeaderboardUser?> getUserProfile(String userId);

  /// Subscribe to real-time leaderboard updates.
  Stream<List<LeaderboardUser>> watchGlobalLeaderboard({
    String field = 'score',
    int limit = 100,
  });
}
