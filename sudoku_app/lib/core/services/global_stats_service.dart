import '../models/global_stats.dart';

/// Service for fetching global statistics
///
/// This service is designed to be easily connected to a backend service
/// like Firebase Firestore, REST API, etc.
///
/// Currently returns placeholder data until a backend is implemented.
class GlobalStatsService {
  static GlobalStatsService? _instance;
  static GlobalStatsService get instance =>
      _instance ??= GlobalStatsService._();

  GlobalStatsService._();

  // Cache for month stats
  final Map<String, GlobalMonthStats> _monthStatsCache = {};

  // Cache for daily stats
  final Map<String, GlobalDailyStats> _dailyStatsCache = {};

  /// Initialize the service
  Future<void> init() async {
    // Backend connection will be initialized here when implemented
    // (Firebase, REST API, etc.)
  }

  /// Get global stats for a specific date
  Future<GlobalDailyStats> getDailyStats(DateTime date) async {
    final key = _dateKey(date);

    // Check cache first
    if (_dailyStatsCache.containsKey(key)) {
      return _dailyStatsCache[key]!;
    }

    // [Backend Integration Point] Fetch from backend
    // For now, return placeholder data
    // In production, this would be:
    // final doc = await FirebaseFirestore.instance
    //     .collection('daily_stats')
    //     .doc(key)
    //     .get();
    // return GlobalDailyStats.fromJson(doc.data()!);

    final stats = _generatePlaceholderStats(date);
    _dailyStatsCache[key] = stats;
    return stats;
  }

  /// Get global stats for a specific month
  Future<GlobalMonthStats> getMonthStats(int year, int month) async {
    final key = '$year-${month.toString().padLeft(2, '0')}';

    // Check cache first
    if (_monthStatsCache.containsKey(key)) {
      return _monthStatsCache[key]!;
    }

    // [Backend Integration Point] Fetch from backend
    // For now, generate placeholder data

    final stats = await _generatePlaceholderMonthStats(year, month);
    _monthStatsCache[key] = stats;
    return stats;
  }

  /// Get count of players who completed a specific date
  Future<int> getPlayersCompletedCount(DateTime date) async {
    final stats = await getDailyStats(date);
    return stats.playersCompleted;
  }

  /// Get count of players who completed full month
  Future<int> getFullMonthCompletersCount(int year, int month) async {
    final stats = await getMonthStats(year, month);
    return stats.fullMonthCompleters;
  }

  /// Report a completion to the backend
  /// This should be called after a player completes a daily challenge
  Future<void> reportCompletion({
    required DateTime date,
    required int completionTimeSeconds,
    required int mistakes,
    required int score,
  }) async {
    // [Backend Integration Point] Send to backend
    // In production, this would update the global stats:
    // await FirebaseFirestore.instance
    //     .collection('daily_stats')
    //     .doc(_dateKey(date))
    //     .update({
    //       'playersCompleted': FieldValue.increment(1),
    //       'totalAttempts': FieldValue.increment(1),
    //       // ... update averages
    //     });

    // For now, just update local cache for demo purposes
    final key = _dateKey(date);
    final currentStats =
        _dailyStatsCache[key] ?? _generatePlaceholderStats(date);

    final newCount = currentStats.playersCompleted + 1;
    final newTotalAttempts = currentStats.totalAttempts + 1;

    // Recalculate averages (simplified)
    final oldTotal =
        currentStats.avgCompletionTimeSeconds * currentStats.playersCompleted;
    final newAvgTime = (oldTotal + completionTimeSeconds) ~/ newCount;

    _dailyStatsCache[key] = currentStats.copyWith(
      playersCompleted: newCount,
      totalAttempts: newTotalAttempts,
      avgCompletionTimeSeconds: newAvgTime,
      lastUpdated: DateTime.now(),
    );

    // Invalidate month cache
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    _monthStatsCache.remove(monthKey);
  }

  /// Clear all caches
  void clearCache() {
    _monthStatsCache.clear();
    _dailyStatsCache.clear();
  }

  /// Generate placeholder stats for a date
  /// This simulates what real data might look like
  GlobalDailyStats _generatePlaceholderStats(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    // Future dates have no completions
    if (checkDate.isAfter(today)) {
      return const GlobalDailyStats();
    }

    // Generate consistent "random" number based on date
    // This ensures same date always shows same number
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final pseudoRandom = (seed * 9301 + 49297) % 233280;
    final normalizedRandom = pseudoRandom / 233280.0;

    // Days further in the past generally have more completions
    final daysSinceDate = today.difference(checkDate).inDays;
    final baseCompletions = 100 + (daysSinceDate * 50).clamp(0, 10000);
    final variance = (normalizedRandom * 2000).toInt();

    // Weekends might have more players
    final isWeekend = checkDate.weekday == DateTime.saturday ||
        checkDate.weekday == DateTime.sunday;
    final weekendBonus = isWeekend ? 500 : 0;

    final playersCompleted = baseCompletions + variance + weekendBonus;

    return GlobalDailyStats(
      playersCompleted: playersCompleted,
      avgCompletionTimeSeconds: 180 + (normalizedRandom * 300).toInt(),
      avgMistakes: normalizedRandom * 3,
      totalAttempts: (playersCompleted * 1.3).toInt(),
      successRate: 0.7 + (normalizedRandom * 0.25),
      lastUpdated: now,
    );
  }

  /// Generate placeholder month stats
  Future<GlobalMonthStats> _generatePlaceholderMonthStats(
      int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dailyStats = <int, GlobalDailyStats>{};

    int totalCompletions = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final stats = await getDailyStats(date);
      dailyStats[day] = stats;
      totalCompletions += stats.playersCompleted;
    }

    // Estimate unique players (roughly 60% of daily average are unique monthly)
    final avgDailyCompletions = totalCompletions / daysInMonth;
    final totalPlayers = (avgDailyCompletions * 3).toInt();

    // Full month completers are much rarer (roughly 5-10% of total players)
    final fullMonthCompleters = (totalPlayers * 0.07).toInt();

    return GlobalMonthStats(
      year: year,
      month: month,
      totalPlayers: totalPlayers,
      fullMonthCompleters: fullMonthCompleters,
      avgCompletionRate:
          0.4 + (totalCompletions / totalPlayers / daysInMonth * 0.5),
      dailyStats: dailyStats,
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
