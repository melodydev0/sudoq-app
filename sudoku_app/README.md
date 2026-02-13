# SudoQ – Zen Sudoku Puzzle

A relaxing brain-training Sudoku game built with Flutter 3.x. Features dynamic difficulty, daily challenges, real-time duels, XP/levels, achievements, and optional Firebase auth.

## Features

### Game
- **9×9 Sudoku** with difficulty levels (Beginner, Easy, Medium, Hard, Expert)
- **Daily Challenge** – one new puzzle per day; trophy room and monthly badges
- **Timer**, **mistake tracking**, **hints**, **fast pencil** (candidates)
- **Tutorial** – how to play (TutorialScreen)

### Progression & Social
- **Levels & XP** – earn XP, unlock cosmetic frames
- **Achievements** – in-app achievements with unlock tracking
- **Duel (Battle)** – real-time 1v1 with matchmaking, ELO, divisions (Bronze–Champion)
- **Leaderboard** – global and user profiles

### App Experience
- **Onboarding** – splash, welcome, experience screens
- **Home** – daily challenge card, quick start, “How to play”, daily bonus (rewarded ad)
- **Profile** – level card, stats, tabs: Daily, Duel, Achievements, Event
- **Settings** – theme (light/dark + premium themes), language (11 locales), sound, vibration, game options
- **Subscription** – ads-free purchase; restore purchases

### Monetization
- **AdsService** – banner, interstitial, rewarded (daily bonus, second chance, XP boost)
- **PurchaseService** – one-time “ads-free” IAP; restore supported

### Tech
- **Firebase** – Auth, Firestore (duels, user sync)
- **Riverpod** – state (settings, statistics, providers in `app_providers.dart`)
- **Localization** – 11 languages (en, zh, hi, es, fr, ar, bn, pt, ru, ja, tr)

## Setup

### Prerequisites
- Flutter 3.x
- Android SDK (API 21+)

### Install
```bash
flutter pub get
```

### AdMob (optional)
1. Create an AdMob app and get Ad Unit IDs.
2. In `lib/core/services/ads_service.dart` replace test IDs with your banner and interstitial (and rewarded) Ad Unit IDs.

### In-App Purchase (optional)
1. Create the “ads-free” product in Google Play Console.
2. In `lib/core/services/purchase_service.dart` set the product ID to match.

### Firebase (optional)
- Add `google-services.json` (Android) and configure `lib/firebase_options.dart` (e.g. via FlutterFire CLI).

### Run
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/       # app_constants.dart
│   ├── l10n/            # app_localizations.dart (11 locales)
│   ├── models/          # settings, statistics, game_state, achievement, daily, level, battle, leaderboard, global_stats
│   ├── providers/       # app_providers.dart (Riverpod: settings, statistics, sudokuGenerator, achievements, frame)
│   ├── services/        # storage, ads_service, purchase_service, sound, sudoku_generator, level, achievement,
│   │                    # daily_challenge, battle, local_duel_stats, global_stats, auth, user_sync
│   ├── theme/           # app_theme, app_theme_manager, app_colors
│   ├── utils/           # responsive_utils
│   └── widgets/         # animated_frame, celebration_effect
├── features/
│   ├── onboarding/      # splash_screen, welcome_screen, experience_screen
│   ├── home/            # home_screen, daily_challenge_card, difficulty_dialog
│   ├── game/            # game_screen, sudoku_grid, number_pad, game_actions, game_complete_dialog
│   ├── daily/           # daily_challenge_screen, trophy_room_screen, monthly_badge_widget
│   ├── battle/          # battle_lobby, matchmaking, battle_game, battle_result, duel_rewards_screen
│   ├── profile/         # profile_screen
│   ├── leaderboard/     # leaderboard_screen, user_profile_screen, leaderboard_tile
│   ├── achievements/    # achievements_screen
│   ├── level/           # level_progress_screen, rewards_screen
│   ├── settings/        # settings_screen
│   ├── subscription/    # subscription_screen
│   └── tutorial/        # tutorial_screen
├── firebase_options.dart
└── main.dart
```

## Architecture

- **Core**: services (storage, ads, purchase, sound, sudoku_generator, level, achievement, daily, battle, auth, sync), models, theme, l10n, Riverpod providers.
- **Features**: presentation-only (screens + widgets); each feature is self-contained under `features/<name>/presentation/`.
- **State**: Riverpod in `core/providers/app_providers.dart`; no repository layer – UI uses services and storage directly.

See **ARCHITECTURE.md** for detailed service list and design notes.  
See **DATABASE_ARCHITECTURE.md** for Firestore duel/user schema.

## Difficulty

Levels (Beginner → Expert) control clue count and puzzle complexity. Daily challenges use a date-based seed for a single puzzle per day.

## Testing

- Generator and puzzle tests: `real_generator_test.dart`, `sudoku_extensive_test.dart`, `sudoku_generator_test.dart`, `stress_test.dart`.
- Basic widget smoke test: `widget_test.dart`.

Use test Ad Unit IDs for emulator; IAP testing requires Google Play Console setup.

## License

Educational / personal use.
