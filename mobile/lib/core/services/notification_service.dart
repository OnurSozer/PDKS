import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> registerToken() async {
    final token = await getToken();
    if (token == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await SupabaseService.client.functions.invoke(
        'register-device-token',
        body: {'token': token, 'platform': platform},
      );
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Foreground notifications are handled by the app UI
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    final type = message.data['type'];
    if (type == 'forgot_clockout') {
      // Deep link to home screen is the default
    } else if (type == 'meal_ready') {
      // Show notification - already on home screen
    }
  }

  static Future<void> onTokenRefresh(void Function(String) callback) async {
    _messaging.onTokenRefresh.listen(callback);
  }
}
