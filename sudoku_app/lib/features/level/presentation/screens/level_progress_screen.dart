import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/models/achievement.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/sound_service.dart';

/// Screen shown after completing a game, displaying XP earned and level progress
class LevelProgressScreen extends StatefulWidget {
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
  final double xpBoostMultiplier; // 2x XP boost from watching ad
  final VoidCallback onContinue;

  const LevelProgressScreen({
    super.key,
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
    required this.onContinue,
  });

  @override
  State<LevelProgressScreen> createState() => _LevelProgressScreenState();
}

class _LevelProgressScreenState extends State<LevelProgressScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _xpCountController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _levelUpFillController;
  late AnimationController _levelUpTextController;

  // Animations
  late Animation<double> _headerScale;
  late Animation<double> _cardSlide;

  // State
  int _displayedXp = 0;
  int _totalCalculatedXp = 0; // Sum of breakdown items
  List<_XpBreakdownItem> _xpBreakdown = [];
  List<_ConfettiParticle> _confettiParticles = [];
  bool _showLevelUp = false;
  int _currentBreakdownIndex = -1;

  @override
  void initState() {
    super.initState();
    _calculateXpBreakdown();
    _checkLevelUp();
    _initAnimations();
    _generateConfetti();
    _startAnimationSequence();

    // Play victory sound when result screen opens
    SoundService().playVictory();
  }

  void _calculateXpBreakdown() {
    _xpBreakdown = [];
    final mult = widget.xpBoostMultiplier.clamp(1.0, 10.0);
    final gameXp = widget.xpEarned - widget.achievementXp;

    // Game XP (difficulty + performance + streak) – base value before 2x
    final baseGame = (gameXp / mult).round();
    if (baseGame > 0) {
      _xpBreakdown.add(_XpBreakdownItem(
        icon: _getDifficultyIcon(widget.difficulty),
        label: 'difficulty',
        xp: baseGame,
        color: _getDifficultyColor(widget.difficulty),
      ));
    }

    // Achievement XP – base value before 2x
    if (widget.achievementXp > 0) {
      final baseAch = (widget.achievementXp / mult).round();
      if (baseAch > 0) {
        _xpBreakdown.add(_XpBreakdownItem(
          icon: Bootstrap.award_fill,
          label: 'achievement',
          xp: baseAch,
          color: const Color(0xFF9C27B0),
          extra: widget.newAchievements.length,
        ));
      }
    }

    // 2x XP Boost from watching ad – remainder so breakdown total = xpEarned
    if (mult > 1.0) {
      final soFar = _xpBreakdown.fold<int>(0, (sum, item) => sum + item.xp);
      final boostXp = widget.xpEarned - soFar;
      if (boostXp > 0) {
        _xpBreakdown.add(_XpBreakdownItem(
          icon: Bootstrap.lightning_charge_fill,
          label: 'xpBoost',
          xp: boostXp,
          color: const Color(0xFFFF6B00),
        ));
      }
    }

    _totalCalculatedXp =
        _xpBreakdown.fold<int>(0, (sum, item) => sum + item.xp);
  }

  void _checkLevelUp() {
    _showLevelUp = widget.newLevelData.level > widget.previousLevelData.level;
  }

  void _initAnimations() {
    // Main entrance animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.42, curve: Curves.elasticOut)),
    );

    _cardSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic)),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _xpCountController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..addListener(() {
        setState(() {
          _displayedXp =
              (_totalCalculatedXp * _xpCountController.value).round();
        });
      });

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Pulse animation for level up (legacy, kept for any reuse)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Level up: XP bar fills then "Level Up" appears inside
    _levelUpFillController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _levelUpTextController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
  }

  void _generateConfetti() {
    final random = Random(42);
    _confettiParticles = List.generate(78, (index) {
      final isSlow = index % 4 == 0;
      return _ConfettiParticle(
        x: random.nextDouble(),
        y: isSlow
            ? random.nextDouble() * 0.4 - 0.5
            : random.nextDouble() * 0.3 - 0.35,
        size: random.nextDouble() * 6 + 6,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECDC4),
          const Color(0xFF9B59B6),
          const Color(0xFF3498DB),
          const Color(0xFFE74C3C),
          const Color(0xFFFFE082),
          const Color(0xFF2ECC71),
        ][random.nextInt(8)],
        velocity: isSlow
            ? random.nextDouble() * 0.5 + 0.5
            : random.nextDouble() * 1.6 + 1.2,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.3,
        shape: random.nextInt(3),
        swayAmplitude: 20 + random.nextDouble() * 28,
        swayFreq: 1.8 + random.nextDouble() * 2.6,
      );
    });
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mainController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _xpCountController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _progressController.forward();

    if (_showLevelUp && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) _levelUpFillController.forward();
      _levelUpFillController.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _levelUpTextController.forward();
        }
      });
    }

    // Start showing XP breakdown items one by one
    for (int i = 0; i < _xpBreakdown.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _currentBreakdownIndex = i);
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _xpCountController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _levelUpFillController.dispose();
    _levelUpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.backgroundGradientStart,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.backgroundGradientStart,
                  theme.backgroundGradientEnd,
                ],
              ),
            ),
          ),

          // Confetti
          _buildConfetti(),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.02),

                      // Header with title and difficulty badge
                      _buildHeader(l10n, theme, size),

                      SizedBox(height: size.height * 0.025),

                      // XP Card
                      Expanded(
                        child: _buildXpCard(l10n, theme, size),
                      ),

                      SizedBox(height: size.height * 0.015),

                      // Level Up card (in-flow widget when user levelled up)
                      if (_showLevelUp) ...[
                        _buildLevelUpCard(l10n, theme, size),
                        SizedBox(height: size.height * 0.015),
                      ],

                      // Level progress (current/new level)
                      _buildLevelProgress(l10n, theme, size),

                      SizedBox(height: size.height * 0.015),

                      // Season info
                      _buildSeasonInfo(l10n, theme, size),

                      // Achievements slider (if any)
                      if (widget.newAchievements.isNotEmpty) ...[
                        SizedBox(height: size.height * 0.015),
                        _buildAchievementsSlider(l10n, theme, size),
                      ],

                      SizedBox(height: size.height * 0.02),

                      // Continue button
                      _buildContinueButton(l10n, theme, size),

                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(
            particles: _confettiParticles,
            progress: _confettiController.value,
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppThemeColors theme, Size size) {
    return ScaleTransition(
      scale: _headerScale,
      child: Column(
        children: [
          Text(
            l10n.gameComplete,
            style: TextStyle(
              fontSize: size.width * 0.065,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getDifficultyColor(widget.difficulty),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDifficultyIcon(widget.difficulty),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getLocalizedDifficulty(l10n, widget.difficulty),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard(AppLocalizations l10n, AppThemeColors theme, Size size) {
    return Transform.translate(
      offset: Offset(0, _cardSlide.value),
      child: Opacity(
        opacity: _mainController.value.clamp(0.0, 1.0),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // XP Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Bootstrap.star_fill,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    l10n.score,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Big XP number – solid black, no gradient
              Text(
                '+$_displayedXp XP',
                style: TextStyle(
                  fontSize: size.width * 0.1,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // XP Breakdown with animations
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_xpBreakdown.length, (index) {
                      final item = _xpBreakdown[index];
                      final isVisible = index <= _currentBreakdownIndex;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isVisible ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 300),
                          offset:
                              isVisible ? Offset.zero : const Offset(0.5, 0),
                          child: _buildBreakdownRow(item, l10n, theme),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
      _XpBreakdownItem item, AppLocalizations l10n, AppThemeColors theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(item.icon, color: item.color, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getBreakdownLabel(l10n, item),
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${item.xp} XP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    final rank = widget.newLevelData.rank;
    final progress = widget.newLevelData.levelProgress;

    return Container(
      padding: EdgeInsets.all(size.width * 0.035),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(rank.icon, style: TextStyle(fontSize: 24.sp)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedRank(l10n, rank),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      'Level ${widget.newLevelData.level}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final raw = _progressController.value;
              final eased = Curves.easeOutCubic.transform(raw);
              final animatedProgress = progress * eased;
              final isFull = animatedProgress >= 0.98;
              return Container(
                decoration: isFull
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: theme.accent.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: animatedProgress,
                    backgroundColor: theme.isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(theme.accent),
                    minHeight: 12,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lv ${widget.newLevelData.level}',
                style: TextStyle(fontSize: 11.sp, color: theme.textSecondary),
              ),
              Text(
                'Lv ${widget.newLevelData.level + 1}',
                style: TextStyle(fontSize: 11.sp, color: theme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonInfo(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    final season = Season.getCurrentSeason();

    return Container(
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.deepOrange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Bootstrap.trophy_fill,
                color: Colors.orange, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Season ${season.seasonNumber}',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  'Level ${widget.newLevelData.seasonLevel} • ${season.daysRemaining} ${l10n.daysRemaining}',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${widget.newLevelData.seasonXp} XP',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSlider(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Bootstrap.award_fill, color: theme.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                '${l10n.achievements} (${widget.newAchievements.length})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Bootstrap.chevron_right,
                color: theme.textSecondary,
                size: 14,
              ),
            ],
          ),
        ),
        // Horizontal slider
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.newAchievements.length,
            itemBuilder: (context, index) {
              final achievement = widget.newAchievements[index];
              return _buildAchievementCard(achievement, theme, size);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
      Achievement achievement, AppThemeColors theme, Size size) {
    return Container(
      width: size.width * 0.4,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            achievement.color.withValues(alpha: 0.2),
            achievement.color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: achievement.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getAchievementName(achievement),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: achievement.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAchievementName(Achievement achievement) {
    // Format nameKey to readable string
    // e.g., 'achievementFirstWin' -> 'First Win'
    String name = achievement.nameKey;
    if (name.startsWith('achievement')) {
      name = name.substring(11); // Remove 'achievement' prefix
    }
    // Add spaces before capital letters
    name = name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim();
    return name;
  }

  Widget _buildContinueButton(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onContinue();
      },
      child: Container(
        width: double.infinity,
        height: size.height * 0.06,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.accent, theme.accent.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.accent.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            l10n.continueText,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Level Up card widget – shown in-flow on the game complete screen (not overlay).
  Widget _buildLevelUpCard(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    final rank = widget.newLevelData.rank;
    final prevLevel = widget.previousLevelData.level;
    final prevProgress = widget.previousLevelData.levelProgress;

    return AnimatedBuilder(
      animation:
          Listenable.merge([_levelUpFillController, _levelUpTextController]),
      builder: (context, child) {
        final fillT =
            Curves.easeOutCubic.transform(_levelUpFillController.value);
        final barProgress = prevProgress + (1.0 - prevProgress) * fillT;
        final textT = Curves.easeOut.transform(_levelUpTextController.value);
        final textOpacity = textT;
        final textScale = 0.92 + 0.08 * textT;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: 14.w,
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
                  Text(rank.icon, style: TextStyle(fontSize: 26.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedRank(l10n, rank),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          'Level $prevLevel',
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final fillWidth = w * barProgress.clamp(0.0, 1.0);
                    return SizedBox(
                      height: 44.w,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: theme.isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : theme.textPrimary.withValues(alpha: 0.08),
                          ),
                          SizedBox(
                            width: fillWidth,
                            height: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.accent,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.accent.withValues(alpha: 0.4),
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
                                                  .withValues(alpha: 0.25),
                                              offset: const Offset(0, 1),
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
                    );
                  },
                ),
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lv $prevLevel',
                    style:
                        TextStyle(fontSize: 11.sp, color: theme.textSecondary),
                  ),
                  Text(
                    'Lv ${prevLevel + 1}',
                    style:
                        TextStyle(fontSize: 11.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Bootstrap.emoji_smile_fill;
      case 'Medium':
        return Bootstrap.emoji_neutral_fill;
      case 'Hard':
        return Bootstrap.emoji_frown_fill;
      case 'Expert':
        return Bootstrap.lightning_charge_fill;
      default:
        return Bootstrap.question_circle_fill;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF4CAF50);
      case 'Medium':
        return const Color(0xFFFF9800);
      case 'Hard':
        return const Color(0xFFf44336);
      case 'Expert':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  String _getLocalizedDifficulty(AppLocalizations l10n, String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return l10n.easy;
      case 'Medium':
        return l10n.medium;
      case 'Hard':
        return l10n.hard;
      case 'Expert':
        return l10n.expert;
      default:
        return difficulty;
    }
  }

  String _getLocalizedRank(AppLocalizations l10n, RankInfo rank) {
    switch (rank.rank) {
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

  String _getBreakdownLabel(AppLocalizations l10n, _XpBreakdownItem item) {
    switch (item.label) {
      case 'difficulty':
        return l10n.difficulty;
      case 'perfect':
        return l10n.perfectGame;
      case 'daily':
        return l10n.dailyChallenge;
      case 'duel':
        return l10n.duel;
      case 'streak':
        return '${item.extra} ${l10n.daily} Streak';
      case 'time':
        return l10n.fastTime;
      case 'achievement':
        return '${l10n.achievements} (${item.extra})';
      case 'xpBoost':
        return l10n.xpBoost;
      default:
        return item.label;
    }
  }
}

// Data classes
class _XpBreakdownItem {
  final IconData icon;
  final String label;
  final int xp;
  final Color color;
  final int? extra;

  _XpBreakdownItem({
    required this.icon,
    required this.label,
    required this.xp,
    required this.color,
    this.extra,
  });
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double velocity;
  final double rotation;
  final double rotationSpeed;
  final int shape;
  final double swayAmplitude;
  final double swayFreq;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
    this.shape = 0,
    this.swayAmplitude = 20,
    this.swayFreq = 2.5,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final t = (progress * particle.velocity).clamp(0.0, 1.0);
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      final sway =
          sin(progress * pi * particle.swayFreq) * particle.swayAmplitude;
      final wobble = sin(progress * pi * 2.5 + particle.x * 8) * 6;
      final x = particle.x * size.width + sway;
      final y =
          (particle.y + progress * particle.velocity) * size.height + wobble;
      final rotation =
          particle.rotation + progress * particle.rotationSpeed * 10;

      if (y > size.height + 30) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case 1:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case 2:
          final linePaint = Paint()
            ..color = particle.color.withValues(alpha: opacity)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(-particle.size, 0),
            Offset(particle.size, 0),
            linePaint,
          );
          break;
        default:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.5,
            ),
            paint,
          );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
