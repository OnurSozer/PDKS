import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final Completer<bool> _initCompleter = Completer<bool>();
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'pdks_default',
    'PDKS Notifications',
    description: 'PDKS push notifications',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('NotificationService: permission status=${settings.authorizationStatus}');

    // Show FCM notifications even when app is in the foreground (iOS/macOS only)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications for Android foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Auto-re-register token on refresh
    _messaging.onTokenRefresh.listen((_) => registerToken());

    // Signal that initialization is complete
    _initCompleter.complete(true);
  }

  static void markInitFailed() {
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete(false);
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> registerToken() async {
    // Wait for Firebase to be initialized before registering
    final success = await _initCompleter.future;
    if (!success) {
      debugPrint('NotificationService: Firebase not initialized, cannot register token');
      return;
    }

    debugPrint('NotificationService: registerToken() called');
    final token = await getToken();
    debugPrint('NotificationService: FCM token = ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    if (token == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      final response = await SupabaseService.client.functions.invoke(
        'register-device-token',
        body: {'token': token, 'platform': platform},
      );
      debugPrint('NotificationService: register response status=${response.status}, data=${response.data}');
    } catch (e) {
      debugPrint('NotificationService: Failed to register device token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    // On iOS, setForegroundNotificationPresentationOptions handles display.
    // Only use flutter_local_notifications on Android.
    if (!Platform.isAndroid) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
  }

  static Future<void> onTokenRefresh(void Function(String) callback) async {
    _messaging.onTokenRefresh.listen(callback);
  }
}
