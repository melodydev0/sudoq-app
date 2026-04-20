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
import 'core/services/auth_service.dart';
import 'core/services/entitlement_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'core/services/user_sync_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/providers/app_providers.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/gen_localizations.dart';
import 'core/navigation/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  NotificationService.registerBackgroundHandler();

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };

  runApp(const _BootstrapApp());
}

/// Minimal bootstrap - no MaterialApp, just a colored box
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Widget? _realApp;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Let the simple widget render first
      await Future.delayed(const Duration(milliseconds: 100));

      // Init storage
      await StorageService.init();

      // Wait for Firebase before continuing (required for all Firebase services)
      try {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
        debugPrint('Firebase initialized');
      } catch (e) {
        debugPrint('Firebase error: $e');
      }

      // Wait a frame before showing real app
      await Future.delayed(const Duration(milliseconds: 50));

      // Build real app
      if (mounted) {
        setState(() {
          _realApp = const ProviderScope(child: SudokuApp());
        });
      }

      // Background services - start after Firebase is ready
      // Remote Config first (needs Firebase) so A/B variant is ready before paywall opens
      Future.delayed(const Duration(milliseconds: 800), _initServicesLater);
      RemoteConfigService.init().ignore();
    } catch (e) {
      debugPrint('Bootstrap error: $e');
      // Still show the app even if bootstrap partially failed
      if (mounted && _realApp == null) {
        setState(() {
          _realApp = const ProviderScope(child: SudokuApp());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If real app is ready, show it
    if (_realApp != null) return _realApp!;

    // Minimal loading - just gradient background matching splash screen
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
    );
  }
}

Future<void> _initServicesLater() async {
  // Firebase is already initialized at this point

  try { await AppThemeManager.init(); } catch (_) {}
  try { await LevelService.init(); } catch (_) {}
  try { await LocalDuelStatsService.init(); } catch (_) {}

  await Future.delayed(const Duration(milliseconds: 500));

  try { await AchievementService.init(); } catch (_) {}
  try { await DailyChallengeService.init(); } catch (_) {}

  await Future.delayed(const Duration(milliseconds: 500));

  try { await GlobalStatsService.instance.init(); } catch (_) {}
  try { await SoundService().init(); } catch (_) {}

  await Future.delayed(const Duration(seconds: 2));

  try { await AdsService.init(); } catch (_) {}
  try { await PurchaseService.init(); } catch (_) {}
  try { await EntitlementService.refreshFromCloud(); } catch (_) {}
  try { await NotificationService.init(); } catch (_) {}

  if (!AuthService.isSignedIn) {
    AuthService.signInAnonymously().ignore();
  }

  // Sync any pending offline ELO/XP changes to cloud
  UserSyncService.autoSync().ignore();

  // Refresh location silently for returning users who already granted permission
  if (LocationService.wasPermissionAsked) {
    LocationService.fetchAndSync().ignore();
  }
}

class SudokuApp extends ConsumerStatefulWidget {
  const SudokuApp({super.key});

  @override
  ConsumerState<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends ConsumerState<SudokuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    AppThemeManager.themeNotifier.addListener(_onThemeChanged);
    WidgetsBinding.instance.addObserver(this);

    EntitlementService.onPremiumChanged = (isPremium) {
      if (mounted) {
        ref.read(adsFreeProvider.notifier).state = isPremium;
      }
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppThemeManager.themeNotifier.removeListener(_onThemeChanged);
    EntitlementService.onPremiumChanged = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UserSyncService.autoSync().ignore();
      RemoteConfigService.refresh().ignore();
      EntitlementService.refreshFromCloud().then((_) {
        if (mounted) {
          ref.read(adsFreeProvider.notifier).state = StorageService.isAdsFree();
        }
      }).ignore();
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final currentTheme = AppThemeManager.currentTheme;

    Locale? appLocale;
    if (settings.languageCode.isNotEmpty) {
      appLocale = Locale(settings.languageCode);
    }

    // All themes are now handled uniformly through AppThemeManager.
    // Premium themes (champion/grandmaster) inherit from AppTheme.lightTheme via copyWith,
    // ensuring M3 and full component theme consistency.
    final ThemeData resolvedTheme = AppThemeManager.getThemeData(context);
    final ThemeData resolvedDarkTheme = AppTheme.darkTheme;
    final ThemeMode resolvedThemeMode;
    if (currentTheme == AppThemeType.dark) {
      resolvedThemeMode = ThemeMode.dark;
    } else if (currentTheme == AppThemeType.champion ||
        currentTheme == AppThemeType.grandmaster) {
      resolvedThemeMode = ThemeMode.light;
    } else {
      resolvedThemeMode = ThemeMode.light;
    }

    return MaterialApp.router(
      title: 'SudoQ',
      debugShowCheckedModeBanner: false,
      theme: resolvedTheme,
      darkTheme: resolvedDarkTheme,
      themeMode: resolvedThemeMode,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GenLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: appLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (appLocale != null) return appLocale;
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('en');
      },
    );
  }
}
