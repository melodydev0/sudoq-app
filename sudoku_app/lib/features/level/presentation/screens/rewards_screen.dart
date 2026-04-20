import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/services/user_sync_service.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Compact screen for viewing and selecting unlocked rewards
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedFrameProvider.notifier).state =
          LevelService.selectedFrameId;
      ref.read(selectedThemeProvider.notifier).state =
          LevelService.selectedThemeId;
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
    final levelData = LevelService.levelData;
    ref.watch(selectedFrameProvider);
    ref.watch(selectedThemeProvider);
    final theme = AppThemeManager.colors;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(l10n, levelData, theme),
            _buildCompactTabBar(l10n, theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFramesGrid(levelData, theme),
                  _buildThemesGrid(levelData, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
      AppLocalizations l10n, UserLevelData levelData, AppThemeColors theme) {
    final rank = levelData.rank;
    final nonDefaultFrames =
        CosmeticRewards.frames.where((r) => r.unlockLevel > 1).length;
    final nonDefaultThemes =
        CosmeticRewards.themes.where((r) => r.unlockLevel > 1).length;
    final totalCount = nonDefaultFrames + nonDefaultThemes;

    final unlockedCount = CosmeticRewards.allRewards
        .where((r) =>
            r.unlockLevel > 1 &&
            r.unlockLevel <= levelData.level &&
            (r.type == RewardType.theme || r.type == RewardType.frame))
        .length
        .clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.accentLight,
                borderRadius: AppTheme.buttonRadius,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: theme.iconSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.buttonPrimary,
              borderRadius: AppTheme.buttonRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                rank.imagePath != null
                    ? Image.asset(
                        rank.imagePath!,
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) =>
                            Text(rank.icon, style: TextStyle(fontSize: 14.sp)),
                      )
                    : Text(rank.icon, style: TextStyle(fontSize: 14.sp)),
                const SizedBox(width: 6),
                Text(
                  'Lv.${levelData.level}',
                  style: TextStyle(
                      color: theme.buttonText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$unlockedCount/$totalCount ${l10n.rewards}',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTabBar(AppLocalizations l10n, AppThemeColors theme) {
    final tabs = [
      {'icon': Bootstrap.border_style, 'label': l10n.frames},
      {'icon': Icons.grid_view_outlined, 'label': l10n.gridStyle},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.accentLight,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  _tabController.animateTo(index);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.buttonPrimary : null,
                  borderRadius: AppTheme.buttonRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 16,
                      color:
                          isSelected ? theme.buttonText : theme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? theme.buttonText : theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFramesGrid(UserLevelData levelData, AppThemeColors theme) {
    final frames = List<FrameReward>.from(CosmeticRewards.frames)
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isUnlocked = frame.unlockLevel <= levelData.level;
        final isEquipped = LevelService.selectedFrameId == frame.id;

        return _buildCompactFrameCard(frame, isUnlocked, isEquipped, theme);
      },
    );
  }

  Widget _buildThemesGrid(UserLevelData levelData, AppThemeColors theme) {
    final themes = List<ThemeReward>.from(CosmeticRewards.themes)
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final themeReward = themes[index];
        final isUnlocked = themeReward.unlockLevel <= levelData.level;
        final isEquipped = LevelService.selectedThemeId == themeReward.id;
        return _buildCompactThemeCard(
            themeReward, isUnlocked, isEquipped, theme);
      },
    );
  }

  Widget _buildCompactFrameCard(FrameReward frame, bool isUnlocked,
      bool isEquipped, AppThemeColors theme) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: isUnlocked ? () => _equipFrame(frame) : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: AppTheme.cardRadius,
          border: isEquipped
              ? Border.all(color: theme.buttonPrimary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color:
                  theme.textPrimary.withValues(alpha: isUnlocked ? 0.12 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(colors: frame.gradientColors)
                    : null,
                color: isUnlocked ? null : theme.divider.withValues(alpha: 0.5),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: isUnlocked && frame.imagePath != null
                  ? ClipRRect(
                      borderRadius: AppTheme.buttonRadius,
                      child: Image.asset(
                        frame.imagePath!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            frame.iconData ?? Bootstrap.border_style,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        frame.iconData ?? Bootstrap.border_style,
                        color: isUnlocked ? Colors.white : theme.textSecondary,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.rewardName(frame.nameKey),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? theme.textPrimary : theme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            if (isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.buttonPrimary,
                  borderRadius: AppTheme.buttonRadius,
                ),
                child: Text('✓',
                    style: TextStyle(color: theme.buttonText, fontSize: 10.sp)),
              )
            else if (!isUnlocked)
              Text(
                'Lv.${frame.unlockLevel}',
                style: TextStyle(fontSize: 9.sp, color: theme.textSecondary),
              )
            else
              Text(
                l10n.equip,
                style: TextStyle(fontSize: 9.sp, color: theme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactThemeCard(ThemeReward themeReward, bool isUnlocked,
      bool isEquipped, AppThemeColors theme) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: isUnlocked ? () => _equipTheme(themeReward) : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: AppTheme.cardRadius,
          border: isEquipped
              ? Border.all(color: theme.buttonPrimary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color:
                  theme.textPrimary.withValues(alpha: isUnlocked ? 0.12 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? themeReward.primaryColor
                    : theme.divider.withValues(alpha: 0.5),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: isUnlocked
                  ? (themeReward.imagePath != null
                      ? ClipRRect(
                          borderRadius: AppTheme.buttonRadius,
                          child: Image.asset(
                            themeReward.imagePath!,
                            width: 60,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(themeReward.previewAsset,
                                  style: TextStyle(fontSize: 20.sp)),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(themeReward.previewAsset,
                              style: TextStyle(fontSize: 20.sp)),
                        ))
                  : Icon(Icons.lock, color: theme.textSecondary, size: 18),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.rewardName(themeReward.nameKey),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? theme.textPrimary : theme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            if (isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.buttonPrimary,
                  borderRadius: AppTheme.buttonRadius,
                ),
                child: Text('✓',
                    style: TextStyle(color: theme.buttonText, fontSize: 10.sp)),
              )
            else if (!isUnlocked)
              Text(
                'Lv.${themeReward.unlockLevel}',
                style: TextStyle(fontSize: 9.sp, color: theme.textSecondary),
              )
            else
              Text(
                l10n.equip,
                style: TextStyle(fontSize: 9.sp, color: theme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  void _equipFrame(FrameReward frame) async {
    await LevelService.setSelectedFrame(frame.id);
    // Sync to Firestore so leaderboards and battles reflect the new frame
    UserSyncService.syncToCloud().ignore();
    if (!mounted) return;
    ref.read(selectedFrameProvider.notifier).state = frame.id;
    setState(() {});

    if (mounted) {
      final t = AppThemeManager.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).equipped}: ${AppLocalizations.of(context).rewardName(frame.nameKey)}'),
          backgroundColor: t.card,
          behavior: SnackBarBehavior.floating,
          shape:
              const RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _equipTheme(ThemeReward themeReward) async {
    await LevelService.setSelectedTheme(themeReward.id);
    if (!mounted) return;
    ref.read(selectedThemeProvider.notifier).state = themeReward.id;
    setState(() {});

    if (mounted) {
      final t = AppThemeManager.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).equipped}: ${AppLocalizations.of(context).rewardName(themeReward.nameKey)}'),
          backgroundColor: t.card,
          behavior: SnackBarBehavior.floating,
          shape:
              const RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
