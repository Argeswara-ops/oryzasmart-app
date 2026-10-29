import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  developer.log(
    'Background message received: ${message.messageId}',
    name: 'NotificationService',
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback opsional yang dipanggil jika token FCM berganti/refresh
  Future<void> Function(String newToken)? onTokenRefresh;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Channel untuk notifikasi prioritas tinggi IoT Padi',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize() async {
    // 1. Minta izin notifikasi (Android 13+ & iOS)
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log(
      'Notification authorization status: ${settings.authorizationStatus}',
      name: 'NotificationService',
    );

    // 2. Konfigurasi foreground notification display dari FCM
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Inisialisasi plugin notifikasi lokal (untuk pop-up banner saat foreground)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotif.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        developer.log(
          'Notification tapped: ${details.payload}',
          name: 'NotificationService',
        );
      },
    );

    // Buat Notification Channel untuk Android
    final androidImplementation = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
      await androidImplementation.requestNotificationsPermission();
    }

    // 4. Ambil token registrasi FCM yang digunakan backend Laravel.
    // ignore: deprecated_member_use
    _fcm.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      developer.log(
        'FCM registration token refreshed',
        name: 'NotificationService',
      );
      await onTokenRefresh?.call(token);
    });
    try {
      // ignore: deprecated_member_use
      _fcmToken = await _fcm.getToken();
    } catch (e) {
      developer.log(
        'Failed to get FCM registration token: $e',
        name: 'NotificationService',
      );
    }

    // 5. Handler saat aplikasi aktif di layar (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'Foreground message received: ${message.notification?.title}',
        name: 'NotificationService',
      );

      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotif.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 6. Handler saat notifikasi diklik ketika aplikasi di background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'Notification opened app from background: ${message.data}',
        name: 'NotificationService',
      );
    });

    // 7. Handler saat notifikasi diklik ketika aplikasi ditutup (Terminated)
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        'App opened from terminated state by notification: ${initialMessage.data}',
        name: 'NotificationService',
      );
    }
  }

  /// Gets the FCM registration token used by the Laravel backend.
  Future<String?> getOrRefreshToken() async {
    // ignore: deprecated_member_use
    _fcmToken = await _fcm.getToken();
    return _fcmToken;
  }
}
