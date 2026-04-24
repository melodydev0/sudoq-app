import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'ads_service.dart';
import 'storage_service.dart';

/// Reads server-side premium entitlements and applies them locally.
///
/// Source of truth should be `/entitlements/{uid}` written by trusted backend.
class EntitlementService {
  EntitlementService._();

  /// Called after premium status changes so UI can update (e.g. Riverpod provider).
  static void Function(bool isPremium)? onPremiumChanged;

  static FirebaseAuth? _authInstance;
  static FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  static FirebaseFirestore? _firestoreInstance;
  static FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  static const Set<String> _supportedProductIds = {
    'sudoq_premium',
    'sudoq_premium_weekly',
    'sudoq_premium_yearly',
  };

  static Future<bool?> refreshFromCloud() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    try {
      final doc = await _firestore.collection('entitlements').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data() ?? <String, dynamic>{};
      final premium = _isPremiumActive(data);
      final wasPremium = StorageService.isAdsFree();

      if (premium != wasPremium) {
        await StorageService.setAdsFree(premium);
        if (premium) {
          AdsService.onAdsFreeActivated();
        } else {
          await AdsService.init();
        }
        onPremiumChanged?.call(premium);
      }

      return premium;
    } catch (_) {
      return null;
    }
  }

  /// Submits a purchase token for server-side verification.
  /// Returns true when backend confirms premium is active for current user.
  static Future<bool> submitPurchaseClaim(PurchaseDetails purchase, {String? price, String? currency}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    if (kIsWeb) return false;
    if (!_supportedProductIds.contains(purchase.productID)) return false;

    final claimRef = _firestore.collection('purchase_claims').doc();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final purchaseToken = _extractAndroidPurchaseToken(purchase);
      if (purchaseToken == null || purchaseToken.isEmpty) return false;
      await claimRef.set({
        'uid': user.uid,
        'platform': 'android',
        'productId': purchase.productID,
        'purchaseToken': purchaseToken,
        'status': 'pending',
        'isTestPurchase': kDebugMode,
        'price': price ?? '',
        'currency': currency ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final receiptData = purchase.verificationData.serverVerificationData;
      if (receiptData.isEmpty) return false;
      await claimRef.set({
        'uid': user.uid,
        'platform': 'ios',
        'productId': purchase.productID,
        'receiptData': receiptData,
        'status': 'pending',
        'isTestPurchase': kDebugMode,
        'price': price ?? '',
        'currency': currency ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      return false;
    }

    final verified = await _waitForClaimVerification(claimRef.id);
    if (verified) {
      final premium = await refreshFromCloud();
      return premium == true;
    }
    return false;
  }

  static String? _extractAndroidPurchaseToken(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseToken;
    }
    final fallback = purchase.verificationData.serverVerificationData;
    if (fallback.isEmpty) return null;
    return fallback;
  }

  static Future<bool> _waitForClaimVerification(String claimId) async {
    // Use a realtime listener instead of polling for instant response
    final completer = Completer<bool>();
    final docRef = _firestore.collection('purchase_claims').doc(claimId);

    late final StreamSubscription sub;
    Timer? timeout;

    sub = docRef.snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() ?? <String, dynamic>{};
      final status = (data['status'] as String?) ?? 'pending';
      if (status == 'verified') {
        timeout?.cancel();
        sub.cancel();
        if (!completer.isCompleted) completer.complete(data['premium'] == true);
      } else if (status == 'rejected' || status == 'error') {
        timeout?.cancel();
        sub.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    }, onError: (_) {
      timeout?.cancel();
      sub.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    // Timeout after 20 seconds
    timeout = Timer(const Duration(seconds: 20), () {
      sub.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  static bool _isPremiumActive(Map<String, dynamic> data) {
    final premium = data['premium'] == true;
    if (!premium) return false;

    final expiresAt = data['expiresAt'];
    if (expiresAt is! Timestamp) return true; // Lifetime entitlement
    return expiresAt.toDate().isAfter(DateTime.now());
  }
}

