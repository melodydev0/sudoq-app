import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for Duel statistics
/// Progress is saved locally and can be synced to cloud when user signs in
class LocalDuelStatsService {
  static const String _keyWins = 'duel_wins';
  static const String _keyLosses = 'duel_losses';
  static const String _keyElo = 'duel_elo';
  static const String _keyWinStreak = 'duel_win_streak';
  static const String _keyBestStreak = 'duel_best_streak';
  static const String _keyTotalGames = 'duel_total_games';
  static const String _keyLastSyncedAt = 'duel_last_synced';

  static SharedPreferences? _prefs;
  static Future<void>? _initFuture; // Re-entrant guard: single init for concurrent callers

  // Pending ELO change for animation (in-memory only)
  static int? _pendingEloChange;
  static bool? _pendingIsWin;
  static String? _pendingRankUp; // New rank if promoted
  static String? _pendingRankUpFrom; // Previous rank (for celebration)

  static Future<void> init() async {
    if (_prefs != null) return;
    _initFuture ??= SharedPreferences.getInstance().then((p) {
      _prefs = p;
    });
    await _initFuture;
  }

  // Getters
  static int get wins => _prefs?.getInt(_keyWins) ?? 0;
  static int get losses => _prefs?.getInt(_keyLosses) ?? 0;
  static int get elo =>
      _prefs?.getInt(_keyElo) ?? 450; // Start at 450 ELO (Bronze)
  static int get winStreak => _prefs?.getInt(_keyWinStreak) ?? 0;
  static int get bestStreak => _prefs?.getInt(_keyBestStreak) ?? 0;
  static int get totalGames => _prefs?.getInt(_keyTotalGames) ?? 0;
  static String? get lastSyncedAt => _prefs?.getString(_keyLastSyncedAt);

  static double get winRate {
    final total = wins + losses;
    if (total == 0) return 0.0;
    return (wins / total) * 100;
  }

  static String get rank => _getRankFromElo(elo);

  // Division thresholds (ELO-based, like Ranked system)
  static const Map<String, int> divisionThresholds = {
    'Bronze': 0,
    'Silver': 500,
    'Gold': 800,
    'Platinum': 1100,
    'Diamond': 1400,
    'Master': 1700,
    'Grandmaster': 2000,
    'Champion': 2300,
  };

  static String _getRankFromElo(int elo) {
    if (elo < 500) return 'Bronze';
    if (elo < 800) return 'Silver';
    if (elo < 1100) return 'Gold';
    if (elo < 1400) return 'Platinum';
    if (elo < 1700) return 'Diamond';
    if (elo < 2000) return 'Master';
    if (elo < 2300) return 'Grandmaster';
    return 'Champion';
  }

  static String getRankEmoji(String rank) {
    switch (rank) {
      case 'Bronze':
        return '🥉';
      case 'Silver':
        return '🥈';
      case 'Gold':
        return '🥇';
      case 'Platinum':
        return '💎';
      case 'Diamond':
        return '💠';
      case 'Master':
        return '🏆';
      case 'Grandmaster':
        return '👑';
      case 'Champion':
        return '🔥';
      default:
        return '🎮';
    }
  }

  static String? getRankImagePath(String rank) {
    final key = rank.toLowerCase();
    return 'assets/divisions/$key.png';
  }

  // Get division color
  static int getDivisionColorValue(String rank) {
    switch (rank) {
      case 'Bronze':
        return 0xFFCD7F32;
      case 'Silver':
        return 0xFFC0C0C0;
      case 'Gold':
        return 0xFFFF8C00;
      case 'Platinum':
        return 0xFF00BFFF;
      case 'Diamond':
        return 0xFF1E90FF;
      case 'Master':
        return 0xFFFFA500;
      case 'Grandmaster':
        return 0xFF9400D3;
      case 'Champion':
        return 0xFFFF4500;
      default:
        return 0xFF808080;
    }
  }

  // Get min ELO for next division
  static int getNextDivisionMinElo(int currentElo) {
    if (currentElo < 500) return 500;
    if (currentElo < 800) return 800;
    if (currentElo < 1100) return 1100;
    if (currentElo < 1400) return 1400;
    if (currentElo < 1700) return 1700;
    if (currentElo < 2000) return 2000;
    if (currentElo < 2300) return 2300;
    return 2300; // Already at Champion
  }

  // Get progress to next division (0.0 to 1.0)
  static double getDivisionProgress(int currentElo) {
    final currentMin = divisionThresholds.entries
        .where((e) => currentElo >= e.value)
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final nextMin = getNextDivisionMinElo(currentElo);

    if (currentMin == nextMin) return 1.0; // Already at Champion

    return (currentElo - currentMin) / (nextMin - currentMin);
  }

  // Get ELO needed for next division
  static int getEloToNextDivision(int currentElo) {
    final nextMin = getNextDivisionMinElo(currentElo);
    if (currentElo >= 2300) return 0; // Already Champion
    return nextMin - currentElo;
  }

  static String getRankDisplay(int elo) {
    return '${getRankEmoji(_getRankFromElo(elo))} ${_getRankFromElo(elo)}';
  }

  // Record a win
  static Future<void> recordWin(int eloChange) async {
    await init();

    // Check for rank up before changing ELO
    final oldRank = rank;
    final newElo = elo + eloChange;
    final newRank = _getRankFromElo(newElo);

    await _prefs?.setInt(_keyWins, wins + 1);
    await _prefs?.setInt(_keyTotalGames, totalGames + 1);
    await _prefs?.setInt(_keyElo, newElo);

    final newStreak = winStreak + 1;
    await _prefs?.setInt(_keyWinStreak, newStreak);

    if (newStreak > bestStreak) {
      await _prefs?.setInt(_keyBestStreak, newStreak);
    }

    // Store for animation
    _pendingEloChange = eloChange;
    _pendingIsWin = true;

    // Check if ranked up
    if (newRank != oldRank) {
      _pendingRankUp = newRank;
      _pendingRankUpFrom = oldRank;
    } else {
      _pendingRankUp = null;
      _pendingRankUpFrom = null;
    }
  }

  // Record a loss
  static Future<void> recordLoss(int eloChange) async {
    await init();

    final newElo = (elo - eloChange).clamp(0, 9999);

    await _prefs?.setInt(_keyLosses, losses + 1);
    await _prefs?.setInt(_keyTotalGames, totalGames + 1);
    await _prefs?.setInt(_keyElo, newElo);
    await _prefs?.setInt(_keyWinStreak, 0); // Reset streak

    // Store for animation
    _pendingEloChange = eloChange;
    _pendingIsWin = false;
    _pendingRankUp = null; // No rank up on loss
    _pendingRankUpFrom = null;
  }

  /// Get rank name from ELO (for UI)
  static String getRankFromElo(int elo) => _getRankFromElo(elo);

  // Get pending ELO change for animation
  static int? get pendingEloChange => _pendingEloChange;
  static bool? get pendingIsWin => _pendingIsWin;
  static String? get pendingRankUp => _pendingRankUp;
  static String? get pendingRankUpFrom => _pendingRankUpFrom;

  // Clear pending ELO change after showing animation
  static void clearPendingEloChange() {
    _pendingEloChange = null;
    _pendingIsWin = null;
    _pendingRankUp = null;
    _pendingRankUpFrom = null;
  }

  // Get all stats as a map
  static Map<String, dynamic> getAllStats() {
    return {
      'wins': wins,
      'losses': losses,
      'elo': elo,
      'winStreak': winStreak,
      'bestStreak': bestStreak,
      'totalGames': totalGames,
      'winRate': winRate,
      'rank': rank,
    };
  }

  // Import stats from cloud (when user signs in)
  static Future<void> importFromCloud(Map<String, dynamic> cloudStats) async {
    await init();

    // Merge: take the higher values
    final cloudWins = cloudStats['wins'] ?? 0;
    final cloudLosses = cloudStats['losses'] ?? 0;
    final cloudElo = cloudStats['elo'] ?? 450;
    final cloudStreak = cloudStats['winStreak'] ?? 0;
    final cloudBestStreak = cloudStats['bestStreak'] ?? 0;

    // If cloud has more games, use cloud data
    final cloudTotal = cloudWins + cloudLosses;
    final localTotal = wins + losses;

    if (cloudTotal > localTotal) {
      await _prefs?.setInt(_keyWins, cloudWins);
      await _prefs?.setInt(_keyLosses, cloudLosses);
      await _prefs?.setInt(_keyElo, cloudElo);
      await _prefs?.setInt(_keyWinStreak, cloudStreak);
      await _prefs?.setInt(_keyBestStreak, cloudBestStreak);
      await _prefs?.setInt(_keyTotalGames, cloudTotal);
    } else if (cloudTotal == localTotal && cloudElo > elo) {
      // Same games but cloud has higher ELO, use cloud
      await _prefs?.setInt(_keyElo, cloudElo);
    }

    await _prefs?.setString(_keyLastSyncedAt, DateTime.now().toIso8601String());
  }

  // Export stats for cloud sync
  static Map<String, dynamic> exportForCloud() {
    return {
      'wins': wins,
      'losses': losses,
      'elo': elo,
      'winStreak': winStreak,
      'bestStreak': bestStreak,
      'totalGames': totalGames,
      'rank': rank,
    };
  }

  // Mark as synced
  static Future<void> markSynced() async {
    await init();
    await _prefs?.setString(_keyLastSyncedAt, DateTime.now().toIso8601String());
  }

  // Check if needs sync (has unsynced local progress)
  static bool get needsSync {
    if (totalGames == 0) return false;
    return lastSyncedAt == null;
  }

  // Reset all stats (for testing)
  static Future<void> resetAll() async {
    await init();
    await _prefs?.remove(_keyWins);
    await _prefs?.remove(_keyLosses);
    await _prefs?.remove(_keyElo);
    await _prefs?.remove(_keyWinStreak);
    await _prefs?.remove(_keyBestStreak);
    await _prefs?.remove(_keyTotalGames);
    await _prefs?.remove(_keyLastSyncedAt);
  }

  // Debug method to set specific stats for testing
  static Future<void> setDebugStats({
    required int wins,
    required int losses,
    required int elo,
    required int bestStreak,
    required int currentStreak,
  }) async {
    await init();
    await _prefs?.setInt(_keyWins, wins);
    await _prefs?.setInt(_keyLosses, losses);
    await _prefs?.setInt(_keyElo, elo);
    await _prefs?.setInt(_keyBestStreak, bestStreak);
    await _prefs?.setInt(_keyWinStreak, currentStreak);
    await _prefs?.setInt(_keyTotalGames, wins + losses);
  }
}
