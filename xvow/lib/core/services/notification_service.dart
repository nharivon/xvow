import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService(this.client);

  final SupabaseClient client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    await Firebase.initializeApp();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initializationSettings);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _initialized = true;
  }

  Future<void> syncRegistration(String userId) async {
    if (kIsWeb) {
      return;
    }

    await initialize();

    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      await clearRegistration(userId);
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen((token) => _saveToken(userId, token));

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _saveToken(userId, token);
  }

  Future<void> clearRegistration(String userId) async {
    if (kIsWeb) {
      return;
    }

    if (_currentToken != null) {
      await client
          .from('notification_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', _currentToken!);
    } else {
      await client.from('notification_tokens').delete().eq('user_id', userId);
    }

    _currentToken = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _saveToken(String userId, String token) async {
    if (token.isEmpty) {
      return;
    }

    if (_currentToken != null && _currentToken != token) {
      await client
          .from('notification_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', _currentToken!);
    }

    await client.from('notification_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,token');

    _currentToken = token;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'xvow_push_channel',
        'Notifications XVOW',
        channelDescription: 'Rappels et validations des vœux hebdomadaires',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}