import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  static AppThemeType _currentTheme = AppThemeType.light;
  static final ValueNotifier<AppThemeType> themeNotifier =
      ValueNotifier(AppThemeType.light);

  /// Initialize theme manager
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(_themeKey);
    if (savedTheme != null) {
      _currentTheme = AppThemeType.values.firstWhere(
        (t) => t.name == savedTheme,
        orElse: () => AppThemeType.light,
      );
      if (_currentTheme == AppThemeType.system) {
        _currentTheme = AppThemeType.light;
        await _prefs?.setString(_themeKey, AppThemeType.light.name);
      }
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
        final isDark = platformBrightness ??
            (SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
        return isDark ? _darkTheme : _lightTheme;
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
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? AppThemeColors.dark() : AppThemeColors.light();
    }
  }

  // ========== THEME DATA ==========
  // All themes build on AppTheme base to ensure M3 + full component theme consistency

  static ThemeData get _lightTheme => AppTheme.lightTheme;

  static ThemeData get _darkTheme => AppTheme.darkTheme;

  // Champion's Glory – warm gold, inherits full M3 theme from AppTheme.lightTheme
  static ThemeData get _championTheme => AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFFFFDF5),
        cardColor: const Color(0xFFFFFEFA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB8860B),
          secondary: Color(0xFFD4A84B),
          surface: Color(0xFFFFFEFA),
          onPrimary: Colors.white,
          onSurface: Color(0xFF5D4E37),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: const Color(0xFF5D4E37).withValues(alpha: 0.12),
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8A6800),
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8A6800),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
            side: const BorderSide(color: Color(0xFF8A6800)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8A6800),
            textStyle: const TextStyle(letterSpacing: 0.3),
          ),
        ),
      );

  // Grandmaster Prestige – violet, inherits full M3 theme from AppTheme.lightTheme
  static ThemeData get _grandmasterTheme => AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        cardColor: const Color(0xFFFDFCFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6B5B95),
          secondary: Color(0xFF8E7CC3),
          surface: Color(0xFFFDFCFF),
          onPrimary: Colors.white,
          onSurface: Color(0xFF3D3551),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: const Color(0xFF3D3551).withValues(alpha: 0.1),
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A35AD),
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6A35AD),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
            side: const BorderSide(color: Color(0xFF6A35AD)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6A35AD),
            textStyle: const TextStyle(letterSpacing: 0.3),
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
        textSecondary: Color(0xFFB0AEA9),
        textMuted: Color(0xFF908F94),
        accent: Color(0xFF9496D8),
        accentSecondary: Color(0xFF8574A4),
        accentLight: Color(0xFF35343A),
        buttonPrimary: Color(0xFF6568BC),
        buttonSecondary: Color(0xFF35343A),
        buttonText: Color(0xFFFFFFFF),
        iconPrimary: Color(0xFF9496D8),
        iconSecondary: Color(0xFFB0AEA9),
        highlight: Color(0xFF35343A),
        success: Color(0xFF4CAF82),
        warning: Color(0xFFE8A840),
        divider: Color(0xFF3A393E),
        shimmer: Color(0xFF3A393E),
        progressBackground: Color(0xFF3A393E),
        navBarBackground: Color(0xFF252429),
        navBarSelected: Color(0xFF9496D8),
        navBarUnselected: Color(0xFFB0AEA9),
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
        textPrimary: Color(0xFF4A3C26),
        textSecondary: Color(0xFF6D5210),
        textMuted: Color(0xFF7E6720),
        accent: Color(0xFF8E6C00),
        accentSecondary: Color(0xFF9A7400),
        accentLight: Color(0xFFFFE680),
        buttonPrimary: Color(0xFF8A6800),
        buttonSecondary: Color(0xFFFFE066),
        buttonText: Color(0xFFFFFFFF),
        iconPrimary: Color(0xFF8E6C00),
        iconSecondary: Color(0xFF7E6720),
        highlight: Color(0xFFFFE680),
        success: Color(0xFF4A7A2E),
        warning: Color(0xFFB84600),
        divider: Color(0xFFE6C866),
        shimmer: Color(0xFFFFD700),
        progressBackground: Color(0xFFDAC280),
        navBarBackground: Color(0xFFFFF4CC),
        navBarSelected: Color(0xFF8A6800),
        navBarUnselected: Color(0xFF7E6720),
        isDark: false,
      );

  /// 👑 Grandmaster Prestige - Premium violet theme (MORE VIBRANT)
  factory AppThemeColors.grandmaster() => const AppThemeColors(
        background: Color(0xFFF3EEFF),
        backgroundGradientStart: Color(0xFFE8DEFF),
        backgroundGradientEnd: Color(0xFFD4C4F0),
        card: Color(0xFFF8F4FF),
        cardBorder: Color(0xFF7E49C4),
        cardShadow: Color(0x407E49C4),
        textPrimary: Color(0xFF2D1F4A),
        textSecondary: Color(0xFF553D85),
        textMuted: Color(0xFF7559A0),
        accent: Color(0xFF7540B8),
        accentSecondary: Color(0xFF9060D0),
        accentLight: Color(0xFFD4BFFF),
        buttonPrimary: Color(0xFF6A35AD),
        buttonSecondary: Color(0xFFD4BFFF),
        buttonText: Color(0xFFFFFFFF),
        iconPrimary: Color(0xFF7540B8),
        iconSecondary: Color(0xFF7559A0),
        highlight: Color(0xFFE8DEFF),
        success: Color(0xFF2E7D32),
        warning: Color(0xFFC23510),
        divider: Color(0xFFC9A8FF),
        shimmer: Color(0xFFB388FF),
        progressBackground: Color(0xFFBFA8E0),
        navBarBackground: Color(0xFFE8DEFF),
        navBarSelected: Color(0xFF6A35AD),
        navBarUnselected: Color(0xFF7559A0),
        isDark: false,
      );

  /// Get gradient for backgrounds
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundGradientStart, backgroundGradientEnd],
      );
}
