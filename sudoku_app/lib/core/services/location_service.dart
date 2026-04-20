import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'storage_service.dart';

/// Handles coarse location permission, acquisition, and syncing to Firestore.
///
/// Stores in `/users/{uid}.location`:
///   { latitude, longitude, country, updatedAt }
/// and `/users/{uid}.locationMeta`:
///   { permissionStatus, updatedAt }
class LocationService {
  LocationService._();

  static FirebaseAuth? _authInstance;
  static FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  static FirebaseFirestore? _firestoreInstance;
  static FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  static const String _keyPermissionAsked = 'location_permission_asked';

  static bool get wasPermissionAsked =>
      StorageService.prefs.getBool(_keyPermissionAsked) ?? false;

  static Future<void> _markPermissionAsked() async {
    await StorageService.prefs.setBool(_keyPermissionAsked, true);
  }

  /// Returns current permission status without prompting.
  static Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  /// Requests coarse location permission.
  /// Returns the resulting [LocationPermission].
  static Future<LocationPermission> requestPermission() async {
    await _markPermissionAsked();
    final permission = await Geolocator.requestPermission();
    await _syncPermissionStatusToCloud(permission);
    return permission;
  }

  /// Full flow: check → request if needed → get position → sync to Firestore.
  /// Call this after permission is granted.
  static Future<bool> fetchAndSync() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _syncPermissionStatusToCloud(permission);
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // coarse – city level
          timeLimit: Duration(seconds: 10),
        ),
      );

      await _syncLocationToCloud(position);
      return true;
    } catch (e) {
      debugPrint('LocationService.fetchAndSync error: $e');
      return false;
    }
  }

  static Future<void> _syncLocationToCloud(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'locationMeta': {
        'permissionStatus': 'granted',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  static Future<void> _syncPermissionStatusToCloud(
      LocationPermission permission) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final statusString = switch (permission) {
      LocationPermission.always => 'granted',
      LocationPermission.whileInUse => 'granted',
      LocationPermission.denied => 'denied',
      LocationPermission.deniedForever => 'denied_forever',
      LocationPermission.unableToDetermine => 'undetermined',
    };

    await _firestore.collection('users').doc(user.uid).set({
      'locationMeta': {
        'permissionStatus': statusString,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
