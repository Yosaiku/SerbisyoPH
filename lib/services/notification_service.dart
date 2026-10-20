import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Function(RemoteMessage)? onMessageReceived;

  Future<void> initialize() async {
    await _requestPermission();
    await _getToken();
    _handleForegroundMessages();
    _handleBackgroundMessages();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _getToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcm_token': token,
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
      if (onMessageReceived != null) {
        onMessageReceived!(message);
      }
    });
  }

  void _handleBackgroundMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (onMessageReceived != null) {
        onMessageReceived!(message);
      }
    });
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('Foreground notification: ${notification.title}');
  }

  Future<void> storeInAppNotification({
    required String recipientUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipient_id': recipientUserId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
}
