import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  FCMService({required this.onMessage});

  final void Function(RemoteMessage message, String handler) onMessage;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  NotificationSettings? permissionSettings;
  String? token;
  String? setupError;
  bool _started = false;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;

    // T1: Message received while the app is visible.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      onMessage(message, 'onMessage');
    });

    // T2: The user taps a notification while the app is backgrounded.
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onMessage(message, 'onMessageOpenedApp');
    });

    // T3: A notification tap starts the app from a terminated state.
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onMessage(initialMessage, 'getInitialMessage');
      }
    } catch (error) {
      setupError = 'Initial-message check failed: $error';
    }

    try {
      permissionSettings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      token = await _messaging.getToken();
    } catch (error) {
      setupError = 'Permission or token error: $error';
    }

    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
      token = newToken;
    });
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    _tokenSubscription?.cancel();
  }
}
