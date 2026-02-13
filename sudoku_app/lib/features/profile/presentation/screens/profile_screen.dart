import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/widgets/animated_frame.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../level/presentation/screens/rewards_screen.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../../battle/presentation/screens/duel_rewards_screen.dart';
import '../../../../core/services/local_duel_stats_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize frame provider with current value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedFrameProvider.notifier).state =
          LevelService.selectedFrameId;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final statistics = ref.watch(statisticsProvider);

    // Use AppThemeManager for premium themes
    final theme = AppThemeManager.colors;

    return Container(
      color: theme.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding()),
              child: Row(
                children: [
                  Text(
                    l10n.personal,
                    style: AppTextStyles.headline2(context,
                        color: theme.textPrimary),
                  ),
                  const Spacer(),
                  // Leaderboard button
                  IconButton(
                    onPressed: () => _openLeaderboard(),
                    icon: Icon(Bootstrap.trophy, size: 22.w),
                    color: theme.iconSecondary,
                  ),
                  IconButton(
                    onPressed: () => _openSettings(),
                    icon: Icon(Bootstrap.gear, size: 22.w),
                    color: theme.iconSecondary,
                  ),
                ],
              ),
            ),

            // Level & XP Card
            _buildLevelCard(theme, l10n),

            SizedBox(height: 16.w),

            // Stats summary
            _buildStatsSummary(statistics, theme, l10n),

            SizedBox(height: 24.w),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: theme.accent,
              unselectedLabelColor: theme.textSecondary,
              indicatorColor: theme.accent,
              labelStyle:
                  TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 12.sp),
              tabs: [
                Tab(text: l10n.daily),
                Tab(text: l10n.duel),
                Tab(text: l10n.achievements),
                Tab(text: l10n.event),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyTab(theme, l10n),
                  _buildBattleTab(theme, l10n),
                  _buildAchievementTab(theme, l10n),
                  _buildEventTab(theme, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(AppThemeColors theme, AppLocalizations l10n) {
    final levelData = LevelService.levelData;
    final rank = levelData.rank;
    final season = LevelService.currentSeason;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding()),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RewardsScreen()),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.buttonPrimary,
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: theme.buttonPrimary, width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.textPrimary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Rank icon with Frame
                  _buildFramedAvatar(rank, theme),
                  SizedBox(width: 12.w),
                  // Level info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getLocalizedRank(l10n, rank.rank),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                                color: theme.buttonText,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.w),
                              decoration: BoxDecoration(
                                color: theme.buttonText.withValues(alpha: 0.25),
                                borderRadius: AppTheme.buttonRadius,
                              ),
                              child: Text(
                                '${l10n.level} ${levelData.level}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.buttonText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.w),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.w),
                          child: LinearProgressIndicator(
                            value: levelData.levelProgress,
                            backgroundColor:
                                theme.buttonText.withValues(alpha: 0.3),
                            valueColor:
                                AlwaysStoppedAnimation(theme.buttonText),
                            minHeight: 6.w,
                          ),
                        ),
                        SizedBox(height: 4.w),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${levelData.totalXp} XP',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: theme.buttonText.withValues(alpha: 0.9),
                              ),
                            ),
                            if (levelData.level < LevelConstants.maxLevel)
                              Text(
                                '${levelData.xpToNextLevel} XP ${l10n.toNextLevel}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color:
                                      theme.buttonText.withValues(alpha: 0.9),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.chevron_right,
                    color: theme.buttonText.withValues(alpha: 0.9),
                  ),
                ],
              ),
              SizedBox(height: 12.w),
              // Season info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
                decoration: BoxDecoration(
                  color: theme.buttonText.withValues(alpha: 0.2),
                  borderRadius: AppTheme.buttonRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                            color: theme.warning, size: 16.w),
                        SizedBox(width: 6.w),
                        Text(
                          '${l10n.season} ${season.seasonNumber}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.buttonText,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${season.daysRemaining} ${l10n.daysRemaining}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.buttonText.withValues(alpha: 0.9),
                      ),
                    ),
                    if (levelData.streakDays > 0)
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: theme.warning, size: 14.w),
                          SizedBox(width: 2.w),
                          Text(
                            '${levelData.streakDays} ${l10n.streak}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedRank(AppLocalizations l10n, UserRank rank) {
    switch (rank) {
      case UserRank.novice:
        return l10n.novice;
      case UserRank.amateur:
        return l10n.amateur;
      case UserRank.talented:
        return l10n.talented;
      case UserRank.expert:
        return l10n.expert;
      case UserRank.master:
        return l10n.master;
      case UserRank.legend:
        return l10n.legend;
      case UserRank.sudokuKing:
        return l10n.sudokuKing;
    }
  }

  Widget _buildFramedAvatar(RankInfo rank, AppThemeColors theme) {
    // Watch the provider for real-time updates
    final selectedFrameId = ref.watch(selectedFrameProvider);

    // Get selected frame - check both normal and ranked frames
    FrameReward? selectedFrame;
    if (selectedFrameId.isNotEmpty && selectedFrameId != 'frame_basic') {
      // First check normal frames
      try {
        selectedFrame =
            CosmeticRewards.frames.firstWhere((f) => f.id == selectedFrameId);
      } catch (_) {}

      // Then check ranked frames if not found
      if (selectedFrame == null) {
        try {
          selectedFrame = CosmeticRewards.rankedFrames
              .firstWhere((f) => f.id == selectedFrameId);
        } catch (_) {}
      }
    }

    final avatarSize = 56.w;
    final hasFrame = selectedFrame != null;

    // Frame + Avatar combined design - ikon frame'den gelir
    if (hasFrame) {
      return AnimatedAvatarFrame(
        frame: selectedFrame,
        size: avatarSize,
        showAnimation: true,
        child: Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selectedFrame.gradientColors,
            ),
            borderRadius: BorderRadius.circular(14.w),
            boxShadow: [
              BoxShadow(
                color:
                    selectedFrame.gradientColors.first.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              selectedFrame.iconData ?? Icons.star,
              color: Colors.white,
              size: 28.w,
            ),
          ),
        ),
      );
    }

    // Default avatar (no frame selected)
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rank.icon,
          style: TextStyle(fontSize: 26.sp),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(
      statistics, AppThemeColors theme, AppLocalizations l10n) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding()),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: l10n.games,
              value: '${statistics.totalGamesPlayed}',
              theme: theme,
            ),
            _StatItem(
              label: l10n.winRate,
              value: '${statistics.winRate.toStringAsFixed(0)}%',
              theme: theme,
            ),
            _StatItem(
              label: l10n.bestStreak,
              value: '${statistics.bestStreak}',
              theme: theme,
            ),
            _StatItem(
              label: l10n.perfect,
              value: '${statistics.perfectGames}',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTab(AppThemeColors theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 50.w,
            color: theme.textMuted,
          ),
          SizedBox(height: 16.w),
          Text(
            l10n.dailyChallengeHistory,
            style: AppTextStyles.title(context, color: theme.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              l10n.completeDailyToSee,
              style: AppTextStyles.body(context, color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTab(AppThemeColors theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_outlined,
            size: 50.w,
            color: theme.textMuted,
          ),
          SizedBox(height: 16.w),
          Text(
            l10n.eventHistory,
            style: AppTextStyles.title(context, color: theme.textSecondary),
          ),
          SizedBox(height: 8.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              l10n.participateInEvents,
              style: AppTextStyles.body(context, color: theme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleTab(AppThemeColors theme, AppLocalizations l10n) {
    final duelStats = LocalDuelStatsService.getAllStats();
    final rank = duelStats['rank'] as String? ?? 'Bronze';
    final elo = duelStats['elo'] as int? ?? 1000;
    final wins = duelStats['wins'] as int? ?? 0;
    final winRate = duelStats['winRate'] as double? ?? 0.0;
    final bestStreak = duelStats['bestStreak'] as int? ?? 0;

    final divColor = _getDuelDivisionColor(rank);
    final progress = LocalDuelStatsService.getDivisionProgress(elo);
    final eloToNext = LocalDuelStatsService.getEloToNextDivision(elo);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Column(
        children: [
          // Duel Division Card
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [divColor, divColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(LocalDuelStatsService.getRankEmoji(rank),
                        style: TextStyle(fontSize: 24.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rank,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$elo ELO',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    _buildMiniStat('$wins', l10n.wins),
                    SizedBox(width: 10.w),
                    _buildMiniStat(
                        '${winRate.toStringAsFixed(0)}%', l10n.winRate),
                    SizedBox(width: 10.w),
                    _buildMiniStat('$bestStreak', l10n.bestStreak),
                  ],
                ),
                SizedBox(height: 8.w),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.w),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      eloToNext > 0 ? '$eloToNext ELO' : 'MAX',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          // Duel Rewards Button
          _buildDuelRewardsButton(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildDuelRewardsButton(AppThemeColors theme, AppLocalizations l10n) {
    final duelWins = LocalDuelStatsService.wins;
    final duelElo = LocalDuelStatsService.elo;

    // Count unlocked rewards using same logic as DuelRewardsScreen
    int unlockedFrames = 0;
    int unlockedThemes = 0;

    // Check each frame's unlock condition
    for (final frame in CosmeticRewards.rankedFrames) {
      if (_isRewardUnlocked(frame, duelWins, duelElo)) {
        unlockedFrames++;
      }
    }

    // Check each theme's unlock condition
    for (final themeReward in CosmeticRewards.rankedThemes) {
      if (_isRewardUnlocked(themeReward, duelWins, duelElo)) {
        unlockedThemes++;
      }
    }

    final totalFrames = CosmeticRewards.rankedFrames.length;
    final totalThemes = CosmeticRewards.rankedThemes.length;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const DuelRewardsScreen()),
        );
        if (changed == true && mounted) {
          // Update the frame provider so avatar updates immediately
          ref.read(selectedFrameProvider.notifier).state =
              LevelService.selectedFrameId;
          setState(() {});
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
        decoration: BoxDecoration(
          color: theme.buttonPrimary,
          borderRadius: AppTheme.buttonRadius,
          border: Border.all(color: theme.buttonPrimary),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.military_tech, color: theme.accent, size: 20.w),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                l10n.duelRewards,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.buttonText),
              ),
            ),
            Text(
              '🖼️ $unlockedFrames/$totalFrames  🎨 $unlockedThemes/$totalThemes',
              style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.buttonText.withValues(alpha: 0.9)),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, color: theme.buttonText, size: 18.w),
          ],
        ),
      ),
    );
  }

  bool _isRewardUnlocked(CosmeticReward reward, int duelWins, int duelElo) {
    final condition = reward.unlockCondition;
    if (condition == null) return true;

    switch (condition) {
      // Win-based rewards
      case 'ranked_10_wins':
        return duelWins >= 10;
      case 'ranked_50_wins':
        return duelWins >= 50;
      case 'ranked_100_wins':
        return duelWins >= 100;
      case 'ranked_250_wins':
        return duelWins >= 250;

      // Division-based rewards (ELO)
      case 'platinum_division':
        return duelElo >= 1100;
      case 'diamond_division':
        return duelElo >= 1400;
      case 'master_division':
        return duelElo >= 1700;
      case 'grandmaster_division':
        return duelElo >= 2000;
      case 'champion_division':
        return duelElo >= 2300;

      // Season rewards - check manual unlocks
      case 'season_top50':
      case 'season_top10':
      case 'season_top3':
      case 'season_first':
        final unlockedRewards = LevelService.levelData.unlockedRewards;
        return unlockedRewards.contains(condition) ||
            unlockedRewards.contains(reward.id);

      default:
        return false;
    }
  }

  Color _getDuelDivisionColor(String rank) {
    switch (rank) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFF8C00);
      case 'Platinum':
        return const Color(0xFF00BFFF);
      case 'Diamond':
        return const Color(0xFF1E90FF);
      case 'Master':
        return const Color(0xFFFFA500);
      case 'Grandmaster':
        return const Color(0xFF9400D3);
      case 'Champion':
        return const Color(0xFFFF4500);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 9.sp)),
      ],
    );
  }

  Widget _buildAchievementTab(AppThemeColors theme, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Achievement progress overview
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: theme.buttonPrimary,
              borderRadius: AppTheme.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 40.w,
                      color: theme.buttonText,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.achievements,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: theme.buttonText,
                            ),
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            l10n.checkYourProgress,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: theme.buttonText.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openAchievements(),
                      child: Text(
                        l10n.viewAll,
                        style: TextStyle(
                            color: theme.buttonText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLeaderboard() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors theme;

  const _StatItem(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: theme.accent,
          ),
        ),
        SizedBox(height: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
