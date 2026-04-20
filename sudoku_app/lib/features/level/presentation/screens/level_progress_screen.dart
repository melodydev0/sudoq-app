import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/models/achievement.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/lottie_loader.dart';
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
  final bool isPremiumXpBoost; // True when 2x is a premium perk
  final List<GameXpBreakdownEntry> gameXpBreakdown;
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
    this.isPremiumXpBoost = false,
    this.gameXpBreakdown = const [],
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
  late AnimationController _levelUpTextController;
  late AnimationController _premiumBoostCardController;
  late AnimationController _premiumBoostCountController;

  // Animations
  late Animation<double> _headerScale;
  late Animation<double> _cardSlide;

  // State
  int _displayedXp = 0;
  int _totalCalculatedXp = 0; // Sum of breakdown items
  int _premiumBoostXp = 0;
  bool _showPremiumBoostAnimation = false;
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

    // Play victory sound after a short delay so it doesn't overlap
    // with the game_complete sound that was triggered on the game screen
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) SoundService().playVictory();
    });
  }

  void _calculateXpBreakdown() {
    _xpBreakdown = [];
    final mult = widget.xpBoostMultiplier.clamp(1.0, 10.0);
    final gameXp = widget.xpEarned - widget.achievementXp;

    if (widget.gameXpBreakdown.isNotEmpty) {
      for (final entry in widget.gameXpBreakdown) {
        if (entry.xp <= 0) continue;
        _xpBreakdown.add(_XpBreakdownItem(
          icon: _iconForBreakdownLabel(entry.label),
          label: entry.label,
          xp: entry.xp,
          color: _colorForBreakdownLabel(entry.label),
          extra: entry.label == 'streak' ? widget.previousLevelData.streakDays : null,
        ));
      }
    } else {
      final baseGame = (gameXp / mult).round();
      if (baseGame > 0) {
        _xpBreakdown.add(_XpBreakdownItem(
          icon: _getDifficultyIcon(widget.difficulty),
          label: 'difficulty',
          xp: baseGame,
          color: _getDifficultyColor(widget.difficulty),
        ));
      }
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

    if (widget.isPremiumXpBoost && mult > 1.0) {
      final premiumBoostItem = _xpBreakdown.where((item) => item.label == 'xpBoost');
      _premiumBoostXp = premiumBoostItem.isNotEmpty ? premiumBoostItem.first.xp : 0;
    } else {
      _premiumBoostXp = 0;
    }
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
          final baseTarget = (_totalCalculatedXp - _premiumBoostXp).clamp(0, _totalCalculatedXp);
          _displayedXp = (baseTarget * _xpCountController.value).round();
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

    _levelUpTextController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _premiumBoostCardController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _premiumBoostCountController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..addListener(() {
        if (!_showPremiumBoostAnimation) return;
        final baseTarget =
            (_totalCalculatedXp - _premiumBoostXp).clamp(0, _totalCalculatedXp);
        setState(() {
          _displayedXp =
              baseTarget + (_premiumBoostXp * _premiumBoostCountController.value).round();
        });
      });
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
    await _xpCountController.forward();

    if (widget.isPremiumXpBoost && _premiumBoostXp > 0 && mounted) {
      setState(() => _showPremiumBoostAnimation = true);
      HapticService.mediumImpact();
      _premiumBoostCardController.forward(from: 0);
      await _premiumBoostCountController.forward(from: 0);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    _progressController.forward();

    if (_showLevelUp && mounted) {
      // Level-up text must appear AFTER the old bar fills to 100%
      // _progressController phase 1 (0→0.60) lasts 0.60 × 1400ms = 840ms
      // Add a small buffer so the bar is visually full before the banner pops
      Future.delayed(const Duration(milliseconds: 950), () {
        if (mounted) _levelUpTextController.forward();
      });
    }

    // Start showing XP breakdown items one by one (runs concurrently with progress)
    for (int i = 0; i < _xpBreakdown.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _currentBreakdownIndex = i);
        HapticService.lightImpact();
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
    _levelUpTextController.dispose();
    _premiumBoostCardController.dispose();
    _premiumBoostCountController.dispose();
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

                      // Integrated level progress (single card)
                      _buildLevelProgress(l10n, theme, size,
                          highlightLevelUp: _showLevelUp),

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
    return LottieLoader.lottieOrFallback(
      assetPath: 'assets/lottie/effects/confetti.json',
      fit: BoxFit.cover,
      fallback: AnimatedBuilder(
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
      ),
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
                      color: Color(0xFFC5CEDC), size: 20),
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

              if (_showPremiumBoostAnimation && _premiumBoostXp > 0) ...[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _premiumBoostCardController,
                    curve: Curves.easeOut,
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _premiumBoostCardController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEFF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC3CCD9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Bootstrap.star_fill,
                            color: Color(0xFF98A6BB),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${l10n.premium} ${l10n.xpBoost}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8A98AD),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${(_premiumBoostXp * _premiumBoostCountController.value).round()} XP',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7E8DA4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // XP Breakdown: use remaining card space first, scroll only if it overflows.
              Expanded(
                child: ClipRect(
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
      AppLocalizations l10n, AppThemeColors theme, Size size,
      {bool highlightLevelUp = false}) {
    final rank = widget.newLevelData.rank;
    final prevLevel = widget.previousLevelData.level;
    final newLevel = widget.newLevelData.level;
    final prevProgress = widget.previousLevelData.levelProgress;
    final newProgress = widget.newLevelData.levelProgress;

    return Container(
      padding: EdgeInsets.all(size.width * 0.035),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: highlightLevelUp
            ? Border.all(
                color: const Color(0xFFBCC6D4).withValues(alpha: 0.7),
                width: 1.4,
              )
            : null,
        boxShadow: highlightLevelUp
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildRankIcon(rank),
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
                      highlightLevelUp
                          ? 'Level $newLevel reached'
                          : 'Level $newLevel',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFBCC6D4).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  highlightLevelUp
                      ? 'LV $newLevel'
                      : '${(newProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9FAABD),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          if (highlightLevelUp) ...[
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _levelUpTextController,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _levelUpTextController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE4EE).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFBCC6D4).withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    'Level ${widget.newLevelData.level} unlocked',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8E9AAF),
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final t = _progressController.value.clamp(0.0, 1.0);

              // Normal game complete: stay in same level and increase within same bar.
              if (!highlightLevelUp || newLevel <= prevLevel) {
                final eased = Curves.easeOutCubic.transform(t);
                final animatedProgress =
                    prevProgress + (newProgress - prevProgress) * eased;
                final isFull = animatedProgress >= 0.98;

                return Column(
                  children: [
                    Container(
                      decoration: isFull
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accent.withValues(alpha: 0.3),
                                  blurRadius: 10,
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
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lv $newLevel',
                          style: TextStyle(
                              fontSize: 11.sp, color: theme.textSecondary),
                        ),
                        Text(
                          'Lv ${newLevel + 1}',
                          style: TextStyle(
                              fontSize: 11.sp, color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Level up flow:
              // Phase 1 (0.00-0.60): fill old level bar to 100%
              // Phase 2 (0.60-0.72): short hold/transition
              // Phase 3 (0.72-1.00): new level bar fills from 0 to new progress
              double animatedProgress;
              int leftLevel;
              int rightLevel;
              bool isTransitioning = false;

              if (t < 0.60) {
                final p = Curves.easeOutCubic.transform((t / 0.60).clamp(0.0, 1.0));
                animatedProgress = prevProgress + (1.0 - prevProgress) * p;
                leftLevel = prevLevel;
                rightLevel = prevLevel + 1;
              } else if (t < 0.72) {
                animatedProgress = 1.0;
                leftLevel = prevLevel;
                rightLevel = prevLevel + 1;
                isTransitioning = true;
              } else {
                final p = Curves.easeOutCubic.transform(
                    ((t - 0.72) / 0.28).clamp(0.0, 1.0));
                animatedProgress = newProgress * p;
                leftLevel = newLevel;
                rightLevel = newLevel + 1;
              }

              final glow = isTransitioning || (t >= 0.72 && animatedProgress >= 0.98);

              return Column(
                children: [
                  Container(
                    decoration: glow
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: theme.accent.withValues(alpha: 0.34),
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
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lv $leftLevel',
                        style: TextStyle(fontSize: 11.sp, color: theme.textSecondary),
                      ),
                      Text(
                        'Lv $rightLevel',
                        style: TextStyle(fontSize: 11.sp, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ],
              );
            },
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
            const Color(0xFFCED6E3).withValues(alpha: 0.24),
            const Color(0xFFAAB5C5).withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3BDCC).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFBCC6D5).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Bootstrap.trophy_fill,
                color: Color(0xFF93A0B3), size: 18),
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
              color: const Color(0xFF9BA8BB),
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
              child: achievement.imagePath.isNotEmpty
                  ? Image.asset(
                      achievement.imagePath,
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => Text(
                        achievement.icon,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    )
                  : Text(
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
        HapticService.mediumImpact();
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
              color: theme.buttonText,
            ),
          ),
        ),
      ),
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
        return const Color(0xFFCED6E2);
      case 'Medium':
        return const Color(0xFFBCC6D4);
      case 'Hard':
        return const Color(0xFFA9B5C6);
      case 'Expert':
        return const Color(0xFF96A4B8);
      default:
        return Colors.grey;
    }
  }

  IconData _iconForBreakdownLabel(String label) {
    switch (label) {
      case 'difficulty':
        return _getDifficultyIcon(widget.difficulty);
      case 'performance':
        return Bootstrap.graph_up_arrow;
      case 'daily':
        return Bootstrap.calendar_day;
      case 'ranked':
        return Bootstrap.trophy_fill;
      case 'streak':
        return Bootstrap.fire;
      case 'streak_daily':
        return Bootstrap.fire;
      default:
        return Bootstrap.star_fill;
    }
  }

  Color _colorForBreakdownLabel(String label) {
    switch (label) {
      case 'difficulty':
        return _getDifficultyColor(widget.difficulty);
      case 'performance':
        return const Color(0xFF4ECDC4);
      case 'daily':
        return const Color(0xFF5B5F97);
      case 'ranked':
        return const Color(0xFF3498DB);
      case 'streak':
        return const Color(0xFFFF8C00);
      case 'streak_daily':
        return const Color(0xFFFF6B35);
      default:
        return const Color(0xFF9B59B6);
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

  Widget _buildRankIcon(RankInfo rank) {
    if (rank.imagePath != null) {
      return Image.asset(
        rank.imagePath!,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) =>
            Text(rank.icon, style: TextStyle(fontSize: 24.sp)),
      );
    }
    return Text(rank.icon, style: TextStyle(fontSize: 24.sp));
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
      case 'performance':
        return l10n.performanceBonus;
      case 'perfect':
        return l10n.perfectGame;
      case 'daily':
        return l10n.dailyChallenge;
      case 'ranked':
        return l10n.ranked;
      case 'duel':
        return l10n.duel;
      case 'streak':
        return '${item.extra ?? 0} ${l10n.daily} ${l10n.streak}';
      case 'streak_daily':
        return l10n.dailyStreakReward;
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
