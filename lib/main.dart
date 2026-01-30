import 'dart:ui'; // For PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/theme_service.dart';
import 'services/job_provider.dart';
import 'services/auth_service.dart';
import 'services/secure_storage.dart';
import 'services/socket_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/presence_service.dart';

import 'views/feed/home_screen.dart';
import 'views/jobs/jobs_screen.dart';
import 'views/post/create_post_screen.dart';
import 'views/events/events_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/feed/notification_screen.dart';
import 'views/login/signin_screen.dart';
import 'views/notification_wrapper.dart';

// 🔥 GLOBAL ROUTE OBSERVER
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// 🔑 GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 🔌 Disconnect on Background to show "Offline" status
      debugPrint("⏸️ App Paused/Detached - Disconnecting Socket");
      SocketService().disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // 🔌 Reconnect to show "Online" status
      debugPrint("▶️ App Resumed - Reconnecting Socket");
      _reconnectSocket();
    }
  }

  Future<void> _reconnectSocket() async {
    final token = await AppSecureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      // Explicitly connect (idempotent inside service)
      SocketService().connect(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeService.themeMode,
            theme: themeService.lightTheme,
            darkTheme: themeService.currentTheme == AppTheme.navy
                ? themeService.navyTheme
                : themeService.darkTheme,
            navigatorKey: navigatorKey, // 🔑 Attach Global Key
            navigatorObservers: [routeObserver], // 🔥 ATTACH OBSERVER
            builder: (context, child) {
              return NotificationWrapper(child: child);
            },
            home: const AuthGate(),
            routes: {
              '/feed': (_) => const HomeScreen(),
              '/jobs': (_) => const JobsScreen(),
              '/add': (_) => const CreatePostScreen(),
              '/events': (_) => const EventsScreen(),
              '/profile': (_) => const ProfileScreen(),
              '/notifications': (_) => const NotificationScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final accessToken = await AppSecureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        _goToLogin();
        return;
      }

      final me = await _authService.getMe();

      if (me != null) {
        // 🔥 First, init services (Notification, Chat, Presence) so they are listening
        _initServices();

        // 🔌 Connect Socket explicitly (it will handle single instance)
        SocketService().connect(accessToken);
        _goToHome();
        return;
      }

      final refreshed = await _authService.refreshAccessToken();

      if (refreshed != null) {
        _initServices();
        SocketService().connect(refreshed);
        _goToHome();
      } else {
        _goToLogin();
      }
    } catch (e) {
      debugPrint("⚠️ Auth Check Failed (Storage/Network): $e");
      // Fallback to login on error (e.g. storage corruption)
      _goToLogin();
    }
  }

  /// Ensure services are listening to sockets even if UI isn't open
  void _initServices() {
    NotificationService();
    ChatService();
    PresenceService();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
