import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'fcm_service.dart';

// Background processing is separate from the visible app's UI state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('onBackgroundMessage: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const CloudCourierApp());
}

class CloudCourierApp extends StatelessWidget {
  const CloudCourierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cloud Courier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF285F8F)),
        useMaterial3: true,
      ),
      home: const CloudCourierHome(),
    );
  }
}

class CloudCourierHome extends StatefulWidget {
  const CloudCourierHome({super.key});

  @override
  State<CloudCourierHome> createState() => _CloudCourierHomeState();
}

class _CloudCourierHomeState extends State<CloudCourierHome> {
  late final FCMService _service;

  String _title = 'Campus updates';
  String _asset = 'default';
  String _handler = 'No message yet';
  String _messageId = 'None';
  String _diagnostic = 'Waiting for a Firebase message';
  String _permission = 'Checking...';
  String _connection = 'Connecting...';
  int _receiptCount = 0;

  @override
  void initState() {
    super.initState();
    _service = FCMService(onMessage: _handleMessage);
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    await _service.initialize();
    if (!mounted) return;
    setState(() {
      _permission = _service.permissionSettings?.authorizationStatus.name ??
          'Unavailable';
      _connection = _service.setupError ??
          (_service.token == null ? 'Token not ready' : 'FCM ready');
    });
  }

  void _handleMessage(RemoteMessage message, String handler) {
    if (!mounted) return;

    final action = message.data['action']?.toString();
    final asset = message.data['asset']?.toString();

    setState(() {
      // Always update these fields, including for rejected payloads.
      _receiptCount++;
      _handler = handler;
      _messageId = message.messageId ?? 'Not provided';

      if (action != 'update_ui') {
        _diagnostic = 'Rejected: action must be update_ui';
        return; // Preserve previous title and image.
      }
      if (asset != 'default' && asset != 'promo') {
        _diagnostic = 'Rejected: missing or unsupported asset';
        return; // Preserve previous title and image.
      }

      _asset = asset!;
      _title = asset == 'promo' ? 'New campus promotion!' : 'Campus updates';
      _diagnostic = 'Accepted: $asset';
    });
  }

  Future<void> _copyToken() async {
    final token = _service.token;
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM token is not available yet')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token copied; paste it in Firebase Console')),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Courier')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_title,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/$_asset.png',
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Message evidence',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Last handler: $_handler'),
                    Text('Receipt count this launch: $_receiptCount'),
                    Text('Message ID: $_messageId',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('Diagnostic: $_diagnostic'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Firebase status',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Permission: $_permission'),
                    Text('Connection: $_connection'),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _copyToken,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy device token'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
