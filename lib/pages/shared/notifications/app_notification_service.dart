import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/firebase_account_gateway.dart';

/// Registers this signed-in device for server notifications and renders FCM
/// messages locally while the app is in the foreground.
class AppNotificationService {
  AppNotificationService._();

  static final instance = AppNotificationService._();
  static const channelId = 'tro_premium_updates';
  static const channelName = 'Thông báo nhà trọ';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _uid;
  DocumentReference<Map<String, dynamic>>? _deviceDocument;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings: settings);
    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Tin nhắn và cập nhật về nhà trọ, hợp đồng, thanh toán.',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _initialized = true;
  }

  Future<PermissionStatus> notificationStatus() =>
      Permission.notification.status;

  Future<bool> requestPermissionOnly() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return false;
    }
    await initialize();
    var status = await Permission.notification.status;
    if (!status.isGranted) status = await Permission.notification.request();
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return false;
    }
    if (!status.isGranted) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (error) {
      debugPrint('FCM permission setup failed: $error');
      return false;
    }
  }

  /// Called after login or from the notification settings switch.
  Future<bool> requestAndRegister(
    FirebaseAccountSession session, {
    required bool enabled,
  }) async {
    if (!enabled) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      if (!kIsWeb &&
          [
            TargetPlatform.android,
            TargetPlatform.iOS,
          ].contains(defaultTargetPlatform)) {
        try {
          _uid = session.uid;
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            await _saveDeviceToken(token, enabled: false);
          }
        } catch (error) {
          debugPrint(
            'Could not save the disabled notification preference: $error',
          );
        }
      }
      return false;
    }
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return false;
    }
    if (!await requestPermissionOnly()) return false;

    try {
      _uid = session.uid;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return false;
      await _saveDeviceToken(token, enabled: true);
      await _tokenSubscription?.cancel();
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (refreshed) => _saveDeviceToken(refreshed, enabled: true),
      );
      return true;
    } catch (error) {
      debugPrint('FCM registration failed: $error');
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (!enabled) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
    }
    final document = _deviceDocument;
    if (document == null) return;
    try {
      await document.set({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Could not update device notification preference: $error');
    }
  }

  Future<void> unregister() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    try {
      await _deviceDocument?.delete();
    } catch (error) {
      debugPrint('Could not remove the FCM device registration: $error');
    }
    _deviceDocument = null;
    _uid = null;
  }

  Future<void> _saveDeviceToken(String token, {required bool enabled}) async {
    final uid = _uid;
    if (uid == null) return;
    final key = sha256.convert(utf8.encode(token)).toString();
    final document = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(key);
    await document.set({
      'token': token,
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _deviceDocument = document;
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title is! String || title.isEmpty || body is! String || body.isEmpty) {
      return;
    }
    await initialize();
    await _local.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          icon: 'ic_stat_notification',
          channelDescription: 'Tin nhắn và cập nhật về nhà trọ.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
