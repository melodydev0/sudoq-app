import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_service.dart';
import 'storage_service.dart';
import 'achievement_service.dart';
import 'local_duel_stats_service.dart';

/// Service for syncing local data with Firestore
/// Local-first approach: data is always saved locally, then synced to cloud
class UserSyncService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static const String _lastSyncKey = 'last_cloud_sync';
  static const String _pendingSyncKey = 'pending_cloud_sync';

  /// Get current user ID (null if not logged in)
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Check if user is anonymous
  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  // ==================== FIRESTORE STRUCTURE ====================
  // users/{uid}/
  //   - profile: { displayName, email, createdAt, lastSeen }
  //   - stats: { level, xp, ranked, achievements, duel }
  //   - settings: { theme, sound, etc }

  /// Sync all local data to Firestore
  static Future<bool> syncToCloud() async {
    if (!isLoggedIn || isAnonymous) return false;

    try {
      final uid = currentUserId!;
      final userRef = _firestore.collection('users').doc(uid);

      // Prepare all data (including market/entitlements for cross-device)
      final syncData = {
        'profile': {
          'displayName': _auth.currentUser?.displayName ?? 'Player',
          'email': _auth.currentUser?.email,
          'lastSeen': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'stats': {
          'level': _exportLevelData(),
          'achievements': _exportAchievementData(),
          'duel': LocalDuelStatsService.exportForCloud(),
          'statistics': _exportStatistics(),
        },
        'settings': _exportSettings(),
        'isAdsFree': StorageService.isAdsFree(),
        'syncedAt': FieldValue.serverTimestamp(),
      };

      // Use merge to not overwrite existing fields
      await userRef.set(syncData, SetOptions(merge: true));

      // Update last sync time locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      await prefs.setBool(_pendingSyncKey, false);

      // Update leaderboard entry
      await _updateLeaderboard(uid);

      return true;
    } catch (e) {
      print('Sync to cloud failed: $e');
      return false;
    }
  }

  /// Sync data from Firestore to local
  static Future<bool> syncFromCloud() async {
    if (!isLoggedIn || isAnonymous) return false;

    try {
      final uid = currentUserId!;
      final userRef = _firestore.collection('users').doc(uid);

      final doc = await userRef.get();
      if (!doc.exists) {
        // No cloud data, upload local data instead
        return await syncToCloud();
      }

      final data = doc.data()!;

      // Check which data is newer (local or cloud)
      final cloudSyncTime = (data['syncedAt'] as Timestamp?)?.toDate();
      final prefs = await SharedPreferences.getInstance();
      final localSyncStr = prefs.getString(_lastSyncKey);
      final localSyncTime =
          localSyncStr != null ? DateTime.parse(localSyncStr) : null;

      // If cloud is newer or local never synced, import from cloud
      if (cloudSyncTime != null &&
          (localSyncTime == null || cloudSyncTime.isAfter(localSyncTime))) {
        await _importFromCloud(data);
      } else {
        // Local is newer, sync to cloud
        await syncToCloud();
      }

      return true;
    } catch (e) {
      print('Sync from cloud failed: $e');
      return false;
    }
  }

  /// Import data from cloud to local storage
  static Future<void> _importFromCloud(Map<String, dynamic> data) async {
    try {
      final stats = data['stats'] as Map<String, dynamic>?;

      if (stats != null) {
        // Import level data
        if (stats['level'] != null) {
          await _importLevelData(stats['level'] as Map<String, dynamic>);
        }

        // Note: Ranked data removed - now using LocalDuelStatsService for duel stats

        // Import achievement data
        if (stats['achievements'] != null) {
          await _importAchievementData(
              stats['achievements'] as Map<String, dynamic>);
        }

        // Import duel stats
        if (stats['duel'] != null) {
          await LocalDuelStatsService.importFromCloud(
              stats['duel'] as Map<String, dynamic>);
        }
      }

      // Import settings
      if (data['settings'] != null) {
        await _importSettings(data['settings'] as Map<String, dynamic>);
      }

      // Import market/entitlements (premium status)
      if (data['isAdsFree'] != null) {
        await StorageService.setAdsFree(data['isAdsFree'] as bool);
      }

      // Update local sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Import from cloud failed: $e');
    }
  }

  /// Mark that local data needs to be synced
  static Future<void> markPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSyncKey, true);
  }

  /// Check if there's pending sync
  static Future<bool> hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingSyncKey) ?? false;
  }

  /// Auto-sync if logged in and has pending changes
  static Future<void> autoSync() async {
    if (!isLoggedIn || isAnonymous) return;

    final hasPending = await hasPendingSync();
    if (hasPending) {
      await syncToCloud();
    }
  }

  // ==================== LEADERBOARD ====================

  /// Update user's entry in both general leaderboard and duel leaderboard
  static Future<void> _updateLeaderboard(String uid) async {
    try {
      final levelData = LevelService.levelData;
      final duelStats = LocalDuelStatsService.getAllStats();
      final division = duelStats['rank'] as String? ?? 'Bronze';

      // Update general leaderboard (for level-based ranking)
      await _firestore.collection('leaderboard').doc(uid).set({
        'uid': uid,
        'displayName': _auth.currentUser?.displayName ?? 'Player',
        'photoUrl': _auth.currentUser?.photoURL,
        'level': levelData.level,
        'totalXp': levelData.totalXp,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update duel leaderboard (for ELO-based ranking)
      await _firestore.collection('duel_leaderboard').doc(uid).set({
        'oderId': uid,
        'displayName': _auth.currentUser?.displayName ?? 'Player',
        'photoUrl': _auth.currentUser?.photoURL,
        'elo': duelStats['elo'] ?? 450,
        'division': division,
        'wins': duelStats['wins'] ?? 0,
        'losses': duelStats['losses'] ?? 0,
        'winRate': duelStats['winRate'] ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Update leaderboard failed: $e');
    }
  }

  /// Get top players from leaderboard (level or duel)
  static Future<List<Map<String, dynamic>>> getTopPlayers({
    String orderBy = 'totalXp',
    int limit = 100,
    String? division, // Filter by division for duel leaderboard
  }) async {
    try {
      // Determine which collection to use
      final isDuelLeaderboard = orderBy == 'duelElo' || orderBy == 'elo';
      final collection = isDuelLeaderboard ? 'duel_leaderboard' : 'leaderboard';
      final actualOrderBy = isDuelLeaderboard ? 'elo' : orderBy;

      Query query = _firestore.collection(collection);

      // Add division filter if specified (for duel leaderboard)
      if (isDuelLeaderboard && division != null && division.isNotEmpty) {
        query = query.where('division', isEqualTo: division);
      }

      final snapshot = await query
          .orderBy(actualOrderBy, descending: true)
          .limit(limit)
          .get();

      final results = <Map<String, dynamic>>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        results.add({
          ...data,
          'rank': i + 1,
          // Normalize field names for compatibility
          if (isDuelLeaderboard) 'duelElo': data['elo'],
          if (isDuelLeaderboard) 'duelWins': data['wins'],
          if (isDuelLeaderboard) 'duelRank': data['division'],
        });
      }
      return results;
    } catch (e) {
      print('Get leaderboard failed: $e');
      return [];
    }
  }

  /// Get top players from duel leaderboard by division
  static Future<List<Map<String, dynamic>>> getDuelLeaderboard({
    String? division,
    int limit = 50,
  }) async {
    return getTopPlayers(
      orderBy: 'duelElo',
      limit: limit,
      division: division,
    );
  }

  /// Get user's rank in leaderboard
  static Future<int?> getUserRank({String orderBy = 'totalXp'}) async {
    if (!isLoggedIn) return null;

    try {
      final uid = currentUserId!;
      final isDuelLeaderboard = orderBy == 'duelElo' || orderBy == 'elo';
      final collection = isDuelLeaderboard ? 'duel_leaderboard' : 'leaderboard';
      final actualOrderBy = isDuelLeaderboard ? 'elo' : orderBy;

      final userDoc = await _firestore.collection(collection).doc(uid).get();

      if (!userDoc.exists) return null;

      final userValue = userDoc.data()?[actualOrderBy] ?? 0;

      // Count users with higher score
      final higherCount = await _firestore
          .collection(collection)
          .where(actualOrderBy, isGreaterThan: userValue)
          .count()
          .get();

      return (higherCount.count ?? 0) + 1;
    } catch (e) {
      print('Get user rank failed: $e');
      return null;
    }
  }

  /// Get user's duel rank
  static Future<int?> getDuelRank() async {
    return getUserRank(orderBy: 'duelElo');
  }

  // ==================== EXPORT HELPERS ====================

  static Map<String, dynamic> _exportLevelData() {
    final data = LevelService.levelData;
    return {
      'level': data.level,
      'totalXp': data.totalXp,
      'seasonXp': data.seasonXp,
      'seasonNumber': data.seasonNumber,
      'streakDays': data.streakDays,
      'unlockedRewards': data.unlockedRewards,
      'selectedTheme': LevelService.selectedThemeId,
      'selectedFrame': LevelService.selectedFrameId,
      'selectedEffect': LevelService.selectedEffectId,
    };
  }

  static Map<String, dynamic> _exportAchievementData() {
    return {
      'unlockedAchievements': AchievementService.unlockedAchievementIds,
      'progress': AchievementService.getAllProgress(),
    };
  }

  static Map<String, dynamic> _exportStatistics() {
    final stats = StorageService.getStatistics();
    return stats.toJson();
  }

  static Map<String, dynamic> _exportSettings() {
    final settings = StorageService.getSettings();
    return {
      ...settings.toJson(),
      'soundEnabled': StorageService.getSoundEnabled(),
    };
  }

  // ==================== IMPORT HELPERS ====================

  static Future<void> _importLevelData(Map<String, dynamic> data) async {
    // Use LevelService's import method
    final jsonStr = '''
    {
      "levelData": {
        "totalXp": ${data['totalXp'] ?? 0},
        "seasonXp": ${data['seasonXp'] ?? 0},
        "seasonNumber": ${data['seasonNumber'] ?? 1},
        "streakDays": ${data['streakDays'] ?? 0},
        "unlockedRewards": ${data['unlockedRewards'] ?? []}
      },
      "selectedTheme": "${data['selectedTheme'] ?? 'theme_default'}",
      "selectedFrame": "${data['selectedFrame'] ?? 'frame_basic'}",
      "selectedEffect": "${data['selectedEffect'] ?? 'effect_sparkle'}"
    }
    ''';
    await LevelService.importData(jsonStr);
  }

  static Future<void> _importAchievementData(Map<String, dynamic> data) async {
    // Import achievements
    final unlocked = data['unlockedAchievements'] as List<dynamic>?;
    if (unlocked != null) {
      for (final id in unlocked) {
        await AchievementService.unlockAchievement(id.toString());
      }
    }
  }

  static Future<void> _importSettings(Map<String, dynamic> data) async {
    if (data['soundEnabled'] != null) {
      await StorageService.setSoundEnabled(data['soundEnabled'] as bool);
    }
  }

  // ==================== USER PROFILE ====================

  /// Create initial profile for new user
  static Future<void> createUserProfile() async {
    if (!isLoggedIn) return;

    final uid = currentUserId!;
    final user = _auth.currentUser!;

    await _firestore.collection('users').doc(uid).set({
      'profile': {
        'displayName': user.displayName ?? 'Player',
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  /// Delete all user data (for account deletion)
  static Future<void> deleteUserData() async {
    if (!isLoggedIn) return;

    final uid = currentUserId!;

    // Delete user document
    await _firestore.collection('users').doc(uid).delete();

    // Delete leaderboard entry
    await _firestore.collection('leaderboard').doc(uid).delete();
  }
}
