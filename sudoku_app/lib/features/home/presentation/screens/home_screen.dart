import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../game/presentation/screens/game_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../../daily/presentation/screens/daily_challenge_screen.dart';
import '../../../battle/presentation/screens/battle_lobby_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  late int _selectedIndex;
  bool _isDailyBonusAvailable = false;
  bool _routeObserverSubscribed = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _checkDailyBonus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route != null) {
        appRouteObserver.subscribe(this, route);
        _routeObserverSubscribed = true;
      }
    }
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
      _routeObserverSubscribed = false;
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Returned to this screen (e.g. from Game) – refresh so "Continue" updates
    if (mounted) setState(() {});
  }

  Future<void> _checkDailyBonus() async {
    final available = await AdsService.isDailyBonusAvailable();
    if (mounted) {
      setState(() {
        _isDailyBonusAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;
    return Scaffold(
      backgroundColor: theme.backgroundGradientEnd,
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    // Lazy loading - only build active tab for better performance
    // 3 tabs: Home (0), Duel (1), Profile (2)
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        // Use ValueKey to rebuild when switching to this tab (for ELO animation)
        return BattleLobbyScreen(
            key: ValueKey('duel_${DateTime.now().millisecondsSinceEpoch}'));
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    ResponsiveUtils.init(context);
    // Use AppThemeManager for premium themes
    final theme = AppThemeManager.colors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.backgroundGradientStart, theme.backgroundGradientEnd],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).hello,
                          style: AppTextStyles.body(context,
                              color: theme.textSecondary),
                        ),
                        SizedBox(height: 4.w),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context).readyToPlay,
                            style: AppTextStyles.headline3(context,
                                color: theme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen()),
                      );
                    },
                    icon: Icon(Bootstrap.trophy, size: 22.w),
                    color: theme.iconPrimary,
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: Icon(Bootstrap.gear, size: 22.w),
                    color: theme.iconPrimary,
                  ),
                ],
              ),

              SizedBox(height: 24.w),

              // Daily Challenge
              _buildDailyChallengeCard(theme),

              SizedBox(height: 16.w),

              // Daily Bonus
              _buildDailyBonusHomeCard(theme),

              SizedBox(height: 20.w),

              // Continue button (if game exists)
              _buildContinueCard(theme),

              SizedBox(height: 24.w),

              // Quick Start
              Text(
                AppLocalizations.of(context).quickStart,
                style: AppTextStyles.title(context, color: theme.textPrimary),
              ),

              SizedBox(height: 12.w),

              // Difficulty options
              _buildDifficultyGrid(theme),

              SizedBox(height: 20.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(AppThemeColors theme) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF5B5F97),
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date box - opens Daily Challenge screen (calendar + badge room)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
              );
            },
            child: Container(
              width: 55.w,
              height: 65.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${now.day}',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.getMonth(now.month),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Small calendar indicator
                  Positioned(
                    top: 4.w,
                    right: 4.w,
                    child: Icon(
                      Bootstrap.calendar_event,
                      size: 12.w,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 14.w),
          // Main content - Play daily challenge
          Expanded(
            child: GestureDetector(
              onTap: () => _startDailyChallenge(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).dailyChallenge,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    AppLocalizations.of(context).dailyChallengeSubtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _startDailyChallenge(),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Bootstrap.play_fill,
                color: Colors.white,
                size: 24.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBonusHomeCard(AppThemeColors theme) {
    final isAvailable = _isDailyBonusAvailable && AdsService.shouldShowAds();

    return GestureDetector(
      onTap: isAvailable ? () => _claimDailyBonus() : null,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isAvailable ? const Color(0xFFC45C56) : Colors.grey.shade500,
          borderRadius: BorderRadius.circular(20.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 55.w,
              height: 55.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14.w),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 28.w,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 14.w),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Bonus',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    isAvailable
                        ? 'Watch ad, earn +50 XP!'
                        : 'Come back tomorrow!',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Play/Check icon
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvailable ? Icons.play_arrow : Icons.check,
                color: Colors.white,
                size: 22.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _claimDailyBonus() async {
    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading ad...'),
            ],
          ),
        ),
      ),
    );

    bool rewarded = false;
    bool adNotReady = false;

    AdsService.showDailyBonusAd(
      onRewarded: () {
        rewarded = true;
      },
      onAdNotReady: () {
        adNotReady = true;
      },
      onAdClosed: () {
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!mounted) return;
          Navigator.pop(context); // Close loading

          if (rewarded) {
            // Add 50 XP bonus
            await LevelService.addBonusXp(50);

            // Update state
            setState(() {
              _isDailyBonusAvailable = false;
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('+50 XP bonus claimed!',
                          style: TextStyle(fontSize: 14.sp)),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    adNotReady
                        ? AppLocalizations.of(context).adLoadingTryAgain
                        : AppLocalizations.of(context).watchFullAdForBonus,
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: adNotReady ? 4 : 2),
                ),
              );
            }
          }
        });
      },
    );
  }

  Widget _buildContinueCard(AppThemeColors theme) {
    final isDark = theme.isDark;
    final cardColor = theme.card;
    final textColor = theme.textPrimary;
    final currentGame = StorageService.getCurrentGame();
    // Only show when there is an actual in-progress game (not completed and grid not already solved)
    final isDone = currentGame == null ||
        currentGame.isCompleted ||
        currentGame.isGridSolved;
    if (isDone) {
      if (currentGame != null &&
          (currentGame.isCompleted || currentGame.isGridSolved)) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => StorageService.clearCurrentGame());
      }
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _continueGame(),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.w),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? textColor.withValues(alpha: 0.1)
                    : const Color(0xFFe8eaf6),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: textColor,
                size: 24.w,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).continueGame,
                    style: AppTextStyles.subtitle(context, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_getLocalizedDifficulty(currentGame.difficulty)} • ${_formatDuration(currentGame.elapsedTime)}',
                    style: AppTextStyles.bodySmall(context,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.w,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyGrid(AppThemeColors theme) {
    final isDark = theme.isDark;
    final cardColor = theme.card;
    final l10n = AppLocalizations.of(context);
    // Modern icons from icons_plus package
    final difficulties = [
      {
        'name': l10n.easy,
        'key': 'Easy',
        'color': const Color(0xFF4CAF50),
        'icon': Bootstrap.emoji_smile_fill,
        'xp': 15
      },
      {
        'name': l10n.medium,
        'key': 'Medium',
        'color': const Color(0xFFFF9800),
        'icon': Bootstrap.emoji_neutral_fill,
        'xp': 30
      },
      {
        'name': l10n.hard,
        'key': 'Hard',
        'color': const Color(0xFFE53935),
        'icon': Bootstrap.emoji_frown_fill,
        'xp': 50
      },
      {
        'name': l10n.expert,
        'key': 'Expert',
        'color': const Color(0xFF9C27B0),
        'icon': Bootstrap.lightning_charge_fill,
        'xp': 80
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 12.w,
        childAspectRatio: ResponsiveUtils.difficultyCardAspectRatio(),
      ),
      itemCount: difficulties.length,
      itemBuilder: (context, index) {
        final diff = difficulties[index];
        final diffColor = diff['color'] as Color;
        return GestureDetector(
          onTap: () => _startNewGame(diff['key'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16.w),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: diffColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // XP Badge at top right
                Positioned(
                  top: 8.w,
                  right: 8.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.orange.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Text(
                      '+${diff['xp']} XP',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        diff['icon'] as IconData,
                        size: 28.w,
                        color: diffColor,
                      ),
                      SizedBox(height: 6.w),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            diff['name'] as String,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: diffColor,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final isDark = theme.isDark;

    // Use theme colors for navbar - seamless integration
    final bgColor = theme.backgroundGradientEnd;
    final selectedColor = theme.accent;
    final unselectedColor =
        isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        // Solid color matching theme - no gradient needed
        color: bgColor,
        // Subtle top border for separation
        border: Border(
          top: BorderSide(
            color: theme.accent.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedFontSize: 11.sp,
          unselectedFontSize: 10.sp,
          iconSize: 22.w,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Bootstrap.house, size: 22.w),
              activeIcon: Icon(Bootstrap.house_fill, size: 22.w),
              label: AppLocalizations.of(context).home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Bootstrap.lightning_charge, size: 22.w),
              activeIcon: Icon(Bootstrap.lightning_charge_fill, size: 22.w),
              label: AppLocalizations.of(context).duel,
            ),
            BottomNavigationBarItem(
              icon: Icon(Bootstrap.person, size: 22.w),
              activeIcon: Icon(Bootstrap.person_fill, size: 22.w),
              label: AppLocalizations.of(context).profile,
            ),
          ],
        ),
      ),
    );
  }

  void _startNewGame(String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: difficulty,
          isNewGame: true,
        ),
      ),
    );
  }

  void _continueGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GameScreen(isNewGame: false),
      ),
    );
  }

  void _startDailyChallenge() {
    // Daily challenge - seed created with today's date
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GameScreen(
          difficulty: 'Medium',
          isNewGame: true,
          isDailyChallenge: true,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getLocalizedDifficulty(String difficulty) {
    final l10n = AppLocalizations.of(context);
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return l10n.easy;
      case 'medium':
        return l10n.medium;
      case 'hard':
        return l10n.hard;
      case 'expert':
        return l10n.expert;
      default:
        return difficulty;
    }
  }
}
