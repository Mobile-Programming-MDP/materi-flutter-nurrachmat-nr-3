import 'dart:convert';

import 'package:cepu_app/firebase_options.dart';
import 'package:cepu_app/screens/home_screen.dart';
import 'package:cepu_app/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const String webVapidKey =
  'BGMKDC2IU-0MZoAZWoKXrCWJXwmz2prRToS4phVQCvzfm35aUZzslKtaL6ROBCGXQjV2Vo0KOgY1bde5temaLSo';

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Izin notifikasi sementara diberikan');
  } else {
    print('Izin notifikasi ditolak');
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  final android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: 'Notifikasi masuk dari FCM',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: title,
    body: body,
    notificationDetails: platform,
  );
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['title'] ?? 'Pesan Baru';
  final body = data['body'] ?? '';
  final sender = data['senderName'] ?? 'Pengirim tidak diketahui';
  final time = data['sentAt'] ?? '';
  final photoUrl = data['senderPhotoUrl'] ?? '';

  ByteArrayAndroidBitmap? largeIconBitmap;
  if (photoUrl.isNotEmpty) {
    final base64 = await _networkImageToBase64(photoUrl);
    if (base64 != null) {
      largeIconBitmap = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }
  //pilih salah satu
  final styleInfo = largeIconBitmap != null
      ? BigPictureStyleInformation(
          largeIconBitmap,
          contentTitle: title,
          summaryText: '$body\n\nDari: $sender - $time',
          largeIcon: largeIconBitmap,
          hideExpandedLargeIcon: true,
        )
      : BigTextStyleInformation(
          '$body\n\nDari: $sender\nWaktu: $time',
          contentTitle: title,
        );

  final simpleStyleInfo = BigTextStyleInformation(
    '$body\n\nDari: $sender\nWaktu: $time',
    contentTitle: title,
  );

  final androidDetails = AndroidNotificationDetails(
    'detailed_channel',
    'Notifikasi Detail',
    channelDescription: 'Notifikasi dengan detail tambahan',
    styleInformation: simpleStyleInfo,
    largeIcon: largeIconBitmap,
    importance: Importance.max,
    priority: Priority.max,
  );

  final platform = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: title,
    body: body,
    notificationDetails: platform,
  );
}

Future<String?> _networkImageToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {}
  return null;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification!.title,
      message.notification!.body,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await requestNotificationPermission();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  if (!kIsWeb) {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(settings: settings);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String status = "Memulai";
  String topic = "berita";

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    try {
      final fcmToken = kIsWeb
          ? await messaging.getToken(vapidKey: webVapidKey)
          : await messaging.getToken();
      debugPrint("FCM Token: $fcmToken");

      if (fcmToken == null) {
        setState(() {
          status = "Gagal mendapatkan token FCM";
        });
      }
    } catch (e) {
      setState(() {
        status = "Error token FCM: $e";
      });
      debugPrint("Error getToken: $e");
    }

    messaging.onTokenRefresh.listen((token) {
      debugPrint("FCM token refreshed: $token");
    });

    if (!kIsWeb) {
      await messaging.subscribeToTopic(topic);
      setState(() {
        status = "Subscribe to topic $topic";
      });
    } else {
      setState(() {
        status = "Web siap menerima notifikasi";
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        showNotificationFromData(message.data);
      } else {
        showBasicNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cepu App",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomeScreen();
          } else {
            return const SignInScreen();
          }
        },
      ),
    );
  }
}
