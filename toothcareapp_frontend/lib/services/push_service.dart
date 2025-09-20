import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class PushService {
  static bool _initialized = false;

  static Future<void> initializeAndRegister() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase init error: $e');
      }
    }

    final messaging = FirebaseMessaging.instance;

    if (Platform.isAndroid) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        print('Notification permission: ${settings.authorizationStatus}');
      }
    }

    try {
      final token = await messaging.getToken();
      if (kDebugMode) {
        print('FCM token: $token');
      }
      if (token != null) {
        await ApiService.registerDeviceToken(platform: 'android', token: token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error obtaining FCM token: $e');
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) {
        print('FCM token refreshed: $newToken');
      }
      await ApiService.registerDeviceToken(platform: 'android', token: newToken);
    });
  }
}
