import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppTheme { system, light, dark, navy }

class ThemeService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'selected_app_theme';

  AppTheme _currentTheme = AppTheme.system;

  ThemeService() {
    _loadTheme();
  }

  AppTheme get currentTheme => _currentTheme;

  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read(key: _themeKey);
    if (savedTheme != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => AppTheme.system,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _storage.write(key: _themeKey, value: theme.name);
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.navy:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme {
    const primaryColor = Color(0xFF5B6CFF);
    const onBackground = Color(0xFF111827);
    const onSurface = Color(0xFF1F2937);
    const subTextColor = Color(0xFF6B7280);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      primaryColor: primaryColor,
      cardColor: const Color(0xFFF8F9FB),
      dividerColor: const Color(0xFFE5E7EB),

      colorScheme: const ColorScheme.light(
        surface: Color(0xFFF8F9FB),
        onSurface: onSurface,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: Color(0xFF8F9BFF),
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surfaceContainer: Color(0xFFF8F9FB),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w900,
        ),
        displayMedium: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w900,
        ),
        displaySmall: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w900,
        ),
        headlineLarge: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: onSurface, fontSize: 16),
        bodyMedium: TextStyle(color: subTextColor, fontSize: 14),
        bodySmall: TextStyle(color: subTextColor, fontSize: 12),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onBackground),
        titleTextStyle: TextStyle(
          color: onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(color: onSurface),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData get darkTheme => _buildTheme(Brightness.dark);
  ThemeData get navyTheme => _buildTheme(Brightness.dark, isNavy: true);

  ThemeData _buildTheme(Brightness brightness, {bool isNavy = false}) {
    final bool isDark = brightness == Brightness.dark;
    const primaryColor = Color(0xFF6366F1);

    // Backgrounds
    final Color scaffoldBg;
    final Color surfaceColor;
    final Color cardColor;

    if (isNavy) {
      scaffoldBg = const Color(0xFF030712); // True deep navy
      surfaceColor = const Color(0xFF111827); // Surface navy
      cardColor = const Color(0xFF1F2937); // Lighter navy for cards
    } else {
      scaffoldBg = const Color(0xFF000000); // True black
      surfaceColor = const Color(0xFF121212); // Material dark surface
      cardColor = const Color(0xFF1E1E1E); // Dark grey card
    }

    const textColor = Colors.white;
    const subTextColor = Colors.white70;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        surface: surfaceColor,
        onSurface: textColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: Colors.white,
        outline: Colors.white10,
        surfaceContainer: cardColor,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: subTextColor, fontSize: 14),
        bodySmall: TextStyle(color: subTextColor, fontSize: 12),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: subTextColor.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: Colors.white10, thickness: 1),

      iconTheme: const IconThemeData(color: textColor),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
