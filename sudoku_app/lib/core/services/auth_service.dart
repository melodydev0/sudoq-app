import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_sync_service.dart';
import 'entitlement_service.dart';
import 'local_duel_stats_service.dart';
import 'storage_service.dart';

/// Authentication service for Firebase Auth with Google Sign-In
class AuthService {
  static FirebaseAuth? _authInstance;
  static GoogleSignIn? _googleSignInInstance;
  static FirebaseFirestore? _firestoreInstance;

  static FirebaseAuth get _auth {
    return _authInstance ??= FirebaseAuth.instance;
  }

  static GoogleSignIn get _googleSignIn {
    return _googleSignInInstance ??= GoogleSignIn();
  }

  static FirebaseFirestore get _firestore {
    return _firestoreInstance ??= FirebaseFirestore.instance;
  }
  static String? _lastSignInError;
  static String? get lastSignInError => _lastSignInError;

  /// Current user
  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  /// Check if user is anonymous
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// User ID
  static String? get oderId => currentUser?.uid;

  // Alias for compatibility
  static String? get userId => oderId;

  /// Display name - prioritizes custom nickname over Firebase display name
  static String get displayName {
    // First check for custom nickname set by user
    final customNickname = StorageService.getNickname();
    if (customNickname != null && customNickname.isNotEmpty) {
      return customNickname;
    }
    
    try {
      // Then check Firebase display name (from Google sign-in)
      if (currentUser?.displayName != null &&
          currentUser!.displayName!.isNotEmpty) {
        return currentUser!.displayName!;
      }
      
      // Generate a default player name based on UID
      if (currentUser != null) {
        final shortId = currentUser!.uid.substring(0, 6).toUpperCase();
        return 'Player_$shortId';
      }
    } catch (_) {}
    
    return 'Player';
  }

  /// Set custom nickname for the user
  static Future<void> setNickname(String nickname) async {
    await StorageService.setNickname(nickname);
    
    // If user is signed in (not anonymous), also sync to Firestore
    if (isSignedIn && !isAnonymous) {
      try {
        await _firestore.collection('users').doc(oderId).set({
          'displayName': nickname,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Update leaderboard entry
        await UserSyncService.updateDisplayName(nickname);
      } catch (e) {
        debugPrint('Failed to sync nickname to cloud: $e');
      }
    }
  }

  /// Get current nickname (custom or generated)
  static String get nickname => displayName;

  /// Photo URL
  static String? get photoUrl => currentUser?.photoURL;

  /// Auth state changes stream
  static Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  static Future<UserCredential?>? _anonSignInFuture;

  /// Sign in anonymously (for quick play without account – no form, no Firestore user doc).
  /// Duel progress is kept in LocalDuelStatsService on device; no cloud profile until Google sign-in.
  /// Uses a 6s timeout and re-entrancy guard so only one sign-in runs at a time (avoids native crash).
  static Future<UserCredential?> signInAnonymously() async {
    if (_anonSignInFuture != null) {
      return _anonSignInFuture;
    }
    _anonSignInFuture = _signInAnonymouslyImpl();
    try {
      return await _anonSignInFuture;
    } finally {
      _anonSignInFuture = null;
    }
  }

  static Future<UserCredential?> _signInAnonymouslyImpl() async {
    try {
      // Small yield to let caller continue without blocking.
      await Future.delayed(Duration.zero);

      final userCredential = await _auth
          .signInAnonymously()
          .timeout(const Duration(seconds: 6), onTimeout: () {
        throw TimeoutException('Anonymous sign-in timed out');
      });

      if (userCredential.user == null) {
        debugPrint('Anonymous sign-in: user is null');
        return null;
      }

      // Create a minimal user profile for anonymous users so admin panel can track them
      try {
        final userRef = _firestore.collection('users').doc(userCredential.user!.uid);
        final docSnap = await userRef.get();
        if (!docSnap.exists) {
          await userRef.set({
            'uid': userCredential.user!.uid,
            'displayName': '',
            'email': '',
            'photoUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeenAt': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
            'isAnonymous': true,
          });
        }
      } catch (e) {
        debugPrint('Anonymous profile creation failed (non-fatal): $e');
      }

      debugPrint('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      // Catch everything – this is called via .ignore() at startup,
      // so it must never throw.
      debugPrint('Anonymous sign-in failed: $e');
      return null;
    }
  }

  /// Sign in with Google.
  /// If user was anonymous (played duel without account), we link Google to that same
  /// account so the UID stays the same and no "transfer" is needed; then we upload
  /// local duel progress to Firestore (users/ doc created here).
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      _lastSignInError = null;
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _lastSignInError = 'Google sign-in cancelled by user.';
        debugPrint(_lastSignInError);
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final wasAnonymous = isAnonymous;
      UserCredential userCredential;

      if (wasAnonymous && currentUser != null) {
        // Link Google to existing anonymous account – same UID, progress preserved
        try {
          userCredential = await currentUser!.linkWithCredential(credential);
          debugPrint(
              'Linked Google to anonymous account: ${userCredential.user?.uid}');
        } on FirebaseAuthException catch (linkError) {
          if (linkError.code == 'credential-already-in-use') {
            // This Google account already has a separate Firebase account.
            // Merge local anonymous progress into that account, then sign in.
            debugPrint(
                'Google account already in use – merging local data then switching accounts');
            final mergeResult = await _mergeLocalThenSignIn(credential);
            if (mergeResult != null) {
              debugPrint('Signed in after merge: ${mergeResult.user?.displayName}');
              return mergeResult;
            }
            return null;
          }
          rethrow;
        }
      } else {
        // New sign-in (or not signed in)
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Post-sign-in Firestore sync – non-blocking so sign-in succeeds even
      // if Firestore rules reject the write (e.g. first-time setup, stale rules).
      try {
        await _createOrUpdateUserProfile(userCredential.user!);
      } catch (e) {
        debugPrint('Post-sign-in profile sync failed (non-fatal): $e');
      }

      try {
        if (wasAnonymous) {
          await UserSyncService.syncToCloud();
        } else {
          final hasPending = await UserSyncService.hasPendingSync();
          if (hasPending) {
            await UserSyncService.syncToCloud();
          } else {
            await UserSyncService.syncFromCloud();
          }
        }
      } catch (e) {
        debugPrint('Post-sign-in cloud sync failed (non-fatal): $e');
      }

      try {
        await EntitlementService.refreshFromCloud();
      } catch (e) {
        debugPrint('Post-sign-in entitlement refresh failed (non-fatal): $e');
      }

      debugPrint('Signed in as: ${userCredential.user?.displayName}');
      return userCredential;
    } on PlatformException catch (e) {
      final msg = '${e.code} ${e.message ?? ''}'.toLowerCase();
      if (msg.contains('developer_error') ||
          msg.contains('unknown calling package name') ||
          msg.contains('com.google.android.gms')) {
        _lastSignInError =
            'Google Sign-In is not configured for this Android app yet. '
            'Enable Google provider in Firebase Auth and add Android SHA-1/SHA-256, '
            'then download new google-services.json.';
      } else {
        _lastSignInError = 'Google sign-in failed: ${e.message ?? e.code}';
      }
      debugPrint('Google sign-in platform error: ${e.code} ${e.message}');
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint('This Google account is already used by another user.');
      }
      _lastSignInError = 'Google sign-in error: ${e.message ?? e.code}';
      debugPrint('Google sign-in error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      _lastSignInError = 'Google sign-in error: $e';
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  /// Sign in with Apple (same flow as Google: link if anonymous, then sync).
  /// Requires Apple Developer account + "Sign in with Apple" in Firebase Console.
  static Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('Apple sign-in: no identity token');
        return null;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );

      final wasAnonymous = isAnonymous;
      UserCredential userCredential;

      if (wasAnonymous && currentUser != null) {
        try {
          userCredential = await currentUser!.linkWithCredential(oauthCredential);
          debugPrint(
              'Linked Apple to anonymous account: ${userCredential.user?.uid}');
        } on FirebaseAuthException catch (linkError) {
          if (linkError.code == 'credential-already-in-use') {
            debugPrint(
                'Apple account already in use – merging local data then switching accounts');
            final mergeResult = await _mergeLocalThenSignIn(oauthCredential);
            if (mergeResult != null) {
              debugPrint('Signed in after Apple merge: ${mergeResult.user?.displayName}');
              return mergeResult;
            }
            return null;
          }
          rethrow;
        }
      } else {
        userCredential = await _auth.signInWithCredential(oauthCredential);
      }

      await _createOrUpdateUserProfile(userCredential.user!);

      if (wasAnonymous) {
        await UserSyncService.syncToCloud();
      } else {
        final hasPending = await UserSyncService.hasPendingSync();
        if (hasPending) {
          await UserSyncService.syncToCloud();
        } else {
          await UserSyncService.syncFromCloud();
        }
      }
      await EntitlementService.refreshFromCloud();

      debugPrint('Signed in with Apple: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint('This Apple ID is already used by another user.');
      }
      debugPrint('Apple sign-in error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return null;
    }
  }

  /// Called when `linkWithCredential` fails with credential-already-in-use.
  /// Saves local anonymous progress, signs in to the existing account, then
  /// merges the anonymous data into that account (keeping the higher values).
  static Future<UserCredential?> _mergeLocalThenSignIn(AuthCredential credential) async {
    // 1. Capture all local progress before signing out of anonymous account
    final localLevel = UserSyncService.exportLocalForMerge();
    final oldAnonymousUid = currentUser?.uid;

    // 2. Sign in to the existing account that owns this credential
    final newCredential = await _auth.signInWithCredential(credential);
    final user = newCredential.user;
    if (user == null) return null;

    // 3. Create/update profile doc if needed
    try {
      await _createOrUpdateUserProfile(user);
    } catch (e) {
      debugPrint('Merge profile sync failed (non-fatal): $e');
    }

    // 4. Merge: pull cloud data, take the best of local vs cloud, write back
    try {
      await UserSyncService.mergeLocalIntoCloud(localLevel);
      await EntitlementService.refreshFromCloud();
    } catch (e) {
      debugPrint('Merge cloud sync failed (non-fatal): $e');
    }

    // 5. Clean up the orphaned anonymous Firestore doc
    if (oldAnonymousUid != null && oldAnonymousUid != user.uid) {
      try {
        await _firestore.collection('users').doc(oldAnonymousUid).delete();
        debugPrint('Deleted orphaned anonymous doc: $oldAnonymousUid');
      } catch (e) {
        debugPrint('Orphan cleanup failed (non-fatal): $e');
      }
    }

    debugPrint('Merged anonymous data into existing account: ${user.uid}');
    return newCredential;
  }

  static String _generateNonce([int length = 32]) {    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create or update user profile in Firestore
  static Future<void> _createOrUpdateUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Create new user profile
      await userRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? 'Player',
        'photoUrl': user.photoURL,
        'email': user.email ?? '',
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'duelStats': {
          'wins': 0,
          'losses': 0,
          'elo': 450, // Starting ELO (Bronze division)
          'division': 'Bronze',
          'gamesPlayed': 0,
          'winStreak': 0,
          'bestWinStreak': 0,
          'totalPlayTime': 0, // in seconds
          'avgCompletionTime': 0, // in seconds
        },
        'achievements': [],
        'settings': {
          'notifications': true,
          'soundEnabled': true,
        },
      });
      debugPrint('Created new user profile for ${user.displayName}');
    } else {
      // Update last seen + ensure createdAt exists for legacy users
      final updateData = <String, dynamic>{
        'lastSeenAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? doc.data()?['displayName'],
        'photoUrl': user.photoURL ?? doc.data()?['photoUrl'],
        'email': user.email ?? doc.data()?['email'] ?? '',
        'isAnonymous': false,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      };
      if (doc.data()?['createdAt'] == null) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
      }
      await userRef.update(updateData);
      debugPrint('Updated user profile for ${user.displayName}');
    }
  }

  /// Get user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isSignedIn) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Get user's account creation date
  static Future<DateTime?> getCreatedAt() async {
    if (!isSignedIn) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['createdAt'] != null) {
        final timestamp = data['createdAt'] as Timestamp;
        return timestamp.toDate();
      }
      // Fallback: use Firebase Auth metadata
      return currentUser?.metadata.creationTime;
    } catch (e) {
      debugPrint('Error getting createdAt: $e');
      return currentUser?.metadata.creationTime;
    }
  }

  /// Get user's country code (from local storage or Firebase)
  static String getCountryCode() {
    return StorageService.getCountryCode();
  }

  /// Set user's country code and sync to Firebase
  static Future<void> setCountryCode(String code) async {
    await StorageService.setCountryCode(code);
    
    // Sync to Firebase if user is signed in
    if (isSignedIn && !isAnonymous) {
      try {
        await _firestore.collection('users').doc(userId).set({
          'countryCode': code,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Update leaderboard entries
        await UserSyncService.updateCountryCode(code);
      } catch (e) {
        debugPrint('Failed to sync country code to cloud: $e');
      }
    }
  }

  /// Get country flag emoji from country code
  static String getCountryFlag() {
    final code = getCountryCode().toUpperCase();
    if (code.length != 2) return '🌍';
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([firstLetter, secondLetter]);
  }

  /// Get user duel stats
  static Future<Map<String, dynamic>?> getBattleStats() async {
    final profile = await getUserProfile();
    // Support both old 'battleStats' and new 'duelStats' for migration
    return profile?['duelStats'] as Map<String, dynamic>? ??
        profile?['battleStats'] as Map<String, dynamic>?;
  }

  /// Update duel stats after a game
  static Future<void> updateBattleStats({
    required bool won,
    required int eloChange,
    required int newElo,
    int? completionTimeSeconds,
  }) async {
    if (!isSignedIn) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();
      final currentStats = doc.data()?['duelStats'] as Map<String, dynamic>? ??
          doc.data()?['battleStats'] as Map<String, dynamic>? ??
          {};

      final currentWinStreak = currentStats['winStreak'] ?? 0;
      final bestWinStreak = currentStats['bestWinStreak'] ?? 0;

      int newWinStreak = won ? currentWinStreak + 1 : 0;
      int newBestWinStreak =
          newWinStreak > bestWinStreak ? newWinStreak : bestWinStreak;

      // Calculate division from ELO
      final divisionInfo = _getRankFromElo(newElo);

      final updates = <String, dynamic>{
        'duelStats.gamesPlayed': FieldValue.increment(1),
        'duelStats.wins':
            won ? FieldValue.increment(1) : FieldValue.increment(0),
        'duelStats.losses':
            won ? FieldValue.increment(0) : FieldValue.increment(1),
        'duelStats.elo': newElo,
        'duelStats.division': divisionInfo['rank'],
        'duelStats.winStreak': newWinStreak,
        'duelStats.bestWinStreak': newBestWinStreak,
        'duelStats.lastPlayedAt': FieldValue.serverTimestamp(),
      };

      // Update completion time stats if provided
      if (completionTimeSeconds != null) {
        final totalTime = currentStats['totalPlayTime'] ?? 0;
        final gamesPlayed = currentStats['gamesPlayed'] ?? 0;
        final newTotalTime = totalTime + completionTimeSeconds;
        final newAvgTime = gamesPlayed > 0
            ? newTotalTime ~/ (gamesPlayed + 1)
            : completionTimeSeconds;

        updates['duelStats.totalPlayTime'] = newTotalTime;
        updates['duelStats.avgCompletionTime'] = newAvgTime;
      }

      await userRef.update(updates);

      // Also update duel leaderboard
      await _updateDuelLeaderboard(newElo, divisionInfo['rank'] as String);

      debugPrint('Updated duel stats: ELO $newElo, ${won ? "WIN" : "LOSS"}');
    } catch (e) {
      debugPrint('Error updating duel stats: $e');
    }
  }

  /// Update duel leaderboard entry
  static Future<void> _updateDuelLeaderboard(int elo, String division) async {
    if (!isSignedIn || isAnonymous) return;

    try {
      await _firestore.collection('duel_leaderboard').doc(userId).set({
        'oderId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'elo': elo,
        'division': division,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating duel leaderboard: $e');
    }
  }

  /// Force-sync the duel leaderboard after debug stats update.
  static Future<void> syncDuelLeaderboard(int elo) async {
    if (!isSignedIn || isAnonymous) return;
    final division = _getRankFromElo(elo)['rank'] as String;
    await _updateDuelLeaderboard(elo, division);
  }

  /// Sync local stats to cloud (full replace)
  static Future<void> syncBattleStatsFromLocal(
      Map<String, dynamic> localStats) async {
    if (!isSignedIn || isAnonymous) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final elo = localStats['elo'] ?? 450;
      final divisionInfo = _getRankFromElo(elo);

      await userRef.set({
        'duelStats': {
          'gamesPlayed': localStats['totalGames'] ?? 0,
          'wins': localStats['wins'] ?? 0,
          'losses': localStats['losses'] ?? 0,
          'elo': elo,
          'division': divisionInfo['rank'],
          'winStreak': localStats['winStreak'] ?? 0,
          'bestWinStreak': localStats['bestStreak'] ?? 0,
        },
      }, SetOptions(merge: true));

      // Update leaderboard
      await _updateDuelLeaderboard(elo, divisionInfo['rank'] as String);

      debugPrint('Synced local stats to cloud');
    } catch (e) {
      debugPrint('Error syncing duel stats: $e');
    }
  }

  /// Division thresholds for Duel mode (ELO-based)
  /// Bronze: 0-499, Silver: 500-799, Gold: 800-1099, Platinum: 1100-1399
  /// Diamond: 1400-1699, Master: 1700-1999, Grandmaster: 2000-2299, Champion: 2300+
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

  /// Get division name from ELO
  static Map<String, dynamic> _getRankFromElo(int elo) {
    String division;

    if (elo < 500) {
      division = 'Bronze';
    } else if (elo < 800) {
      division = 'Silver';
    } else if (elo < 1100) {
      division = 'Gold';
    } else if (elo < 1400) {
      division = 'Platinum';
    } else if (elo < 1700) {
      division = 'Diamond';
    } else if (elo < 2000) {
      division = 'Master';
    } else if (elo < 2300) {
      division = 'Grandmaster';
    } else {
      division = 'Champion';
    }

    return {
      'rank': division,
      'tier': 1
    }; // Tier kept for backward compatibility
  }

  /// Get rank display string (e.g., "Gold")
  static String getRankDisplay(int elo) {
    final info = _getRankFromElo(elo);
    return info['rank'] as String;
  }

  /// Get rank emoji
  static String getRankEmoji(String rank) {
    const emojis = {
      'Bronze': '🥉',
      'Silver': '🥈',
      'Gold': '🥇',
      'Platinum': '💎',
      'Diamond': '💠',
      'Master': '🏆',
      'Grandmaster': '👑',
      'Champion': '🔥',
    };
    return emojis[rank] ?? '🎮';
  }

  /// Get division color
  static int getDivisionColorValue(String division) {
    const colors = {
      'Bronze': 0xFFCD7F32,
      'Silver': 0xFFC0C0C0,
      'Gold': 0xFFFF8C00,
      'Platinum': 0xFF00BFFF,
      'Diamond': 0xFF1E90FF,
      'Master': 0xFFFFA500,
      'Grandmaster': 0xFF9400D3,
      'Champion': 0xFFFF4500,
    };
    return colors[division] ?? 0xFF808080;
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      // Sync local data to cloud before signing out
      if (isSignedIn && !isAnonymous) {
        await UserSyncService.syncToCloud();
      }

      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear local caches so the next sign-in doesn't inherit stale data
      await LocalDuelStatsService.resetAll();
      await StorageService.clearAll();
      await StorageService.init();

      debugPrint('Signed out and local data cleared');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Delete account
  static Future<bool> deleteAccount() async {
    if (!isSignedIn) return false;

    try {
      final uid = userId;
      if (uid == null) return false;

      // Delete all user-related Firestore collections
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('users').doc(uid));
      batch.delete(_firestore.collection('leaderboard').doc(uid));
      batch.delete(_firestore.collection('duel_leaderboard').doc(uid));
      batch.delete(_firestore.collection('entitlements').doc(uid));
      await batch.commit();

      // Delete subcollections (best effort)
      try {
        final duelHistory = await _firestore
            .collection('users')
            .doc(uid)
            .collection('duel_history')
            .limit(500)
            .get();
        for (final doc in duelHistory.docs) {
          await doc.reference.delete();
        }
        final achievements = await _firestore
            .collection('users')
            .doc(uid)
            .collection('achievements')
            .limit(500)
            .get();
        for (final doc in achievements.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}

      // Delete Firebase Auth account
      bool authDeleted = false;
      try {
        await currentUser?.delete();
        authDeleted = true;
      } catch (e) {
        debugPrint('Firebase Auth delete failed (may need re-auth): $e');
      }

      // Sign out from Google
      await _googleSignIn.signOut();
      if (!authDeleted) {
        await _auth.signOut();
      }

      // Mirror signOut cleanup: clear local caches
      await LocalDuelStatsService.resetAll();

      debugPrint('Account deleted (auth removed: $authDeleted)');
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }
}
