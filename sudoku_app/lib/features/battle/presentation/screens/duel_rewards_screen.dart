import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/animated_frame.dart';

/// Duel Rewards Screen - Shows frames and themes unlockable through duel achievements
class DuelRewardsScreen extends StatefulWidget {
  const DuelRewardsScreen({super.key});

  @override
  State<DuelRewardsScreen> createState() => _DuelRewardsScreenState();
}

class _DuelRewardsScreenState extends State<DuelRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, true); // Always return true to refresh profile
        }
      },
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textPrimary),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: Text(
            l10n.duelRewards,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.accent,
            labelColor: theme.accent,
            unselectedLabelColor: theme.textSecondary,
            tabs: [
              Tab(text: '🖼️ ${l10n.frames}'),
              Tab(text: '🎨 ${l10n.themes}'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Stats Summary
            _buildStatsSummary(theme, l10n),

            // Rewards List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFramesList(theme, l10n),
                  _buildThemesList(theme, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(AppThemeColors theme, AppLocalizations l10n) {
    int duelWins = 0;
    int duelElo = 1000;
    String duelRank = 'Bronze';
    String rankEmoji = '🥉';

    try {
      duelWins = LocalDuelStatsService.wins;
      duelElo = LocalDuelStatsService.elo;
      duelRank = LocalDuelStatsService.rank;
      rankEmoji = LocalDuelStatsService.getRankEmoji(duelRank);
    } catch (e) {
      debugPrint('Error loading duel stats: $e');
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent.withValues(alpha: 0.15),
            theme.accentSecondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(rankEmoji, duelRank, theme),
          _buildStatItem('🏆', '$duelWins ${l10n.wins}', theme),
          _buildStatItem('⚡', '$duelElo ELO', theme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, AppThemeColors theme) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24.sp)),
        SizedBox(height: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFramesList(AppThemeColors theme, AppLocalizations l10n) {
    final frames = CosmeticRewards.rankedFrames;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isUnlocked = _isRewardUnlocked(frame);
        final progress = _getUnlockProgress(frame);

        return _buildRewardCard(
          theme: theme,
          l10n: l10n,
          reward: frame,
          isUnlocked: isUnlocked,
          progress: progress,
          onTap: isUnlocked ? () => _selectFrame(frame) : null,
        );
      },
    );
  }

  Widget _buildThemesList(AppThemeColors theme, AppLocalizations l10n) {
    const themes = CosmeticRewards.rankedThemes;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final themeReward = themes[index];
        final isUnlocked = _isRewardUnlocked(themeReward);
        final progress = _getUnlockProgress(themeReward);

        return _buildRewardCard(
          theme: theme,
          l10n: l10n,
          reward: themeReward,
          isUnlocked: isUnlocked,
          progress: progress,
          onTap: isUnlocked ? () => _selectTheme(themeReward) : null,
        );
      },
    );
  }

  Widget _buildRewardCard({
    required AppThemeColors theme,
    required AppLocalizations l10n,
    required CosmeticReward reward,
    required bool isUnlocked,
    required double progress,
    VoidCallback? onTap,
  }) {
    final isSelected = _isSelected(reward);
    final isFrame = reward.type == RewardType.frame;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isSelected ? theme.accent.withValues(alpha: 0.2) : theme.card)
              : theme.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isSelected
                ? theme.accent
                : (isUnlocked
                    ? theme.cardBorder
                    : theme.cardBorder.withValues(alpha: 0.3)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Preview - Use FramePreview for frames, emoji for themes
            if (isFrame && reward is FrameReward)
              FramePreview(
                frame: reward,
                size: 55.w,
                isSelected: isSelected,
                isUnlocked: isUnlocked,
              )
            else
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? theme.accent.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Center(
                  child: Text(
                    reward.previewAsset,
                    style: TextStyle(
                      fontSize: 28.sp,
                      color: isUnlocked ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
            SizedBox(width: 12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getRewardName(reward, l10n),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? theme.textPrimary
                                : theme.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: theme.accent, size: 20.w),
                      if (!isUnlocked)
                        Icon(Icons.lock,
                            color: theme.textSecondary, size: 18.w),
                    ],
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    _getUnlockConditionText(reward, l10n),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.textSecondary,
                    ),
                  ),
                  if (!isUnlocked && progress > 0) ...[
                    SizedBox(height: 8.w),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.w),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.cardBorder,
                        valueColor: AlwaysStoppedAnimation(theme.accent),
                        minHeight: 4,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isRewardUnlocked(CosmeticReward reward) {
    try {
      final condition = reward.unlockCondition;
      if (condition == null) return true;

      final duelWins = LocalDuelStatsService.wins;
      final duelElo = LocalDuelStatsService.elo;

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

        // Season rewards - only through special unlocks
        case 'season_top50':
        case 'season_top10':
        case 'season_top3':
        case 'season_first':
          // Check if manually unlocked
          final unlockedRewards = LevelService.levelData.unlockedRewards;
          return unlockedRewards.contains(condition) ||
              unlockedRewards.contains(reward.id);

        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking reward unlock: $e');
      return false;
    }
  }

  double _getUnlockProgress(CosmeticReward reward) {
    try {
      final condition = reward.unlockCondition;
      if (condition == null) return 1.0;

      final duelWins = LocalDuelStatsService.wins;
      final duelElo = LocalDuelStatsService.elo;

      switch (condition) {
        case 'ranked_10_wins':
          return (duelWins / 10).clamp(0.0, 1.0);
        case 'ranked_50_wins':
          return (duelWins / 50).clamp(0.0, 1.0);
        case 'ranked_100_wins':
          return (duelWins / 100).clamp(0.0, 1.0);
        case 'ranked_250_wins':
          return (duelWins / 250).clamp(0.0, 1.0);
        case 'platinum_division':
          return (duelElo / 1100).clamp(0.0, 1.0);
        case 'diamond_division':
          return (duelElo / 1400).clamp(0.0, 1.0);
        case 'master_division':
          return (duelElo / 1700).clamp(0.0, 1.0);
        case 'grandmaster_division':
          return (duelElo / 2000).clamp(0.0, 1.0);
        case 'champion_division':
          return (duelElo / 2300).clamp(0.0, 1.0);
        default:
          return 0.0;
      }
    } catch (e) {
      debugPrint('Error getting unlock progress: $e');
      return 0.0;
    }
  }

  String _getUnlockConditionText(CosmeticReward reward, AppLocalizations l10n) {
    final condition = reward.unlockCondition;
    if (condition == null) return '';

    switch (condition) {
      case 'ranked_10_wins':
        return 'Win 10 ${l10n.duel.toLowerCase()}s';
      case 'ranked_50_wins':
        return 'Win 50 ${l10n.duel.toLowerCase()}s';
      case 'ranked_100_wins':
        return 'Win 100 ${l10n.duel.toLowerCase()}s';
      case 'ranked_250_wins':
        return 'Win 250 ${l10n.duel.toLowerCase()}s';
      case 'platinum_division':
        return 'Reach Platinum (1100 ELO)';
      case 'diamond_division':
        return 'Reach Diamond (1400 ELO)';
      case 'master_division':
        return 'Reach Master (1700 ELO)';
      case 'grandmaster_division':
        return 'Reach Grandmaster (2000 ELO)';
      case 'champion_division':
        return 'Reach Champion (2300 ELO)';
      case 'season_top50':
        return 'Finish Top 50 in Season';
      case 'season_top10':
        return 'Finish Top 10 in Season';
      case 'season_top3':
        return 'Finish Top 3 in Season';
      case 'season_first':
        return 'Finish #1 in Season';
      default:
        return condition;
    }
  }

  String _getRewardName(CosmeticReward reward, AppLocalizations l10n) {
    // Try to get localized name, fallback to nameKey
    try {
      final nameKey = reward.nameKey;
      // Simple mapping for common reward names
      switch (nameKey) {
        case 'frameWarrior':
          return 'Warrior Frame';
        case 'frameGladiator':
          return 'Gladiator Frame';
        case 'framePlatinumRanked':
          return 'Platinum Frame';
        case 'frameDiamondRanked':
          return 'Diamond Frame';
        case 'frameMasterRanked':
          return 'Master Frame';
        case 'frameGrandmasterRanked':
          return 'Grandmaster Frame';
        case 'frameChampionRanked':
          return 'Champion Frame';
        case 'frameTop50':
          return 'Top 50 Frame';
        case 'framePro':
          return 'Pro Frame';
        case 'frameElite':
          return 'Elite Frame';
        case 'frameLegend':
          return 'Legend Frame';
        case 'themeChampion':
          return "Champion's Glory";
        case 'themeGrandmaster':
          return 'Grandmaster Prestige';
        default:
          return nameKey;
      }
    } catch (e) {
      return reward.nameKey;
    }
  }

  bool _isSelected(CosmeticReward reward) {
    try {
      if (reward.type == RewardType.frame) {
        return LevelService.selectedFrameId == reward.id;
      } else if (reward.type == RewardType.theme) {
        return LevelService.selectedThemeId == reward.id;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking selection: $e');
      return false;
    }
  }

  void _selectFrame(CosmeticReward reward) {
    HapticFeedback.selectionClick();
    LevelService.setSelectedFrame(reward.id);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Frame selected'),
        backgroundColor: AppThemeManager.colors.accent,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _selectTheme(CosmeticReward reward) {
    HapticFeedback.selectionClick();
    LevelService.setSelectedTheme(reward.id);

    // Apply the theme to AppThemeManager
    AppThemeType themeType;
    switch (reward.id) {
      case 'ranked_theme_champion':
        themeType = AppThemeType.champion;
        break;
      case 'ranked_theme_grandmaster':
        themeType = AppThemeType.grandmaster;
        break;
      default:
        themeType = AppThemeType.light; // Default theme
    }
    AppThemeManager.setTheme(themeType);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Theme applied'),
        backgroundColor: AppThemeManager.colors.accent,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
}
