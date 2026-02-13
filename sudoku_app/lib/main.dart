import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_manager.dart';
import 'core/services/storage_service.dart';
import 'core/services/ads_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/level_service.dart';
import 'core/services/achievement_service.dart';
import 'core/services/daily_challenge_service.dart';
import 'core/services/global_stats_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/local_duel_stats_service.dart';
import 'core/providers/app_providers.dart';
import 'core/l10n/app_localizations.dart';
import 'core/navigation/app_route_observer.dart';

import 'features/onboarding/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (app will continue): $e');
  }

  await StorageService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SudokuApp(),
    ),
  );

  // Initialize services in background
  _initBackgroundServices();
}

/// Initialize services in background - optimized for performance
Future<void> _initBackgroundServices() async {
  // Wait for UI to settle first
  await Future.delayed(const Duration(milliseconds: 800));

  // Phase 1: Essential services (fast)
  try {
    await AppThemeManager.init();
    await LevelService.init();
    await LocalDuelStatsService.init();
  } catch (e) {
    debugPrint('Phase 1 init error: $e');
  }

  // Small break to let UI breathe
  await Future.delayed(const Duration(milliseconds: 300));

  // Phase 2: Game services
  try {
    await AchievementService.init();
    await DailyChallengeService.init();
  } catch (e) {
    debugPrint('Phase 2 init error: $e');
  }

  // Another break
  await Future.delayed(const Duration(milliseconds: 300));

  // Phase 3: Stats and sound
  try {
    await GlobalStatsService.instance.init();
    await SoundService().init();
  } catch (e) {
    debugPrint('Phase 3 init error: $e');
  }

  // Phase 4: Heavy services (AdMob, Purchase) - delayed more
  await Future.delayed(const Duration(seconds: 2));

  try {
    await AdsService.init();
  } catch (e) {
    debugPrint('Ads init error: $e');
  }

  try {
    await PurchaseService.init();
  } catch (e) {
    debugPrint('Purchase init error: $e');
  }
}

class SudokuApp extends ConsumerStatefulWidget {
  const SudokuApp({super.key});

  @override
  ConsumerState<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends ConsumerState<SudokuApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    AppThemeManager.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppThemeManager.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final currentTheme = AppThemeManager.currentTheme;

    // Determine locale based on settings
    Locale? appLocale;
    if (settings.languageCode.isNotEmpty) {
      appLocale = Locale(settings.languageCode);
    }

    // Determine theme
    ThemeData theme;
    ThemeData darkTheme;
    ThemeMode themeMode;

    if (currentTheme == AppThemeType.champion) {
      // Champion's Glory - Premium warm gold
      theme = AppThemeManager.getThemeData(context);
      darkTheme = AppTheme.darkTheme;
      themeMode = ThemeMode.light; // Force light for premium theme
    } else if (currentTheme == AppThemeType.grandmaster) {
      // Grandmaster Prestige - Premium lavender
      theme = AppThemeManager.getThemeData(context);
      darkTheme = AppTheme.darkTheme;
      themeMode = ThemeMode.light; // Force light for premium theme
    } else {
      // Normal theme: derive themeMode from current theme selection (not settings)
      theme = AppTheme.lightTheme;
      darkTheme = AppTheme.darkTheme;
      if (currentTheme == AppThemeType.dark) {
        themeMode = ThemeMode.dark;
      } else if (currentTheme == AppThemeType.light) {
        themeMode = ThemeMode.light;
      } else {
        themeMode = ThemeMode.system;
      }
    }

    return MaterialApp(
      title: 'SudoQ',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      navigatorObservers: [appRouteObserver],
      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: appLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (appLocale != null) {
          return appLocale;
        }
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('en');
      },

      home: const SplashScreen(),
    );
  }
}
