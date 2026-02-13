import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: const Text('Test Animations'),
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
                  'Premium animasyonlar v3 (yeni build)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _sectionTitle(context, '🚀 Giriş / Splash', isDark),
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
                  'Logo + SudoQ + Zen Sudoku Puzzle animasyonu',
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
                      leading: Icon(
                        Icons.emoji_events,
                        color: Colors.amber.shade700,
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
                        'Confetti + badge transition',
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
                leading: Icon(
                  Bootstrap.arrow_up_circle_fill,
                  color: Colors.purple.shade400,
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
                  'XP bar dolar, içinde Level Up yazısı',
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
                    leading: Icon(Icons.emoji_events,
                        color: Colors.green.shade400, size: 24),
                    title: Text(
                      AppLocalizations.of(context).victory,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Scale + fade trophy',
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
                    leading: Icon(Icons.cancel,
                        color: Colors.red.shade400, size: 24),
                    title: Text(
                      AppLocalizations.of(context).defeat,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Scale + fade X',
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
                    leading: Icon(Icons.auto_awesome,
                        color: Colors.green.shade400, size: 24),
                    title: Text(
                      'Cell celebration',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Doğru hücre partikül patlaması',
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
                    leading: Icon(Icons.radio_button_checked,
                        color: Colors.blue.shade400, size: 24),
                    title: Text(
                      'Ripple effect',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Hücre seçim dalga efekti',
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
                        color: Color(0xFF4ADE80), size: 24),
                    title: Text(
                      'Success checkmark',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Başarı onay animasyonu',
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
                    leading: Icon(Icons.emoji_events,
                        color: Colors.amber.shade400, size: 24),
                    title: Text(
                      AppLocalizations.of(context).gameComplete,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Oyun bitti dialog',
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
                    leading: Icon(Icons.trending_up,
                        color: Colors.purple.shade400, size: 24),
                    title: Text(
                      AppLocalizations.of(context).levelUp,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'XP + seviye atlama ekranı',
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
                ],
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
                    leading: Icon(Icons.view_agenda,
                        color: Colors.green.shade400, size: 24),
                    title: Text(
                      'Satır tamamlama',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Bir satır doğru bitince yeşil çizgi efekti',
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
                    leading: Icon(Icons.view_column,
                        color: Colors.green.shade400, size: 24),
                    title: Text(
                      'Sütun tamamlama',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Bir sütun doğru bitince yeşil çizgi efekti',
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
                    leading: Icon(Icons.grid_3x3,
                        color: Colors.amber.shade400, size: 24),
                    title: Text(
                      'Kutu tamamlama',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      '3x3 kutu doğru bitince altın kutu efekti',
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
                'Tap an item to play the animation. Tap the overlay or "Continue" to close.',
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
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SplashScreen(testMode: true),
      ),
    );
  }

  void _openRankUpTest(BuildContext context, String fromRank, String toRank) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _LevelUpAnimationTest(
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openResultBadgeTest(BuildContext context, {required bool won}) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ResultBadgeTestPage(won: won),
      ),
    );
  }

  void _openCellCelebrationTest(BuildContext context) {
    HapticFeedback.lightImpact();
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
                color: const Color(0xFF4ADE80),
                onComplete: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRippleTest(BuildContext context) {
    HapticFeedback.lightImpact();
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
                color: Colors.blue.shade400,
                onComplete: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSuccessCheckmarkTest(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EffectTestPage(
          hint: 'Success checkmark',
          child: Center(
            child: SuccessCheckmark(
              size: 80,
              color: const Color(0xFF4ADE80),
              onComplete: () {},
            ),
          ),
        ),
      ),
    );
  }

  void _openGameCompleteDialogTest(BuildContext context) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    final prev = UserLevelData(totalXp: 80, seasonNumber: 1);
    final next = UserLevelData(totalXp: 130, seasonNumber: 1);
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

  void _openSectionCompletionTest(
      BuildContext context, String type, int index) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _SectionCompletionTestPage(type: type, index: index),
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
                      border: Border.all(
                        color: theme.accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.textPrimary.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: theme.accent.withValues(alpha: 0.2),
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
                            Text('🌱', style: TextStyle(fontSize: 26.sp)),
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
                                color: theme.accent,
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
                                          color: theme.accent,
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.accent
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
                                                  : theme.accent,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.won
                ? [const Color(0xFF1a472a), const Color(0xFF0d2818)]
                : [const Color(0xFF4a1a1a), const Color(0xFF280d0d)],
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
                          color: (widget.won ? Colors.green : Colors.red)
                              .withValues(alpha: 0.22),
                          border: Border.all(
                            color: widget.won ? Colors.green : Colors.red,
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.won ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.6),
                              blurRadius: 28,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: (widget.won ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.35),
                              blurRadius: 52,
                              spreadRadius: 6,
                            ),
                            BoxShadow(
                              color: (widget.won ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.15),
                              blurRadius: 72,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.won
                              ? Bootstrap.trophy_fill
                              : Bootstrap.x_circle_fill,
                          size: 64,
                          color:
                              widget.won ? Colors.amber : Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.won ? l10n.victory : l10n.defeat,
                        style: TextStyle(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.won
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(
                              color: (widget.won ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.5),
                              blurRadius: 12,
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
