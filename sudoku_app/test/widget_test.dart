import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/core/services/storage_service.dart';
import 'package:sudoku_app/core/l10n/app_localizations.dart';
import 'package:sudoku_app/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:sudoku_app/features/home/presentation/screens/home_screen.dart';

void main() {
  group('Widget tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });

    testWidgets('SplashScreen builds and displays',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      // Advance timers so none remain pending (Splash 1.5s, then transition)
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('SplashScreen animation: shows SudoQ and Zen Sudoku Puzzle',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      // Initial frame (animation at 0)
      await tester.pump();
      expect(find.text('SudoQ'), findsOneWidget);
      expect(find.text('Zen Sudoku Puzzle'), findsOneWidget);
      // Advance animation: ~400ms (fade/scale mid-way)
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('SudoQ'), findsOneWidget);
      // Advance to animation end (~1200ms total)
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('SudoQ'), findsOneWidget);
      expect(find.text('Zen Sudoku Puzzle'), findsOneWidget);
      // Consume splash navigation timer so no pending timers at test end
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('HomeScreen builds within ProviderScope and localizations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: supportedLocales,
            locale: Locale('en'),
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('HomeScreen shows scaffold and content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: supportedLocales,
            locale: Locale('en'),
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
