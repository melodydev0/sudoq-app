import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'storage_service.dart';

/// Handles OneSignal push notification setup, permission, and user sync.
class NotificationService {
  NotificationService._();

  static const String _appId = 'ff6a85b4-2c80-4fec-bb70-075ccf869d27';

  static FirebaseAuth? _authInstance;
  static FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  static bool _isInitialized = false;

  static bool get isEnabled => StorageService.getPushNotificationsEnabled();

  /// No-op: OneSignal handles background messages internally.
  static void registerBackgroundHandler() {}

  static Future<void> init() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    OneSignal.initialize(_appId);

    if (isEnabled) {
      await OneSignal.Notifications.requestPermission(true);
    }

    _syncExternalUserId();
    _auth.authStateChanges().listen((_) => _syncExternalUserId());

    OneSignal.Notifications.addClickListener(_onNotificationClicked);

    _isInitialized = true;
  }

  /// Links the Firebase UID to OneSignal so server can target by user ID.
  static void _syncExternalUserId() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      OneSignal.logout();
      return;
    }
    OneSignal.login(user.uid);
  }

  static void _onNotificationClicked(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;

    final type = data['type'] as String?;
    debugPrint('Notification clicked: type=$type, data=$data');

    // Future: navigate to relevant screen based on type
    // e.g. if (type == 'duel_match') navigateToBattle(data['battleId']);
  }

  /// Toggle push notifications on/off.
  static Future<void> setEnabled(bool enabled) async {
    await StorageService.setPushNotificationsEnabled(enabled);
    if (enabled) {
      OneSignal.User.pushSubscription.optIn();
      if (!_isInitialized) {
        await init();
      }
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
  }
}
