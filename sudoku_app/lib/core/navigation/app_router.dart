import 'package:go_router/go_router.dart';

import '../models/achievement.dart';
import '../models/leaderboard_user.dart';
import '../models/level_system.dart';
import '../navigation/app_route_observer.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/battle/presentation/screens/battle_lobby_screen.dart';
import '../../features/battle/presentation/screens/matchmaking_screen.dart';
import '../../features/battle/presentation/screens/battle_game_screen.dart';
import '../../features/battle/presentation/screens/battle_result_screen.dart';
import '../../features/battle/presentation/screens/duel_rewards_screen.dart';
import '../../features/daily/presentation/screens/daily_challenge_screen.dart';
import '../../features/daily/presentation/screens/trophy_room_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/leaderboard/presentation/screens/user_profile_screen.dart';
import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/level/presentation/screens/level_progress_screen.dart';
import '../../features/level/presentation/screens/rewards_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../features/tutorial/presentation/screens/tutorial_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/experience_screen.dart';
import '../../features/onboarding/presentation/screens/permission_screen.dart';

/// Named route paths — single source of truth for all navigation.
abstract class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const game = '/home/game';
  static const duelLobby = '/home/duel';
  static const matchmaking = '/home/duel/matchmaking';
  static const battleGame = '/home/duel/battle';
  static const battleResult = '/home/duel/result';
  static const duelRewards = '/home/duel/rewards';
  static const daily = '/home/daily';
  static const trophyRoom = '/home/daily/trophies';
  static const leaderboard = '/leaderboard';
  static const userProfile = '/leaderboard/user';
  static const achievements = '/achievements';
  static const levelProgress = '/level';
  static const rewards = '/level/rewards';
  static const settings = '/settings';
  static const subscription = '/subscription';
  static const tutorial = '/tutorial';
  static const welcome = '/welcome';
  static const experience = '/experience';
  static const permissions = '/permissions';
}

/// Extra data container for LevelProgressScreen navigation.
class LevelProgressExtra {
  final int xpEarned;
  final UserLevelData previousLevelData;
  final UserLevelData newLevelData;
  final String difficulty;
  final Duration completionTime;
  final int mistakes;
  final bool isDailyChallenge;
  final bool isRanked;
  final List<Achievement> newAchievements;
  final int achievementXp;
  final double xpBoostMultiplier;
  final bool isPremiumXpBoost;
  final List<GameXpBreakdownEntry> gameXpBreakdown;
  final void Function() onContinue;

  const LevelProgressExtra({
    required this.xpEarned,
    required this.previousLevelData,
    required this.newLevelData,
    required this.difficulty,
    required this.completionTime,
    required this.mistakes,
    required this.isDailyChallenge,
    required this.isRanked,
    this.newAchievements = const [],
    this.achievementXp = 0,
    this.xpBoostMultiplier = 1.0,
    this.isPremiumXpBoost = false,
    this.gameXpBreakdown = const [],
    required this.onContinue,
  });
}

/// Extra data container for BattleResultScreen navigation.
class BattleResultExtra {
  final String battleId;
  final Duration completionTime;
  final int mistakes;
  final String? forcedResult;
  final int? eloChange;
  final int? startElo;
  final int? newElo;
  final String? rankUpFrom;
  final String? rankUpTo;

  const BattleResultExtra({
    required this.battleId,
    required this.completionTime,
    required this.mistakes,
    this.forcedResult,
    this.eloChange,
    this.startElo,
    this.newElo,
    this.rankUpFrom,
    this.rankUpTo,
  });
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  observers: [appRouteObserver],
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        return HomeScreen(initialTab: int.tryParse(tab ?? '0') ?? 0);
      },
      routes: [
        GoRoute(
          path: 'game',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return GameScreen(
              difficulty: extra?['difficulty'] as String?,
              isNewGame: extra?['isNewGame'] as bool? ?? true,
              isDailyChallenge: extra?['isDailyChallenge'] as bool? ?? false,
              dailyChallengeDate: extra?['dailyChallengeDate'] as DateTime?,
            );
          },
        ),
        GoRoute(
          path: 'duel',
          builder: (context, state) => const BattleLobbyScreen(),
          routes: [
            GoRoute(
              path: 'matchmaking',
              builder: (context, state) => const MatchmakingScreen(),
            ),
            GoRoute(
              path: 'battle',
              builder: (context, state) {
                final battleId = state.extra as String? ?? '';
                return BattleGameScreen(battleId: battleId);
              },
            ),
            GoRoute(
              path: 'result',
              builder: (context, state) {
                final extra = state.extra as BattleResultExtra;
                return BattleResultScreen(
                  battleId: extra.battleId,
                  completionTime: extra.completionTime,
                  mistakes: extra.mistakes,
                  forcedResult: extra.forcedResult,
                  eloChange: extra.eloChange,
                  startElo: extra.startElo,
                  newElo: extra.newElo,
                  rankUpFrom: extra.rankUpFrom,
                  rankUpTo: extra.rankUpTo,
                );
              },
            ),
            GoRoute(
              path: 'rewards',
              builder: (context, state) => const DuelRewardsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'daily',
          builder: (context, state) => const DailyChallengeScreen(),
          routes: [
            GoRoute(
              path: 'trophies',
              builder: (context, state) => const TrophyRoomScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.leaderboard,
      builder: (context, state) => const LeaderboardScreen(),
      routes: [
        GoRoute(
          path: 'user',
          builder: (context, state) {
            final user = state.extra as LeaderboardUser;
            return UserProfileScreen(user: user);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.achievements,
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: AppRoutes.levelProgress,
      builder: (context, state) {
        final extra = state.extra as LevelProgressExtra;
        return LevelProgressScreen(
          xpEarned: extra.xpEarned,
          previousLevelData: extra.previousLevelData,
          newLevelData: extra.newLevelData,
          difficulty: extra.difficulty,
          completionTime: extra.completionTime,
          mistakes: extra.mistakes,
          isDailyChallenge: extra.isDailyChallenge,
          isRanked: extra.isRanked,
          newAchievements: extra.newAchievements,
          achievementXp: extra.achievementXp,
          xpBoostMultiplier: extra.xpBoostMultiplier,
          isPremiumXpBoost: extra.isPremiumXpBoost,
          gameXpBreakdown: extra.gameXpBreakdown,
          onContinue: extra.onContinue,
        );
      },
      routes: [
        GoRoute(
          path: 'rewards',
          builder: (context, state) => const RewardsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.subscription,
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: AppRoutes.tutorial,
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.experience,
      builder: (context, state) => const ExperienceScreen(),
    ),
    GoRoute(
      path: AppRoutes.permissions,
      builder: (context, state) => const PermissionScreen(),
    ),
  ],
);
