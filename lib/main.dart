import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/secure_storage.dart';

import 'views/feed/home_screen.dart';
import 'views/jobs/jobs_screen.dart';
import 'views/post/create_post_screen.dart';
import 'views/events/events_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/feed/notification_screen.dart';
import 'views/login/signin_screen.dart';

// 🔥 GLOBAL ROUTE OBSERVER
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeService.themeMode,
            theme: themeService.lightTheme,
            darkTheme: themeService.currentTheme == AppTheme.navy
                ? themeService.navyTheme
                : themeService.darkTheme,
            navigatorObservers: [routeObserver], // 🔥 ATTACH OBSERVER
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
    final accessToken = await AppSecureStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      _goToLogin();
      return;
    }

    final me = await _authService.getMe();

    if (me != null) {
      _goToHome();
      return;
    }

    final refreshed = await _authService.refreshAccessToken();

    if (refreshed != null) {
      _goToHome();
    } else {
      _goToLogin();
    }
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
