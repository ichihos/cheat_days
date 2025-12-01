import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(userId, newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Handle foreground notifications
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle background notifications
  }

  Future<void> scheduleCheatDayReminder(String userId, DateTime scheduledDate) async {
    await _firestore.collection('scheduledNotifications').add({
      'userId': userId,
      'type': 'cheat_day_reminder',
      'scheduledDate': scheduledDate.toIso8601String(),
      'message': '今日はチートデイ！何を食べますか？',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelCheatDayReminder(String notificationId) async {
    await _firestore.collection('scheduledNotifications').doc(notificationId).delete();
  }
}
