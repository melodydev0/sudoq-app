import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_sync_service.dart';

/// Authentication service for Firebase Auth with Google Sign-In
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current user
  static User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  /// Check if user is anonymous
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// User ID
  static String? get oderId => currentUser?.uid;

  // Alias for compatibility
  static String? get userId => oderId;

  /// Display name
  static String get displayName {
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    }
    if (isAnonymous) {
      // Generate a random player name for anonymous users
      final shortId = currentUser?.uid.substring(0, 6).toUpperCase() ?? 'ANON';
      return 'Player_$shortId';
    }
    return 'Player';
  }

  /// Photo URL
  static String? get photoUrl => currentUser?.photoURL;

  /// Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

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
      await Future.delayed(Duration.zero);
      final userCredential = await _auth
          .signInAnonymously()
          .timeout(const Duration(seconds: 4), onTimeout: () {
        debugPrint('Anonymous sign-in timed out (Firebase/network?)');
        throw TimeoutException('Anonymous sign-in timed out');
      });
      if (userCredential.user == null) {
        debugPrint('Anonymous sign-in: user is null');
        return null;
      }
      debugPrint('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Anonymous sign-in FirebaseAuthException: ${e.code} ${e.message}');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('Anonymous sign-in timeout: $e');
      return null;
    } catch (e, st) {
      debugPrint('Anonymous sign-in error: $e');
      if (kDebugMode) debugPrint('$st');
      return null;
    }
  }

  /// Sign in with Google.
  /// If user was anonymous (played duel without account), we link Google to that same
  /// account so the UID stays the same and no "transfer" is needed; then we upload
  /// local duel progress to Firestore (users/ doc created here).
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in cancelled by user');
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
        userCredential = await currentUser!.linkWithCredential(credential);
        debugPrint(
            'Linked Google to anonymous account: ${userCredential.user?.uid}');
      } else {
        // New sign-in (or not signed in)
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Create or update Firestore profile (for anonymous we had no users/ doc)
      await _createOrUpdateUserProfile(userCredential.user!);

      // If they were anonymous, upload local duel (and other) stats to cloud
      if (wasAnonymous) {
        await UserSyncService.syncToCloud();
      } else {
        await UserSyncService.syncFromCloud();
      }

      debugPrint('Signed in as: ${userCredential.user?.displayName}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint('This Google account is already used by another user.');
      }
      debugPrint('Google sign-in error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
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
        userCredential = await currentUser!.linkWithCredential(oauthCredential);
        debugPrint(
            'Linked Apple to anonymous account: ${userCredential.user?.uid}');
      } else {
        userCredential = await _auth.signInWithCredential(oauthCredential);
      }

      await _createOrUpdateUserProfile(userCredential.user!);

      if (wasAnonymous) {
        await UserSyncService.syncToCloud();
      } else {
        await UserSyncService.syncFromCloud();
      }

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

  static String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
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
        'email': user.email,
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
      // Update last seen
      await userRef.update({
        'lastSeenAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? doc.data()?['displayName'],
        'photoUrl': user.photoURL ?? doc.data()?['photoUrl'],
      });
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
      debugPrint('Signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Delete account
  static Future<bool> deleteAccount() async {
    if (!isSignedIn) return false;

    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete Firebase Auth account
      await currentUser?.delete();

      // Sign out from Google
      await _googleSignIn.signOut();

      debugPrint('Account deleted');
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }
}
