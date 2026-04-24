import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/models/achievement.dart';
import '../../../../core/models/statistics.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/l10n/app_localizations.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Achievement> _getAchievementsWithProgress(Statistics stats) {
    final achievements = Achievements.getDefaultAchievements();
    final achievementData = AchievementService.data;

    return achievements.map((achievement) {
      int currentValue = 0;
      bool isUnlocked = achievementData.unlockedIds.contains(achievement.id);

      // Calculate current value based on achievement type
      switch (achievement.id) {
        // ============ GAME WINS ============
        case 'first_win':
        case 'win_10':
        case 'win_50':
        case 'win_100':
        case 'win_500':
          currentValue = stats.totalGamesWon;
          break;

        // ============ PERFECT GAMES ============
        case 'first_perfect':
        case 'perfect_10':
        case 'perfect_50':
        case 'perfect_100':
          currentValue = stats.perfectGames;
          break;

        // ============ WIN STREAKS ============
        case 'streak_3':
        case 'streak_7':
        case 'streak_14':
        case 'streak_30':
          currentValue = stats.bestStreak;
          break;

        // ============ SPEED ACHIEVEMENTS ============
        case 'speed_easy_3min':
          currentValue =
              (stats.difficultyStats['Easy']?.bestTime ?? 999999) <= 180
                  ? 1
                  : 0;
          break;
        case 'speed_medium_8min':
          currentValue =
              (stats.difficultyStats['Medium']?.bestTime ?? 999999) <= 480
                  ? 1
                  : 0;
          break;
        case 'speed_hard_15min':
          currentValue =
              (stats.difficultyStats['Hard']?.bestTime ?? 999999) <= 900
                  ? 1
                  : 0;
          break;
        case 'speed_expert_25min':
          currentValue =
              (stats.difficultyStats['Expert']?.bestTime ?? 999999) <= 1500
                  ? 1
                  : 0;
          break;

        // ============ DIFFICULTY PUZZLES ============
        // Easy achievements
        case 'easy_5':
        case 'easy_10':
        case 'easy_50':
        case 'easy_100':
        case 'easy_master':
          currentValue = stats.difficultyStats['Easy']?.gamesWon ?? 0;
          break;

        // Medium achievements
        case 'medium_5':
        case 'medium_10':
        case 'medium_50':
        case 'medium_master':
          currentValue = stats.difficultyStats['Medium']?.gamesWon ?? 0;
          break;

        // Hard achievements
        case 'hard_5':
        case 'hard_20':
        case 'hard_master':
          currentValue = stats.difficultyStats['Hard']?.gamesWon ?? 0;
          break;

        // Expert achievements
        case 'expert_10':
        case 'expert_master':
          currentValue = stats.difficultyStats['Expert']?.gamesWon ?? 0;
          break;

        // Expert perfect (check if unlocked in achievement data)
        case 'expert_perfect':
          currentValue =
              achievementData.unlockedIds.contains('expert_perfect') ? 1 : 0;
          break;

        // Days played (unique days, not streak)
        case 'days_7':
        case 'days_30':
        case 'days_365':
          currentValue = stats.daysPlayed;
          break;

        // Daily challenges completed
        case 'daily_first':
        case 'daily_7':
        case 'daily_14':
        case 'daily_30':
          currentValue = stats.totalDailyChallengesCompleted;
          break;

        // Hints used
        case 'hints_10':
        case 'hints_100':
        case 'hints_500':
        case 'hints_1000':
          currentValue = stats.totalHintsUsed;
          break;

        // ============ DUEL ACHIEVEMENTS ============
        // Duel Win achievements
        case 'duel_first_win':
        case 'duel_win_10':
        case 'duel_win_50':
        case 'duel_win_100':
        case 'duel_win_500':
          currentValue = LocalDuelStatsService.wins;
          break;

        // Duel streak
        case 'duel_streak_3':
        case 'duel_streak_5':
        case 'duel_streak_10':
          currentValue = LocalDuelStatsService.bestStreak;
          break;

        // Division achievements (based on ELO)
        case 'duel_silver':
        case 'duel_gold':
        case 'duel_platinum':
        case 'duel_diamond':
        case 'duel_master':
        case 'duel_grandmaster':
        case 'duel_champion':
          currentValue = LocalDuelStatsService.elo;
          break;

        default:
          currentValue = 0;
      }

      // Check if achievement should be unlocked (only for non-coming-soon)
      if (!achievement.isComingSoon &&
          currentValue >= achievement.targetValue &&
          !isUnlocked) {
        isUnlocked = true;
      }

      return achievement.copyWith(
        currentValue: currentValue.clamp(0, achievement.targetValue),
        isUnlocked: isUnlocked,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(statisticsProvider);
    final achievements = _getAchievementsWithProgress(stats);
    final size = MediaQuery.of(context).size;
    final labelSize = size.width * 0.035;
    final theme = AppThemeManager.colors;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: theme.iconSecondary),
                  ),
                  Text(
                    l10n.achievements,
                    style: TextStyle(
                      fontSize: labelSize.clamp(18.0, 22.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Progress overview
            _buildProgressOverview(l10n, achievements, labelSize, theme),
            const SizedBox(height: 16),
            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.buttonPrimary,
              unselectedLabelColor: theme.textSecondary,
              indicatorColor: theme.buttonPrimary,
              labelStyle: TextStyle(
                fontSize: labelSize.clamp(11.0, 14.0),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              tabs: AchievementCategory.values.map((category) {
                return Tab(text: _getCategoryName(category, l10n));
              }).toList(),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: AchievementCategory.values.map((category) {
                  return _buildCategoryList(
                      category, achievements, labelSize, theme);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview(AppLocalizations l10n,
      List<Achievement> achievements, double labelSize, AppThemeColors theme) {
    final availableAchievements =
        achievements.where((a) => !a.isComingSoon).toList();
    final unlockedCount =
        availableAchievements.where((a) => a.isUnlocked).length;
    final totalCount = availableAchievements.length;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.buttonPrimary,
          borderRadius: AppTheme.cardRadius,
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
                Icon(
                  Icons.emoji_events,
                  color: theme.buttonText,
                  size: labelSize * 2.5,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlockedCount / $totalCount ${l10n.unlocked}',
                        style: TextStyle(
                          color: theme.buttonText,
                          fontSize: labelSize.clamp(14.0, 18.0),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.keepPlayingToUnlock,
                        style: TextStyle(
                          color: theme.buttonText.withValues(alpha: 0.85),
                          fontSize: labelSize.clamp(11.0, 14.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.buttonText.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(theme.buttonText),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(AchievementCategory category,
      List<Achievement> achievements, double labelSize, AppThemeColors theme) {
    final categoryAchievements =
        achievements.where((a) => a.category == category).toList();
    categoryAchievements.sort((a, b) => a.xpReward.compareTo(b.xpReward));

    if (categoryAchievements.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noAchievementsInCategory,
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryAchievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(
            categoryAchievements[index], labelSize, theme);
      },
    );
  }

  Widget _buildAchievementCard(
      Achievement achievement, double labelSize, AppThemeColors theme) {
    final l10n = AppLocalizations.of(context);
    final isComingSoon = achievement.isComingSoon;
    final iconData = _getAchievementIcon(achievement);
    final iconColor = _getAchievementIconColor(achievement);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComingSoon ? theme.accentLight : theme.card,
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: achievement.isUnlocked && !isComingSoon
            ? Border.all(color: theme.success.withValues(alpha: 0.5), width: 2)
            : Border.all(color: theme.divider, width: 1),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: labelSize * 3.5,
                height: labelSize * 3.5,
                decoration: BoxDecoration(
                  color: isComingSoon
                      ? theme.divider.withValues(alpha: 0.5)
                      : achievement.isUnlocked
                          ? iconColor.withValues(alpha: 0.15)
                          : theme.accentLight,
                  borderRadius: AppTheme.buttonRadius,
                  boxShadow: achievement.isUnlocked && !isComingSoon
                      ? [
                          BoxShadow(
                              color: iconColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Center(
                  child: Image.asset(
                    achievement.imagePath,
                    width: labelSize * 1.6,
                    height: labelSize * 1.6,
                    errorBuilder: (_, __, ___) => Icon(
                      iconData,
                      size: labelSize * 1.6,
                      color: isComingSoon
                          ? theme.textSecondary
                          : achievement.isUnlocked
                              ? iconColor
                              : theme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.achievementTitle(achievement.id),
                            style: TextStyle(
                              fontSize: labelSize.clamp(12.0, 15.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: isComingSoon
                                  ? theme.textSecondary
                                  : achievement.isUnlocked
                                      ? theme.textPrimary
                                      : theme.textSecondary,
                            ),
                          ),
                        ),
                        if (achievement.isUnlocked && !isComingSoon)
                          Icon(Icons.check_circle,
                              color: theme.success, size: labelSize * 1.4),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.achievementDesc(achievement.id),
                      style: TextStyle(
                        fontSize: labelSize.clamp(10.0, 12.0),
                        color: isComingSoon
                            ? theme.textSecondary.withValues(alpha: 0.8)
                            : theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: isComingSoon ? 0 : achievement.progress,
                              backgroundColor: theme.accentLight,
                              valueColor: AlwaysStoppedAnimation(
                                isComingSoon
                                    ? theme.divider
                                    : achievement.isUnlocked
                                        ? theme.success
                                        : theme.buttonPrimary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isComingSoon ? theme.divider : theme.warning,
                            borderRadius: AppTheme.buttonRadius,
                          ),
                          child: Text(
                            'XP +${achievement.xpReward}',
                            style: TextStyle(
                              fontSize: labelSize.clamp(9.0, 11.0),
                              fontWeight: FontWeight.bold,
                              color: isComingSoon
                                  ? theme.textSecondary
                                  : theme.buttonText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isComingSoon
                              ? '0/${achievement.targetValue}'
                              : '${achievement.currentValue}/${achievement.targetValue}',
                          style: TextStyle(
                            fontSize: labelSize.clamp(10.0, 12.0),
                            fontWeight: FontWeight.w600,
                            color: isComingSoon
                                ? theme.textSecondary
                                : achievement.isUnlocked
                                    ? theme.success
                                    : theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isComingSoon)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.warning,
                  borderRadius: AppTheme.buttonRadius,
                ),
                child: Text(
                  l10n.comingSoon,
                  style: TextStyle(
                    fontSize: labelSize.clamp(8.0, 10.0),
                    fontWeight: FontWeight.bold,
                    color: theme.buttonText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryName(AchievementCategory category, AppLocalizations l10n) {
    switch (category) {
      case AchievementCategory.seedling:
        return l10n.seedling;
      case AchievementCategory.rising:
        return l10n.rising;
      case AchievementCategory.skilled:
        return l10n.skilled;
      case AchievementCategory.elite:
        return l10n.elite;
      case AchievementCategory.legendary:
        return l10n.legendary;
      case AchievementCategory.duel:
        return '⚔️ ${l10n.duel}';
    }
  }

  /// Get icon based on achievement type and XP reward
  IconData _getAchievementIcon(Achievement achievement) {
    final id = achievement.id;
    final xp = achievement.xpReward;

    // Duel achievements - special icons
    if (id.startsWith('duel_')) {
      if (id.contains('champion')) return Bootstrap.trophy_fill;
      if (id.contains('grandmaster')) return FontAwesome.hat_wizard_solid;
      if (id.contains('master')) return Bootstrap.gem;
      if (id.contains('diamond')) return FontAwesome.gem_solid;
      if (id.contains('platinum')) return FontAwesome.shield_solid;
      if (id.contains('gold')) return Bootstrap.award_fill;
      if (id.contains('silver')) return FontAwesome.medal_solid;
      if (id.contains('streak')) return FontAwesome.fire_solid;
      if (id.contains('win')) return FontAwesome.trophy_solid;
      return Bootstrap.shield_fill;
    }

    // Easy/Beginner achievements
    if (id.startsWith('easy_')) return FontAwesome.seedling_solid;

    // Medium achievements
    if (id.startsWith('medium_')) return Bootstrap.lightning_fill;

    // Hard achievements
    if (id.startsWith('hard_')) return FontAwesome.dumbbell_solid;

    // Expert achievements
    if (id.startsWith('expert_')) return FontAwesome.brain_solid;

    // Days played
    if (id.startsWith('days_')) return FontAwesome.calendar_check_solid;

    // Daily challenges
    if (id.startsWith('daily_')) return FontAwesome.star_solid;

    // Hints
    if (id.startsWith('hints_')) return FontAwesome.lightbulb_solid;

    // Based on XP tier
    if (xp >= 1000) return Bootstrap.trophy_fill;
    if (xp >= 500) return FontAwesome.crown_solid;
    if (xp >= 200) return FontAwesome.gem_solid;
    if (xp >= 100) return FontAwesome.medal_solid;
    if (xp >= 50) return FontAwesome.star_solid;

    return FontAwesome.circle_check_solid;
  }

  /// Get icon color based on achievement rarity/XP
  Color _getAchievementIconColor(Achievement achievement) {
    final xp = achievement.xpReward;
    final id = achievement.id;

    // Duel - special colors
    if (id.startsWith('duel_')) {
      if (id.contains('champion')) return const Color(0xFFFF4500); // Orange-red
      if (id.contains('grandmaster')) return const Color(0xFF9400D3); // Purple
      if (id.contains('master')) return const Color(0xFFFFA500); // Orange
      if (id.contains('diamond')) return const Color(0xFF1E90FF); // Blue
      if (id.contains('platinum')) return const Color(0xFF00BFFF); // Light blue
      if (id.contains('gold')) return const Color(0xFFFFD700); // Gold
      if (id.contains('silver')) return const Color(0xFFC0C0C0); // Silver
      if (id.contains('streak')) return const Color(0xFFFF5722); // Deep Orange
      return const Color(0xFFCD7F32); // Bronze
    }

    // Based on XP tier - Legendary
    if (xp >= 1000) return const Color(0xFFFFD700); // Gold
    if (xp >= 500) return const Color(0xFF9C27B0); // Purple
    if (xp >= 200) return const Color(0xFF2196F3); // Blue
    if (xp >= 100) return const Color(0xFF4CAF50); // Green
    if (xp >= 50) return const Color(0xFFFF9800); // Orange

    return const Color(0xFF607D8B); // Grey-blue
  }
}
