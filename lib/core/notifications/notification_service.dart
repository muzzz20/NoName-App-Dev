import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM push notifications. NAD-39.
///
/// **Defensive by design** — every call is wrapped so a messaging failure
/// (no permission, web without a configured service worker / VAPID key,
/// emulator without Google Play services) NEVER crashes the app. Push is
/// a nice-to-have; the app must boot and run regardless.
///
/// Activation notes:
/// - Web push additionally needs a VAPID key (Firebase console → Project
///   settings → Cloud Messaging → Web Push certificates) wired into
///   getToken(vapidKey: ...) and the `web/firebase-messaging-sw.js`
///   service worker (stub committed).
/// - iOS additionally needs an APNs key uploaded to Firebase.
///
/// The server side (Cloud Function onActivityCreate → topic
/// "new-activities") works independently of any client config.
class NotificationService {
  NotificationService._();

  /// Set by the app (after the router exists) to navigate on tap.
  static void Function(String route)? onNavigate;

  /// Initialize messaging: request permission, subscribe to the
  /// new-activities topic, persist the token, and wire tap handling.
  /// Safe to call once at startup; no-ops on failure.
  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission();

      // Topic subscription is unsupported on web — guard it.
      if (!kIsWeb) {
        await messaging.subscribeToTopic('new-activities');
      }

      await _saveToken(messaging);

      // App opened from a terminated state by tapping a notification.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);

      // App in background, brought to foreground by a tap.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    } catch (e) {
      debugPrint('NotificationService.init skipped: $e');
    }
  }

  static Future<void> _saveToken(FirebaseMessaging messaging) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final token = await messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NotificationService token save skipped: $e');
    }
  }

  static void _handleTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      onNavigate?.call(route);
    }
  }
}
