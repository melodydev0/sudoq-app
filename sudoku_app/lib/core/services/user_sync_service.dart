import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_service.dart';
import 'storage_service.dart';
import 'achievement_service.dart';
import 'local_duel_stats_service.dart';
import 'daily_challenge_service.dart';
import '../models/statistics.dart';

/// Service for syncing local data with Firestore
/// Local-first approach: data is always saved locally, then synced to cloud
class UserSyncService {
  static FirebaseFirestore? _firestoreInstance;
  static FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  static FirebaseAuth? _authInstance;
  static FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

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
          'daily': _exportDailyData(),
        },
        'settings': _exportSettings(),
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
      debugPrint('Sync to cloud failed: $e');
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
      debugPrint('Sync from cloud failed: $e');
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

        // Import game statistics
        if (stats['statistics'] != null) {
          await _importStatistics(stats['statistics'] as Map<String, dynamic>);
        }

        // Import daily challenge data
        if (stats['daily'] != null) {
          await _importDailyData(stats['daily'] as Map<String, dynamic>);
        }
      }

      // Import settings (full)
      if (data['settings'] != null) {
        await _importSettings(data['settings'] as Map<String, dynamic>);
      }

      // Update local sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Import from cloud failed: $e');
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
        'selectedFrame': LevelService.selectedFrameId,
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
        'selectedFrame': LevelService.selectedFrameId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update leaderboard failed: $e');
    }
  }

  /// Update display name in all leaderboards
  static Future<void> updateDisplayName(String displayName) async {
    if (!isLoggedIn) return;
    
    final uid = currentUserId!;
    
    try {
      // Update level leaderboard
      await _firestore.collection('leaderboard').doc(uid).set({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update duel leaderboard
      await _firestore.collection('duel_leaderboard').doc(uid).set({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update display name failed: $e');
    }
  }

  /// Update country code in all leaderboards
  static Future<void> updateCountryCode(String countryCode) async {
    if (!isLoggedIn) return;
    
    final uid = currentUserId!;
    
    try {
      // Update level leaderboard
      await _firestore.collection('leaderboard').doc(uid).set({
        'countryCode': countryCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update duel leaderboard
      await _firestore.collection('duel_leaderboard').doc(uid).set({
        'countryCode': countryCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update country code failed: $e');
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
      debugPrint('Get leaderboard failed: $e');
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
      debugPrint('Get user rank failed: $e');
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

  static Map<String, dynamic> _exportDailyData() {
    final data = DailyChallengeService.data;
    return {
      'currentStreak': data.currentStreak,
      'bestStreak': data.bestStreak,
      'totalDaysCompleted': data.totalDaysCompleted,
      'earnedBadgesCount': data.earnedBadges.where((b) => b.isComplete).length,
      // Full data stored as json string for cross-device restore
      'fullData': jsonEncode(data.toJson()),
    };
  }

  static Map<String, dynamic> _exportSettings() {
    final settings = StorageService.getSettings();
    return {
      ...settings.toJson(),
      'soundEnabled': StorageService.getSoundEnabled(),
      'pushNotificationsEnabled': StorageService.getPushNotificationsEnabled(),
    };
  }

  // ==================== IMPORT HELPERS ====================

  static Future<void> _importLevelData(Map<String, dynamic> data) async {
    final payload = <String, dynamic>{
      'levelData': {
        'totalXp': data['totalXp'] ?? 0,
        'seasonXp': data['seasonXp'] ?? 0,
        'seasonNumber': data['seasonNumber'] ?? 1,
        'streakDays': data['streakDays'] ?? 0,
        'unlockedRewards': data['unlockedRewards'] ?? <dynamic>[],
      },
      'selectedTheme': data['selectedTheme'] ?? 'theme_default',
      'selectedFrame': data['selectedFrame'] ?? 'frame_basic',
      'selectedEffect': data['selectedEffect'] ?? 'effect_sparkle',
    };
    await LevelService.importData(jsonEncode(payload));
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

  static Future<void> _importStatistics(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) return;
      final current = StorageService.getStatistics();
      final cloudWins = data['totalGamesWon'] as int? ?? 0;
      if (cloudWins > current.totalGamesWon) {
        // Cloud has more wins — import cloud statistics
        final imported = Statistics.fromJson(data);
        await StorageService.saveStatistics(imported);
      }
    } catch (e) {
      debugPrint('Import statistics failed: $e');
    }
  }

  static Future<void> _importDailyData(Map<String, dynamic> data) async {
    try {
      final fullDataJson = data['fullData'] as String?;
      if (fullDataJson == null || fullDataJson.isEmpty) return;
      final parsed = jsonDecode(fullDataJson) as Map<String, dynamic>;
      final cloudTotal = parsed['totalDaysCompleted'] as int? ?? 0;
      final localTotal = DailyChallengeService.totalDaysCompleted;
      if (cloudTotal > localTotal) {
        await DailyChallengeService.importFromJson(parsed);
      }
    } catch (e) {
      debugPrint('Import daily data failed: $e');
    }
  }

  static Future<void> _importSettings(Map<String, dynamic> data) async {
    try {
      if (data['soundEnabled'] != null) {
        await StorageService.setSoundEnabled(data['soundEnabled'] as bool);
      }
      if (data['pushNotificationsEnabled'] != null) {
        await StorageService.setPushNotificationsEnabled(
            data['pushNotificationsEnabled'] as bool);
      }
      // Import full AppSettings (language, autoRemoveNotes, vibration, etc.)
      final settingsFields = {
        'isDarkMode', 'soundEnabled', 'vibrationEnabled', 'autoRemoveNotes',
        'highlightSameNumbers', 'highlightRowColumn', 'showMistakes',
        'showTimer', 'showRemainingNumbers', 'defaultDifficulty', 'languageCode',
      };
      final hasAnyField = settingsFields.any((k) => data.containsKey(k));
      if (hasAnyField) {
        final currentSettings = StorageService.getSettings();
        final merged = currentSettings.copyWith(
          isDarkMode: data['isDarkMode'] as bool? ?? currentSettings.isDarkMode,
          soundEnabled: data['soundEnabled'] as bool? ?? currentSettings.soundEnabled,
          vibrationEnabled: data['vibrationEnabled'] as bool? ?? currentSettings.vibrationEnabled,
          autoRemoveNotes: data['autoRemoveNotes'] as bool? ?? currentSettings.autoRemoveNotes,
          highlightSameNumbers: data['highlightSameNumbers'] as bool? ?? currentSettings.highlightSameNumbers,
          highlightRowColumn: data['highlightRowColumn'] as bool? ?? currentSettings.highlightRowColumn,
          showMistakes: data['showMistakes'] as bool? ?? currentSettings.showMistakes,
          showTimer: data['showTimer'] as bool? ?? currentSettings.showTimer,
          showRemainingNumbers: data['showRemainingNumbers'] as bool? ?? currentSettings.showRemainingNumbers,
          defaultDifficulty: data['defaultDifficulty'] as String? ?? currentSettings.defaultDifficulty,
          languageCode: data['languageCode'] as String? ?? currentSettings.languageCode,
        );
        await StorageService.saveSettings(merged);
      }
    } catch (e) {
      debugPrint('Import settings failed: $e');
    }
  }

  // ==================== USER PROFILE ====================

  /// Export a snapshot of ALL local data for cross-device merge
  /// (called before switching from anonymous to an existing account)
  static Map<String, dynamic> exportLocalForMerge() {
    return {
      'level': _exportLevelData(),
      'achievements': _exportAchievementData(),
      'duel': LocalDuelStatsService.exportForCloud(),
      'statistics': _exportStatistics(),
      'daily': _exportDailyData(),
    };
  }

  /// Merge anonymous local snapshot into the current (Google/Apple) cloud account.
  /// Always keeps the HIGHER value for numeric progress fields.
  static Future<void> mergeLocalIntoCloud(
      Map<String, dynamic> localSnapshot) async {
    if (!isLoggedIn || isAnonymous) return;

    try {
      final uid = currentUserId!;
      final userRef = _firestore.collection('users').doc(uid);
      final cloudDoc = await userRef.get();
      final cloudData = cloudDoc.data() ?? {};
      final cloudStats = cloudData['stats'] as Map<String, dynamic>? ?? {};

      // --- Level: keep higher totalXp ---
      final localLevel = localSnapshot['level'] as Map<String, dynamic>? ?? {};
      final cloudLevel = cloudStats['level'] as Map<String, dynamic>? ?? {};
      final localXp = localLevel['totalXp'] as int? ?? 0;
      final cloudXp = cloudLevel['totalXp'] as int? ?? 0;
      final mergedLevel = localXp > cloudXp ? localLevel : cloudLevel;

      // Merge unlockedRewards (union of both)
      final localRewards = Set<String>.from(
          (localLevel['unlockedRewards'] as List<dynamic>? ?? []).map((e) => e.toString()));
      final cloudRewards = Set<String>.from(
          (cloudLevel['unlockedRewards'] as List<dynamic>? ?? []).map((e) => e.toString()));
      mergedLevel['unlockedRewards'] = localRewards.union(cloudRewards).toList();

      // --- Duel: keep higher wins+losses total (more games played) ---
      final localDuel = localSnapshot['duel'] as Map<String, dynamic>? ?? {};
      final cloudDuel = cloudStats['duel'] as Map<String, dynamic>? ?? {};
      final localGames = (localDuel['wins'] as int? ?? 0) + (localDuel['losses'] as int? ?? 0);
      final cloudGames = (cloudDuel['wins'] as int? ?? 0) + (cloudDuel['losses'] as int? ?? 0);
      final mergedDuel = localGames > cloudGames ? localDuel : cloudDuel;
      // Always keep higher ELO
      final localElo = localDuel['elo'] as int? ?? 450;
      final cloudElo = cloudDuel['elo'] as int? ?? 450;
      mergedDuel['elo'] = localElo > cloudElo ? localElo : cloudElo;

      // --- Achievements: union ---
      final localAch = localSnapshot['achievements'] as Map<String, dynamic>? ?? {};
      final cloudAch = cloudStats['achievements'] as Map<String, dynamic>? ?? {};
      final localUnlocked = Set<String>.from(
          (localAch['unlockedAchievements'] as List<dynamic>? ?? []).map((e) => e.toString()));
      final cloudUnlocked = Set<String>.from(
          (cloudAch['unlockedAchievements'] as List<dynamic>? ?? []).map((e) => e.toString()));
      final mergedAch = {
        ...cloudAch,
        'unlockedAchievements': localUnlocked.union(cloudUnlocked).toList(),
      };

      // --- Statistics: keep higher totalGamesWon ---
      final localStats = localSnapshot['statistics'] as Map<String, dynamic>? ?? {};
      final cloudStatsMap = cloudStats['statistics'] as Map<String, dynamic>? ?? {};
      final localWins = localStats['totalGamesWon'] as int? ?? 0;
      final cloudWins = cloudStatsMap['totalGamesWon'] as int? ?? 0;
      final mergedStats = localWins > cloudWins ? localStats : cloudStatsMap;

      // --- Daily: keep higher totalDaysCompleted ---
      final localDaily = localSnapshot['daily'] as Map<String, dynamic>? ?? {};
      final cloudDaily = cloudStats['daily'] as Map<String, dynamic>? ?? {};
      final localDays = localDaily['totalDaysCompleted'] as int? ?? 0;
      final cloudDays = cloudDaily['totalDaysCompleted'] as int? ?? 0;
      final mergedDaily = localDays > cloudDays ? localDaily : cloudDaily;

      await userRef.set({
        'stats': {
          'level': mergedLevel,
          'achievements': mergedAch,
          'duel': mergedDuel,
          'statistics': mergedStats,
          'daily': mergedDaily,
        },
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Import merged data back to local
      await _importFromCloud({
        'stats': {
          'level': mergedLevel,
          'achievements': mergedAch,
          'duel': mergedDuel,
          'statistics': mergedStats,
          'daily': mergedDaily,
        },
      });

      await _updateLeaderboard(uid);
      debugPrint('Merged anonymous data into cloud account: $uid');
    } catch (e) {
      debugPrint('mergeLocalIntoCloud failed: $e');
    }
  }

  /// Create initial profile for new user
  static Future<void> createUserProfile() async {
    if (!isLoggedIn) return;

    final uid = currentUserId!;
    final user = _auth.currentUser!;

    await _firestore.collection('users').doc(uid).set({
      'profile': {
        'displayName': user.displayName ?? 'Player',
        'email': user.email,
        'photoUrl': user.photoURL,
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

    // Delete duel leaderboard entry
    await _firestore.collection('duel_leaderboard').doc(uid).delete();
  }
}
