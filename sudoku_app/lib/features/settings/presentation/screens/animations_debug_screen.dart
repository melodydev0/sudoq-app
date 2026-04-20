import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/game_state.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/celebration_effect.dart';
import '../../../battle/presentation/widgets/rank_up_celebration_overlay.dart';
import '../../../game/presentation/widgets/game_complete_dialog.dart';
import '../../../game/presentation/widgets/sudoku_grid.dart';
import '../../../level/presentation/screens/level_progress_screen.dart';
import '../../../onboarding/presentation/screens/splash_screen.dart';
import 'icon_export_screen.dart';

/// Debug screen to test all in-app animations without manual gameplay.
class AnimationsDebugScreen extends StatelessWidget {
  const AnimationsDebugScreen({super.key});

  static const List<({String from, String to})> _rankUps = [
    (from: 'Bronze', to: 'Silver'),
    (from: 'Silver', to: 'Gold'),
    (from: 'Gold', to: 'Platinum'),
    (from: 'Platinum', to: 'Diamond'),
    (from: 'Diamond', to: 'Master'),
    (from: 'Master', to: 'Grandmaster'),
    (from: 'Grandmaster', to: 'Champion'),
  ];

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Animations + Buttons'),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [AppColors.backgroundLight, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sade / şık / handcrafted motion set',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _sectionTitle(context, '🚀 Giriş / Splash', isDark),
            const SizedBox(height: 8),

            // Icon Export Tool
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.amber),
                title: const Text(
                  'Export All Icons as PNG',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Tüm ikonları PNG olarak dışa aktar',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IconExportScreen()),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ListTile(
                leading: Icon(
                  Icons.rocket_launch,
                  color: Colors.blue.shade400,
                  size: 24,
                ),
                title: Text(
                  'Splash screen',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Handcrafted splash art + clean fade transition',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        isDark ? Colors.grey.shade500 : AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.play_circle_outline,
                  color:
                      isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                ),
                onTap: () => _openSplashTest(context),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '🏆 Rank-up celebrations', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _rankUps.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFC4CEDB),
                        size: 24,
                      ),
                      title: Text(
                        '${_rankUps[i].from} → ${_rankUps[i].to}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Premium rank-up: burst + sparks + shimmer text',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.grey.shade500
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary,
                      ),
                      onTap: () => _openRankUpTest(
                          context, _rankUps[i].from, _rankUps[i].to),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '⬆️ Level Up', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ListTile(
                leading: const Icon(
                  Bootstrap.arrow_up_circle_fill,
                  color: Color(0xFFB8C2CF),
                  size: 24,
                ),
                title: Text(
                  'Level Up',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Integrated Level Progress screen (single-bar layout)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        isDark ? Colors.grey.shade500 : AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.play_circle_outline,
                  color:
                      isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                ),
                onTap: () => _openLevelUpTest(context),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '⚔️ Battle result badges', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.emoji_events,
                        color: Color(0xFFCDD6E2), size: 24),
                    title: Text(
                      AppLocalizations.of(context).victory,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Minimal trophy badge intro (soft glow + fade)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_circle_outline,
                      color: isDark
                          ? Colors.grey.shade400
                          : AppColors.textSecondary,
                    ),
                    onTap: () => _openResultBadgeTest(context, won: true),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.cancel,
                        color: Color(0xFFAEB8C8), size: 24),
                    title: Text(
                      AppLocalizations.of(context).defeat,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Minimal defeat badge intro (soft glow + fade)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_circle_outline,
                      color: isDark
                          ? Colors.grey.shade400
                          : AppColors.textSecondary,
                    ),
                    onTap: () => _openResultBadgeTest(context, won: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '🎮 Oyun içi (In-game)', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_awesome,
                        color: Color(0xFFD5DEE9), size: 24),
                    title: Text(
                      'Cell celebration',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Refined neutral particle burst',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openCellCelebrationTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.grid_on,
                        color: Color(0xFFC3CDD9), size: 24),
                    title: Text(
                      'Board completion sweep',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Top-down crafted fill effect for complete-now finish',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openBoardCompletionSweepTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.radio_button_checked,
                        color: Color(0xFFC9D2E0), size: 24),
                    title: Text(
                      'Ripple effect',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Soft grayscale ripple',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openRippleTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.check_circle,
                        color: Color(0xFFD7DFEA), size: 24),
                    title: Text(
                      'Success checkmark',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Clean handcrafted success checkmark',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openSuccessCheckmarkTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.emoji_events,
                        color: Color(0xFFC9D2E0), size: 24),
                    title: Text(
                      AppLocalizations.of(context).gameComplete,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Game complete dialog (modern minimal styling)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openGameCompleteDialogTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.trending_up,
                        color: Color(0xFFB8C2CF), size: 24),
                    title: Text(
                      AppLocalizations.of(context).levelUp,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Integrated level-up flow with Level 2 emphasis',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openLevelProgressTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium,
                        color: Color(0xFFB4BFCE), size: 24),
                    title: Text(
                      'Premium 2x XP boost',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Final XP count + subtle premium x2 add-on animation',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openPremiumXpBoostTest(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline,
                        color: Color(0xFFB8C2CF), size: 24),
                    title: Text(
                      AppLocalizations.of(context).autoCompleteNow,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Handcrafted auto-complete CTA (soft slide-in)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openAutoCompleteButtonTest(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '🧪 Test Buttons', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ListTile(
                leading: const Icon(Icons.smart_button,
                    color: Color(0xFFB8C2CF), size: 24),
                title: Text(
                  'All app buttons',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Every major button style in one place',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        isDark ? Colors.grey.shade500 : AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.play_circle_outline,
                  color:
                      isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                ),
                onTap: () => _openGameEndButtonsTest(context),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '📐 Satır / sütun / kutu tamamlama', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.view_agenda,
                        color: Color(0xFFCCD5E3), size: 24),
                    title: Text(
                      'Satır tamamlama',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Row completion with subtle clean stroke',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openSectionCompletionTest(context, 'row', 2),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.view_column,
                        color: Color(0xFFCCD5E3), size: 24),
                    title: Text(
                      'Sütun tamamlama',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Column completion with subtle clean stroke',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openSectionCompletionTest(context, 'col', 1),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.grid_3x3,
                        color: Color(0xFFC9D2E0), size: 24),
                    title: Text(
                      'Kutu tamamlama',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      '3x3 box completion with minimal highlight',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.play_circle_outline,
                        color: isDark
                            ? Colors.grey.shade400
                            : AppColors.textSecondary),
                    onTap: () => _openSectionCompletionTest(context, 'box', 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Tap any item to preview the new handcrafted animation set.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color:
                      isDark ? Colors.grey.shade600 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
        ),
      ),
    );
  }

  void _openSplashTest(BuildContext context) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SplashScreen(testMode: true),
      ),
    );
  }

  void _openRankUpTest(BuildContext context, String fromRank, String toRank) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: RankUpCelebrationOverlay(
            fromRank: fromRank,
            toRank: toRank,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  static void _openLevelUpTest(BuildContext context) {
    HapticService.lightImpact();
    // Level 2 threshold is >220 total XP in current level model.
    final prev = UserLevelData(totalXp: 210, seasonNumber: 1);
    final next = UserLevelData(totalXp: 260, seasonNumber: 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LevelProgressScreen(
          xpEarned: 50,
          previousLevelData: prev,
          newLevelData: next,
          difficulty: 'Medium',
          completionTime: const Duration(minutes: 5, seconds: 12),
          mistakes: 0,
          isDailyChallenge: false,
          isRanked: false,
          newAchievements: const [],
          achievementXp: 0,
          xpBoostMultiplier: 1.0,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openResultBadgeTest(BuildContext context, {required bool won}) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ResultBadgeTestPage(won: won),
      ),
    );
  }

  void _openCellCelebrationTest(BuildContext context) {
    HapticService.lightImpact();
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EffectTestPage(
          hint: 'Cell celebration',
          child: Stack(
            fit: StackFit.expand,
            children: [
              CelebrationEffect(
                position: center,
                color: const Color(0xFFD8E0EA),
                onComplete: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBoardCompletionSweepTest(BuildContext context) {
    HapticService.lightImpact();
    final size = MediaQuery.of(context).size;
    final boardSize = size.width * 0.84;
    final left = (size.width - boardSize) / 2;
    final top = (size.height - boardSize) / 2;
    final rect = Rect.fromLTWH(left, top, boardSize, boardSize);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EffectTestPage(
          hint: 'Board completion sweep',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF202734),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3F4A5B),
                    ),
                  ),
                ),
              ),
              BoardCompletionEffect(
                boardRect: rect,
                gridSize: 9,
                onComplete: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRippleTest(BuildContext context) {
    HapticService.lightImpact();
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EffectTestPage(
          hint: 'Ripple effect',
          child: Stack(
            fit: StackFit.expand,
            children: [
              RippleEffect(
                position: center,
                color: const Color(0xFFC6D0DE),
                onComplete: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSuccessCheckmarkTest(BuildContext context) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EffectTestPage(
          hint: 'Success checkmark',
          child: Center(
            child: SuccessCheckmark(
              size: 80,
              color: const Color(0xFFD8E0EA),
              onComplete: () {},
            ),
          ),
        ),
      ),
    );
  }

  void _openGameCompleteDialogTest(BuildContext context) {
    HapticService.lightImpact();
    showDialog<void>(
      context: context,
      builder: (context) => GameCompleteDialog(
        won: true,
        score: 1250,
        time: const Duration(minutes: 4, seconds: 32),
        mistakes: 0,
        difficulty: 'Medium',
        onNewGame: () => Navigator.of(context).pop(),
        onHome: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _openLevelProgressTest(BuildContext context) {
    HapticService.lightImpact();
    final prev = UserLevelData(totalXp: 210, seasonNumber: 1);
    final next = UserLevelData(totalXp: 260, seasonNumber: 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LevelProgressScreen(
          xpEarned: 50,
          previousLevelData: prev,
          newLevelData: next,
          difficulty: 'Medium',
          completionTime: const Duration(minutes: 5, seconds: 12),
          mistakes: 0,
          isDailyChallenge: false,
          isRanked: false,
          newAchievements: const [],
          achievementXp: 0,
          xpBoostMultiplier: 1.0,
          isPremiumXpBoost: false,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openPremiumXpBoostTest(BuildContext context) {
    HapticService.lightImpact();
    final prev = UserLevelData(totalXp: 640, seasonNumber: 1);
    final next = UserLevelData(totalXp: 860, seasonNumber: 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LevelProgressScreen(
          xpEarned: 220,
          previousLevelData: prev,
          newLevelData: next,
          difficulty: 'Hard',
          completionTime: const Duration(minutes: 7, seconds: 8),
          mistakes: 1,
          isDailyChallenge: false,
          isRanked: false,
          newAchievements: const [],
          achievementXp: 40,
          xpBoostMultiplier: 2.0,
          isPremiumXpBoost: true,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openSectionCompletionTest(
      BuildContext context, String type, int index) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _SectionCompletionTestPage(type: type, index: index),
      ),
    );
  }

  void _openAutoCompleteButtonTest(BuildContext context) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _AutoCompleteButtonTestPage(),
      ),
    );
  }

  void _openGameEndButtonsTest(BuildContext context) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _AllButtonsTestPage(),
      ),
    );
  }
}

class _AllButtonsTestPage extends StatelessWidget {
  const _AllButtonsTestPage();

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);

    void tapMsg(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped: $label'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
        );

    Widget card({required List<Widget> children}) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16213E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(children: children),
        );

    Widget appActionButton(
      String label, {
      IconData? icon,
      bool adBadge = false,
      bool active = false,
      bool primary = false,
      double? width,
    }) {
      final bg = primary
          ? theme.buttonPrimary
          : (active
              ? theme.accent.withValues(alpha: 0.16)
              : (isDark ? const Color(0xFF1E2747) : const Color(0xFFF3F5F8)));
      final fg = primary
          ? theme.buttonText
          : (active ? theme.accent : (isDark ? Colors.white : AppColors.textPrimary));
      final borderColor = active
          ? theme.accent.withValues(alpha: 0.45)
          : (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08));

      return GestureDetector(
        onTap: () => tapMsg(label),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (adBadge) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFBBC5D2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'AD',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: primary ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('All App Buttons'),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'App genelindeki buton stilleri burada tek ekranda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          sectionTitle('In-Game Action Buttons'),
          card(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  appActionButton('Hint', icon: Icons.lightbulb_outline, adBadge: true),
                  appActionButton('Notes', icon: Icons.edit_note, adBadge: true),
                  appActionButton('Erase', icon: Icons.backspace_outlined),
                  appActionButton('Undo', icon: Icons.undo),
                  appActionButton('Pause', icon: Icons.pause_circle_outline),
                  appActionButton('Complete now!', icon: Icons.check_circle_outline, primary: true),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Sudoku Number Pad Buttons'),
          card(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 1; i <= 9; i++)
                    GestureDetector(
                      onTap: () => tapMsg('Number $i'),
                      child: Container(
                        width: 52,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E2747) : const Color(0xFFF3F5F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Text(
                          '$i',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  appActionButton(
                    'Clear Cell',
                    icon: Icons.backspace_outlined,
                    width: 170,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Game Complete Buttons'),
          card(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => tapMsg(l10n.home),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        side: BorderSide(
                            color: const Color(0xFFBCC6D4).withValues(alpha: 0.7)),
                      ),
                      child: Text(l10n.home),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => tapMsg(l10n.newGame),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonPrimary,
                        foregroundColor: theme.buttonText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        elevation: 1,
                      ),
                      child: Text(l10n.newGame),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Free Ad + Premium CTA Buttons'),
          card(
            children: [
              appActionButton(
                'Watch Ad for 2x XP',
                icon: Icons.play_circle_filled,
                primary: true,
                adBadge: true,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
              appActionButton(
                'No thanks (normal XP)',
                icon: Icons.arrow_forward,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
              appActionButton(
                'Watch Ad (Second Chance)',
                icon: Icons.play_circle_filled,
                adBadge: true,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
              appActionButton(
                'Become VIP',
                icon: Icons.workspace_premium,
                primary: true,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => tapMsg('Give Up'),
                child: Text(
                  'Give Up',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Home / Start Flow Buttons'),
          card(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  appActionButton('Easy', icon: Icons.sentiment_satisfied_alt),
                  appActionButton('Medium', icon: Icons.tune),
                  appActionButton('Hard', icon: Icons.local_fire_department),
                  appActionButton('Daily Challenge', icon: Icons.calendar_today),
                  appActionButton('Duel / Battle', icon: Icons.sports_kabaddi),
                  appActionButton('Leaderboard', icon: Icons.emoji_events_outlined),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Battle / Matchmaking Buttons'),
          card(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  appActionButton('Find Match', icon: Icons.search, primary: true),
                  appActionButton('Create Room', icon: Icons.add_circle_outline),
                  appActionButton('Join with Code', icon: Icons.meeting_room_outlined),
                  appActionButton('Ready', icon: Icons.check_circle_outline, active: true),
                  appActionButton('Rematch', icon: Icons.replay, primary: true),
                  appActionButton('Back to Lobby', icon: Icons.home_outlined),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Subscription / Profile / Settings Buttons'),
          card(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  appActionButton('Monthly Plan', icon: Icons.calendar_month, primary: true),
                  appActionButton('Yearly Plan', icon: Icons.workspace_premium, primary: true),
                  appActionButton('Restore Purchase', icon: Icons.restore),
                  appActionButton('Manage Subscription', icon: Icons.settings_outlined),
                  appActionButton('Save Changes', icon: Icons.save_outlined, primary: true),
                  appActionButton('Reset Data', icon: Icons.refresh),
                  appActionButton('Sign Out', icon: Icons.logout),
                  appActionButton('Delete Account', icon: Icons.delete_outline),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          sectionTitle('Core Flutter Button Types'),
          card(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => tapMsg('ElevatedButton'),
                      child: const Text('Elevated'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => tapMsg('OutlinedButton'),
                      child: const Text('Outlined'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => tapMsg('TextButton'),
                      child: const Text('Text'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => tapMsg('IconButton: search'),
                    icon: const Icon(Icons.search),
                  ),
                  IconButton(
                    onPressed: () => tapMsg('IconButton: favorite'),
                    icon: const Icon(Icons.favorite_border),
                  ),
                  IconButton(
                    onPressed: () => tapMsg('IconButton: more'),
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Buton tasarım düzenlemelerini bu tek ekrandan yapabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey.shade500 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Test page for the "Complete now!" auto-complete button (slide-in + tap).
class _AutoCompleteButtonTestPage extends StatefulWidget {
  const _AutoCompleteButtonTestPage();

  @override
  State<_AutoCompleteButtonTestPage> createState() =>
      _AutoCompleteButtonTestPageState();
}

class _AutoCompleteButtonTestPageState extends State<_AutoCompleteButtonTestPage> {
  int _tapCount = 0;
  Key _slideKey = UniqueKey();

  void _replaySlide() {
    setState(() {
      _slideKey = UniqueKey();
      _tapCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.autoCompleteNow),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Spacer(),
            Text(
              'Tap the button to replay slide animation',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
              ),
            ),
            if (_tapCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tapped $_tapCount time(s)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFBBC5D2),
                  ),
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TweenAnimationBuilder<double>(
                        key: _slideKey,
                        tween: Tween(begin: 1, end: 0),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(80 * value, 0),
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTap: _replaySlide,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB9C3D1),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB9C3D1)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Bootstrap.check2_all,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.autoCompleteNow,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _fakeAction(Icons.undo, 'Undo', isDark),
                      _fakeAction(Icons.backspace_outlined, 'Erase', isDark),
                      _fakeAction(Icons.edit_outlined, 'Notes', isDark),
                      _fakeAction(Icons.flash_on, 'Fast', isDark),
                      _fakeAction(Icons.lightbulb_outline, 'Hint', isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _fakeAction(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.grey),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Level Up animation test: XP bar fills then "Level Up" appears inside.
class _LevelUpAnimationTest extends StatefulWidget {
  final VoidCallback onClose;

  const _LevelUpAnimationTest({required this.onClose});

  @override
  State<_LevelUpAnimationTest> createState() => _LevelUpAnimationTestState();
}

class _LevelUpAnimationTestState extends State<_LevelUpAnimationTest>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _textController;
  static const double _prevProgress = 0.54;
  static const int _prevLevel = 1;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fillController.forward();
    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: Listenable.merge([_fillController, _textController]),
              builder: (context, child) {
                final fillT =
                    Curves.easeOutCubic.transform(_fillController.value);
                final barProgress =
                    _prevProgress + (1.0 - _prevProgress) * fillT;
                final textT = Curves.easeOut.transform(_textController.value);
                final textOpacity = textT;
                final textScale = 0.92 + 0.08 * textT;

                const accentNeutral = Color(0xFFBCC6D4);
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.w,
                    ),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: accentNeutral.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: theme.textPrimary.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: accentNeutral.withValues(alpha: 0.24),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('◌', style: TextStyle(fontSize: 24.sp, color: accentNeutral)),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Novice',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Level $_prevLevel',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(barProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: accentNeutral,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.w),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final fillWidth = w * barProgress.clamp(0.0, 1.0);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 44.w,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: theme.isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : theme.textPrimary
                                              .withValues(alpha: 0.08),
                                    ),
                                    SizedBox(
                                      width: fillWidth,
                                      height: double.infinity,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: accentNeutral,
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentNeutral
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Opacity(
                                        opacity: textOpacity,
                                        child: Transform.scale(
                                          scale: textScale,
                                          child: Text(
                                            'LEVEL UP',
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                              color: barProgress > 0.5
                                                  ? Colors.white
                                                  : accentNeutral,
                                              shadows: barProgress > 0.5
                                                  ? [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.25),
                                                        offset:
                                                            const Offset(0, 1),
                                                        blurRadius: 2,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8.w),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lv $_prevLevel',
                              style: TextStyle(
                                  fontSize: 11.sp, color: theme.textSecondary),
                            ),
                            Text(
                              'Lv ${_prevLevel + 1}',
                              style: TextStyle(
                                  fontSize: 11.sp, color: theme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal 9x9 solved grid for section completion effect demo.
GameState _minimalGameState() {
  const solved = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];
  final grid = solved.map((r) => List<int>.from(r)).toList();
  final notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
  return GameState(
    puzzle: grid,
    solution: grid,
    currentGrid: grid,
    notes: notes,
    difficulty: 'Medium',
    gridSize: 9,
  );
}

class _SectionCompletionTestPage extends StatefulWidget {
  final String type;
  final int index;

  const _SectionCompletionTestPage({required this.type, required this.index});

  @override
  State<_SectionCompletionTestPage> createState() =>
      _SectionCompletionTestPageState();
}

class _SectionCompletionTestPageState
    extends State<_SectionCompletionTestPage> {
  List<CompletedSection> _sections = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _sections = [
            CompletedSection(
                type: widget.type,
                index: widget.index,
                completedAt: DateTime.now()),
          ];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.type == 'row'
              ? 'Satır tamamlama'
              : widget.type == 'col'
                  ? 'Sütun tamamlama'
                  : 'Kutu tamamlama',
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Grid üzerinde efekt oynar',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SudokuGrid(
                      gameState: _minimalGameState(),
                      selectedRow: null,
                      selectedCol: null,
                      onCellTap: (_, __) {},
                      completedSections: _sections,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '${AppLocalizations.of(context).continueGame} (tap to close)',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper for one-off effects: tap to close.
class _EffectTestPage extends StatelessWidget {
  final Widget child;
  final String hint;

  const _EffectTestPage({required this.child, required this.hint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.grey.shade900,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap to close',
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen page that plays the battle result badge animation (victory or defeat).
class _ResultBadgeTestPage extends StatefulWidget {
  final bool won;

  const _ResultBadgeTestPage({required this.won});

  @override
  State<_ResultBadgeTestPage> createState() => _ResultBadgeTestPageState();
}

class _ResultBadgeTestPageState extends State<_ResultBadgeTestPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 880),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF171C24), Color(0xFF0F1319)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (widget.won
                                  ? const Color(0xFFE4E9F2)
                                  : const Color(0xFFC9D1DF))
                              .withValues(alpha: 0.18),
                          border: Border.all(
                            color: widget.won
                                ? const Color(0xFFE2E8F2)
                                : const Color(0xFFBDC7D7),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.34),
                              blurRadius: 26,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: (widget.won
                                      ? const Color(0xFFE2E8F2)
                                      : const Color(0xFFBDC7D7))
                                  .withValues(alpha: 0.18),
                              blurRadius: 34,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.won
                              ? Bootstrap.trophy_fill
                              : Bootstrap.x_circle_fill,
                          size: 64,
                          color: widget.won
                              ? const Color(0xFFF0F4FA)
                              : const Color(0xFFD3DBE7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.won ? l10n.victory : l10n.defeat,
                        style: TextStyle(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.won
                              ? const Color(0xFFEAF0F8)
                              : const Color(0xFFD1D9E6),
                          letterSpacing: 3.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.42),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.continueGame,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
