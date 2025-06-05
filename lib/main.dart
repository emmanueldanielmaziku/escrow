import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('🔄 Handling background message: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Setup system UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications setup
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // TODO: Handle tapped notification payload
      print('🔔 Notification tapped: ${response.payload}');
      
    },
  );

  // Android channel (required for Android 8.0+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel',
    'Default Channel',
    description: 'Default channel for app notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(const EscrowEngine());
}

class EscrowEngine extends StatefulWidget {
  const EscrowEngine({super.key});

  @override
  State<EscrowEngine> createState() => _EscrowEngineState();
}

class _EscrowEngineState extends State<EscrowEngine> {
  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions (especially for iOS)
    await messaging.requestPermission();

    // Get the device token
    final token = await messaging.getToken();
    print('🔑 FCM Token: $token');

    // Handle notifications when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Channel',
              channelDescription: 'Default notification channel',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data['payload'], // Optional payload
        );
      }
    });

    // Handle when app is opened via notification (background or terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App opened from notification: ${message.data}');
      // TODO: Navigate based on message.data or notification
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Escrow App',
        theme: ThemeData(
          fontFamily: 'ProductSanReg',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF22C55E),
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
        },
      ),
    );
  }
}
