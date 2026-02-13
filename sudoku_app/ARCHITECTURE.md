# Architecture Documentation

## Overview

**SudoQ** is a Flutter Sudoku app with **feature-based architecture**, Riverpod for state management, and Firebase for auth/sync. There is no repository layer; services are used directly and exposed via `app_providers.dart` where needed.

## Architecture Layers

### 1. Core Layer (`lib/core/`)

#### Services (`core/services/`)
| Service | Role |
|--------|------|
| **StorageService** | SharedPreferences wrapper; settings, statistics, current game, first-launch flag |
| **AdsService** | AdMob: banner, interstitial, rewarded (daily bonus, second chance, XP boost); init, shouldShowAds, onAdsFreeActivated |
| **PurchaseService** | In-App Purchase (ads-free); init, restore, purchase flow; integrates with AdsService |
| **SoundService** | Audio playback for game events (correct, wrong, complete, etc.) |
| **SudokuGenerator** | Puzzle generation by difficulty (Beginner–Expert, Daily Challenge); hint, fast-pencil logic |
| **LevelService** | XP, levels, cosmetic frames; addBonusXp, selectedFrameId |
| **AchievementService** | Achievements data, unlock, checkAfterWin, checkAfterDuelWin |
| **DailyChallengeService** | Daily puzzle generation and completion tracking |
| **BattleService** | Real-time duel: matchmaking, game state, Firestore |
| **LocalDuelStatsService** | Local ELO/duel stats (wins, losses, division) |
| **GlobalStatsService** | Global stats aggregation |
| **AuthService** | Firebase Auth + Google Sign-In |
| **UserSyncService** | Sync user profile and achievements to Firestore |

#### Models (`core/models/`)
- **settings.dart** – AppSettings (theme, language, sound, vibration, difficulty, game options)
- **statistics.dart** – Statistics, DifficultyStats (games played/won, streaks, play time)
- **game_state.dart** – GameState for the active puzzle
- **achievement.dart** – Achievement definitions and progress
- **daily_challenge.dart** / **daily_challenge_system.dart** – Daily challenge data
- **level_system.dart** / **cosmetic_rewards.dart** – Level/XP and frame rewards
- **battle_models.dart** – Duel match, lobby, result models
- **leaderboard_user.dart** – Leaderboard entry
- **global_stats.dart** – Global stats DTOs

#### Providers (`core/providers/`)
- **app_providers.dart** – Riverpod providers: `settingsProvider`, `statisticsProvider`, `sudokuGeneratorProvider`, `unlockedAchievementsProvider`, `selectedFrameProvider`, etc. Backed by StorageService, LevelService, AchievementService.

#### Theme (`core/theme/`)
- **app_theme.dart** – Light/dark ThemeData
- **app_theme_manager.dart** – Current theme (including premium Champion/Grandmaster), persistence
- **app_colors.dart** – AppThemeColors, AppTextStyles

#### Other Core
- **l10n/app_localizations.dart** – In-app strings (11 locales: en, zh, hi, es, fr, ar, bn, pt, ru, ja, tr)
- **utils/responsive_utils.dart** – Responsive scaling (sp, w, wp, hp)
- **widgets/** – AnimatedFrame, CelebrationEffect
- **constants/app_constants.dart** – App-wide constants

### 2. Features Layer (`lib/features/`)

Each feature has **presentation/screens/** and optionally **presentation/widgets/**.

| Feature | Screens | Notes |
|---------|---------|--------|
| **onboarding** | SplashScreen, WelcomeScreen, ExperienceScreen | First launch vs returning user |
| **home** | HomeScreen | Tabs: Home, Duel, Profile; daily challenge card, quick start, how to play → Tutorial |
| **game** | GameScreen | Grid, number pad, timer, hints, fast pencil, complete dialog; widgets: SudokuGrid, NumberPad, GameActions, GameCompleteDialog |
| **daily** | DailyChallengeScreen, TrophyRoomScreen | Daily puzzle, calendar, monthly badge widget |
| **battle** | BattleLobbyScreen, MatchmakingScreen, BattleGameScreen, BattleResultScreen, DuelRewardsScreen | Real-time duel flow |
| **profile** | ProfileScreen | Level/XP card, stats, tabs: Daily, Duel, Achievements, Event |
| **leaderboard** | LeaderboardScreen, UserProfileScreen | Widget: LeaderboardTile |
| **achievements** | AchievementsScreen | List of achievements (AchievementService) |
| **level** | LevelProgressScreen, RewardsScreen | Level progress and frame rewards |
| **settings** | SettingsScreen | Theme, language, sound, vibration, game options, IAP restore, debug (unlock all / reset) |
| **subscription** | SubscriptionScreen | Premium / ads-free subscription UI |
| **tutorial** | TutorialScreen | How to play Sudoku |

### 3. App Entry (`lib/main.dart`)

- `main()`: Firebase init, StorageService init, orientation/UI overlay, `runApp(ProviderScope(child: SudokuApp()))`
- Background init (phased): AppThemeManager, LevelService, LocalDuelStatsService → AchievementService, DailyChallengeService → GlobalStatsService, SoundService → AdsService, PurchaseService
- **SudokuApp** (ConsumerStatefulWidget): theme from AppThemeManager + settingsProvider, locale from settings, `home: SplashScreen()`

## Key Technical Points

### Difficulty & Puzzle Generation
- **SudokuGenerator** produces puzzles per difficulty (Beginner–Expert) and daily seeds.
- Difficulty influences clue count and complexity; no separate DifficultyAnalyzer type in current code.

### IAP & Ads
- **PurchaseService**: one-time “ads-free” product; restore purchases; on success calls `AdsService.onAdsFreeActivated()`.
- **AdsService**: banner, interstitial, rewarded (daily bonus, second chance, XP boost); respects purchase state.

### State Management
- **Riverpod** only in `app_providers.dart` (and any feature-specific state in screens).
- No GameRepository/StorageRepository; UI and services use StorageService, LevelService, AchievementService, etc. directly.

### Firebase
- **Auth**: AuthService, Google Sign-In.
- **Firestore**: Battle (duels), UserSyncService (profile, achievements).
- See **DATABASE_ARCHITECTURE.md** for Firestore schema.

## Dependency Injection

Riverpod providers in `app_providers.dart`:

```dart
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(...);
final statisticsProvider = StateNotifierProvider<StatisticsNotifier, Statistics>(...);
final sudokuGeneratorProvider = Provider<SudokuGenerator>(...);
final unlockedAchievementsProvider = StateProvider<Set<String>>(...);
final selectedFrameProvider = StateProvider<String>(...);
// etc.
```

No `gameRepositoryProvider` or `storageRepositoryProvider`; game state is managed inside GameScreen and persisted via StorageService.

## Error Handling

- **PurchaseService**: network/retry, timeouts, platform-specific errors, user-facing messages.
- **Game generation**: try/catch, validation of generated puzzles (covered by tests).

## Testing

- Generator and game logic tests in `test/`: real_generator_test, sudoku_extensive_test, sudoku_generator_test, stress_test.
- Widget test: basic smoke in `widget_test.dart`.

## Code Quality

- Null safety, type safety, separation of concerns.
- No Learn/strategy module (removed); no repository layer in current codebase.
