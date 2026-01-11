import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/debug_service.dart';
import 'revenuecat_helper.dart';

class SubscriptionService {
  static const String entitlementId = 'premium';

  static Future<void> init() async {
    if (kIsWeb) return; // RevenueCat not supported on Web

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration = PurchasesConfiguration(RevenueCatHelper.apiKey);
    await Purchases.configure(configuration);
  }

  static Future<bool> isPremium() async {
    // 1. Check RevenueCat (Mobile Only)
    if (!kIsWeb) {
      try {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        if (customerInfo.entitlements.all[entitlementId]?.isActive ?? false) {
          return true;
        }
      } on PlatformException catch (_) {
        // Continue to check Firestore
      }
    }

    // 2. Check Firestore (Gift Codes & Web/Mobile Fallback)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['premium_until'] != null) {
          final Timestamp expiry = doc.data()!['premium_until'];
          return expiry.toDate().isAfter(DateTime.now());
        }
      }
    } catch (e) {
      DebugService.error("Error checking firestore premium", e);
    }

    return false;
  }

  static Future<String?> redeemCode(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "User not logged in";

      final codeRef = FirebaseFirestore.instance.collection('promo_codes').doc(code.toUpperCase());
      final codeDoc = await codeRef.get();

      if (!codeDoc.exists) return "Invalid code";

      final data = codeDoc.data()!;
      if (data['is_active'] == false) return "Code expired";
      
      final usedCount = data['used_count'] ?? 0;
      final maxUses = data['max_uses'] ?? 1;
      if (usedCount >= maxUses) return "Code fully redeemed";

      // Apply Code
      final durationDays = data['duration_days'] ?? 30;
      final newExpiry = DateTime.now().add(Duration(days: durationDays));

      // Transaction to ensure safety
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(codeRef, {'used_count': FieldValue.increment(1)});
        
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        transaction.set(userRef, {
          'premium_until': Timestamp.fromDate(newExpiry),
          'redeemed_code': code.toUpperCase()
        }, SetOptions(merge: true));
      });

      return null; // Success
    } catch (e) {
      return "Error redeeming code: $e";
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (_) {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
