import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// App-wide theme types
enum AppThemeType {
  system, // Follow system dark/light
  light, // Force light mode
  dark, // Force dark mode
  champion, // Champion's Glory - Premium warm gold
  grandmaster, // Grandmaster Prestige - Premium lavender
}

/// Manages app-wide theming
class AppThemeManager {
  static const String _themeKey = 'app_theme_type';
  static SharedPreferences? _prefs;
  static AppThemeType _currentTheme = AppThemeType.system;
  static final ValueNotifier<AppThemeType> themeNotifier =
      ValueNotifier(AppThemeType.system);

  /// Initialize theme manager
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(_themeKey);
    if (savedTheme != null) {
      _currentTheme = AppThemeType.values.firstWhere(
        (t) => t.name == savedTheme,
        orElse: () => AppThemeType.system,
      );
    }
    themeNotifier.value = _currentTheme;
  }

  /// Get current theme type
  static AppThemeType get currentTheme => _currentTheme;

  /// Set theme type
  static Future<void> setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    themeNotifier.value = theme;
    await _prefs?.setString(_themeKey, theme.name);
  }

  /// Check if using premium ranked theme
  static bool get isRankedTheme =>
      _currentTheme == AppThemeType.champion ||
      _currentTheme == AppThemeType.grandmaster;

  /// Get ThemeData for current theme
  static ThemeData getThemeData(BuildContext context,
      {bool? platformBrightness}) {
    switch (_currentTheme) {
      case AppThemeType.light:
        return _lightTheme;
      case AppThemeType.dark:
        return _darkTheme;
      case AppThemeType.champion:
        return _championTheme;
      case AppThemeType.grandmaster:
        return _grandmasterTheme;
      case AppThemeType.system:
        final brightness =
            platformBrightness == true ? Brightness.dark : Brightness.light;
        return brightness == Brightness.dark ? _darkTheme : _lightTheme;
    }
  }

  /// Get app colors for current theme
  static AppThemeColors get colors {
    switch (_currentTheme) {
      case AppThemeType.light:
        return AppThemeColors.light();
      case AppThemeType.dark:
        return AppThemeColors.dark();
      case AppThemeType.champion:
        return AppThemeColors.champion();
      case AppThemeType.grandmaster:
        return AppThemeColors.grandmaster();
      case AppThemeType.system:
        return AppThemeColors.light();
    }
  }

  // ========== THEME DATA ==========

  static ThemeData get _lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F5F2),
        cardColor: const Color(0xFFFDFCF9),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5558A8),
          secondary: Color(0xFF6D5B8A),
          surface: Color(0xFFFDFCF9),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: const Color(0xFF2C2B30).withValues(alpha: 0.08),
          shape:
              const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
      );

  static ThemeData get _darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF1C1B1F),
        cardColor: const Color(0xFF252429),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B7EC7),
          secondary: Color(0xFF6D5B8A),
          surface: Color(0xFF252429),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
      );

  // Champion's Glory – handcrafted buttons & cards
  static ThemeData get _championTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFFFFDF5),
        cardColor: const Color(0xFFFFFEFA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB8860B),
          secondary: Color(0xFFD4A84B),
          surface: Color(0xFFFFFEFA),
          onPrimary: Colors.white,
          onSurface: Color(0xFF5D4E37),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: const Color(0xFF5D4E37).withValues(alpha: 0.12),
          shape:
              const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
      );

  // Grandmaster Prestige – handcrafted buttons & cards
  static ThemeData get _grandmasterTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        cardColor: const Color(0xFFFDFCFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6B5B95),
          secondary: Color(0xFF8E7CC3),
          surface: Color(0xFFFDFCFF),
          onPrimary: Colors.white,
          onSurface: Color(0xFF3D3551),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: const Color(0xFF3D3551).withValues(alpha: 0.1),
          shape:
              const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
      );
}

/// Custom color palette for each theme
class AppThemeColors {
  final Color background;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;
  final Color card;
  final Color cardBorder;
  final Color cardShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSecondary;
  final Color accentLight;
  final Color buttonPrimary;
  final Color buttonSecondary;
  final Color buttonText;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color highlight;
  final Color success;
  final Color warning;
  final Color divider;
  final Color shimmer;
  final Color progressBackground;
  final Color navBarBackground;
  final Color navBarSelected;
  final Color navBarUnselected;
  final bool isDark;

  const AppThemeColors({
    required this.background,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSecondary,
    required this.accentLight,
    required this.buttonPrimary,
    required this.buttonSecondary,
    required this.buttonText,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.highlight,
    required this.success,
    required this.warning,
    required this.divider,
    required this.shimmer,
    required this.progressBackground,
    required this.navBarBackground,
    required this.navBarSelected,
    required this.navBarUnselected,
    required this.isDark,
  });

  /// Light theme colors – warm, handcrafted palette
  factory AppThemeColors.light() => const AppThemeColors(
        background: Color(0xFFF6F5F2),
        backgroundGradientStart: Color(0xFFEDEBE6),
        backgroundGradientEnd: Color(0xFFF2F0EB),
        card: Color(0xFFFDFCF9),
        cardBorder: Color(0xFFE5E3DE),
        cardShadow: Color(0x1A2C2B30),
        textPrimary: Color(0xFF2C2B30),
        textSecondary: Color(0xFF5E5D64),
        textMuted: Color(0xFF8E8D92),
        accent: Color(0xFF5558A8),
        accentSecondary: Color(0xFF6D5B8A),
        accentLight: Color(0xFFE5E4F0),
        buttonPrimary: Color(0xFF5558A8),
        buttonSecondary: Color(0xFFE5E4F0),
        buttonText: Color(0xFFFFFFFF),
        iconPrimary: Color(0xFF5558A8),
        iconSecondary: Color(0xFF8E8D92),
        highlight: Color(0xFFE8E6F2),
        success: Color(0xFF2E8B6C),
        warning: Color(0xFFD4942E),
        divider: Color(0xFFE5E3DE),
        shimmer: Color(0xFFE0DED9),
        progressBackground: Color(0xFFE0DED9),
        navBarBackground: Color(0xFFFDFCF9),
        navBarSelected: Color(0xFF5558A8),
        navBarUnselected: Color(0xFF5E5D64),
        isDark: false,
      );

  /// Dark theme colors – soft charcoal, handcrafted
  factory AppThemeColors.dark() => const AppThemeColors(
        background: Color(0xFF1C1B1F),
        backgroundGradientStart: Color(0xFF1C1B1F),
        backgroundGradientEnd: Color(0xFF252429),
        card: Color(0xFF2A292E),
        cardBorder: Color(0xFF3A393E),
        cardShadow: Color(0x40000000),
        textPrimary: Color(0xFFE8E6E3),
        textSecondary: Color(0xFFA8A6A3),
        textMuted: Color(0xFF6E6D72),
        accent: Color(0xFF7B7EC7),
        accentSecondary: Color(0xFF6D5B8A),
        accentLight: Color(0xFF35343A),
        buttonPrimary: Color(0xFF7B7EC7),
        buttonSecondary: Color(0xFF35343A),
        buttonText: Color(0xFFFFFFFF),
        iconPrimary: Color(0xFF7B7EC7),
        iconSecondary: Color(0xFFA8A6A3),
        highlight: Color(0xFF35343A),
        success: Color(0xFF2E8B6C),
        warning: Color(0xFFD4942E),
        divider: Color(0xFF3A393E),
        shimmer: Color(0xFF3A393E),
        progressBackground: Color(0xFF3A393E),
        navBarBackground: Color(0xFF252429),
        navBarSelected: Color(0xFF7B7EC7),
        navBarUnselected: Color(0xFFA8A6A3),
        isDark: true,
      );

  /// 🏆 Champion's Glory - Premium warm gold theme (MORE VIBRANT)
  factory AppThemeColors.champion() => const AppThemeColors(
        background: Color(0xFFFFF9E6),
        backgroundGradientStart: Color(0xFFFFF4CC),
        backgroundGradientEnd: Color(0xFFFFE8A3),
        card: Color(0xFFFFFCF0),
        cardBorder: Color(0xFFDAA520),
        cardShadow: Color(0x40DAA520),
        textPrimary: Color(0xFF5D4E37),
        textSecondary: Color(0xFF8B6914),
        textMuted: Color(0xFFA68B3D),
        accent: Color(0xFFDAA520),
        accentSecondary: Color(0xFFFFD700),
        accentLight: Color(0xFFFFE680),
        buttonPrimary: Color(0xFFDAA520),
        buttonSecondary: Color(0xFFFFE066),
        buttonText: Color(0xFF3D2E1A),
        iconPrimary: Color(0xFFDAA520),
        iconSecondary: Color(0xFFB8960B),
        highlight: Color(0xFFFFE680),
        success: Color(0xFF7CB342),
        warning: Color(0xFFFF8F00),
        divider: Color(0xFFE6C866),
        shimmer: Color(0xFFFFD700),
        progressBackground: Color(0xFFDAC280),
        navBarBackground: Color(0xFFFFF4CC),
        navBarSelected: Color(0xFFDAA520),
        navBarUnselected: Color(0xFFA68B3D),
        isDark: false,
      );

  /// 👑 Grandmaster Prestige - Premium violet theme (MORE VIBRANT)
  factory AppThemeColors.grandmaster() => const AppThemeColors(
        background: Color(0xFFF3EEFF),
        backgroundGradientStart: Color(0xFFE8DEFF),
        backgroundGradientEnd: Color(0xFFD4C4F0),
        card: Color(0xFFF8F4FF),
        cardBorder: Color(0xFF9C6ADE),
        cardShadow: Color(0x409C6ADE),
        textPrimary: Color(0xFF3D2E5A),
        textSecondary: Color(0xFF6B4D9E),
        textMuted: Color(0xFF8E72B8),
        accent: Color(0xFF9C6ADE),
        accentSecondary: Color(0xFFB388FF),
        accentLight: Color(0xFFD4BFFF),
        buttonPrimary: Color(0xFF9C6ADE),
        buttonSecondary: Color(0xFFD4BFFF),
        buttonText: Color(0xFFFFFFFF),
        iconPrimary: Color(0xFF9C6ADE),
        iconSecondary: Color(0xFF7E57C2),
        highlight: Color(0xFFE8DEFF),
        success: Color(0xFF66BB6A),
        warning: Color(0xFFFFAB40),
        divider: Color(0xFFC9A8FF),
        shimmer: Color(0xFFB388FF),
        progressBackground: Color(0xFFBFA8E0),
        navBarBackground: Color(0xFFE8DEFF),
        navBarSelected: Color(0xFF9C6ADE),
        navBarUnselected: Color(0xFF8E72B8),
        isDark: false,
      );

  /// Get gradient for backgrounds
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundGradientStart, backgroundGradientEnd],
      );
}
