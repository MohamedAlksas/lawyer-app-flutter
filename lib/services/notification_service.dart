import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      // Firebase not configured (no google-services.json / GoogleService-Info.plist)
      return;
    }
  }

  Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return await messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> registerToken(String? token) async {
    if (token == null) return;
    try {
      final api = ApiService();
      await api.post('/notifications/token/register', data: {
        'token': token,
        'platform': 'mobile',
      });
    } catch (_) {}
  }

  Future<void> unregisterToken(String? token) async {
    if (token == null) return;
    try {
      final api = ApiService();
      await api.delete('/notifications/token/unregister', data: {
        'token': token,
      });
    } catch (_) {}
  }

  void listenToMessages({
    required void Function(String title, String body, Map<String, String> data) onMessage,
    required void Function(String title, String body, Map<String, String> data) onLaunch,
  }) {
    if (!_initialized) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        onMessage(
          notif.title ?? '',
          notif.body ?? '',
          Map<String, String>.from(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        onLaunch(
          notif.title ?? '',
          notif.body ?? '',
          Map<String, String>.from(message.data),
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        final notif = message.notification;
        if (notif != null) {
          onLaunch(
            notif.title ?? '',
            notif.body ?? '',
            Map<String, String>.from(message.data),
          );
        }
      }
    });
  }
}
