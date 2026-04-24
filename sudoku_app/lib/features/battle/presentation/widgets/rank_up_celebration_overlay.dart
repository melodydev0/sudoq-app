import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:sudoku_app/core/services/sound_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/division_badge.dart';

class RankUpCelebrationOverlay extends StatefulWidget {
  final String fromRank;
  final String toRank;
  final VoidCallback onDismiss;

  const RankUpCelebrationOverlay({
    super.key,
    required this.fromRank,
    required this.toRank,
    required this.onDismiss,
  });

  @override
  State<RankUpCelebrationOverlay> createState() =>
      _RankUpCelebrationOverlayState();
}

class _RankUpCelebrationOverlayState extends State<RankUpCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _phaseController;
  late AnimationController _particleController;
  late AnimationController _glowPulseController;
  late AnimationController _shimmerController;

  // Phase 1: Backdrop + old rank entrance
  late Animation<double> _backdropOpacity;
  late Animation<double> _oldRankOpacity;
  late Animation<double> _oldRankScale;

  // Phase 2: Old rank shatter/dissolve
  late Animation<double> _oldRankDissolve;

  // Phase 3: Light burst + new rank reveal
  late Animation<double> _burstOpacity;
  late Animation<double> _burstScale;
  late Animation<double> _newRankScale;
  late Animation<double> _newRankOpacity;

  // Phase 4: Title + subtitle
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;

  // Phase 5: Tap hint
  late Animation<double> _hintOpacity;

  @override
  void initState() {
    super.initState();

    _phaseController = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );

    _glowPulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    // Phase 1: 0.00 - 0.15 → backdrop + old rank fades in
    _backdropOpacity = Tween<double>(begin: 0, end: 0.88).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.0, 0.12, curve: Curves.easeOut),
      ),
    );
    _oldRankOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.04, 0.16, curve: Curves.easeOut),
      ),
    );
    _oldRankScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.04, 0.16, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 2: 0.16 - 0.32 → old rank dissolves out
    _oldRankDissolve = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.18, 0.36, curve: Curves.easeInCubic),
      ),
    );

    // Phase 3: 0.30 - 0.58 → light burst + new rank emerges
    _burstOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 65),
    ]).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.30, 0.52, curve: Curves.easeOut),
      ),
    );
    _burstScale = Tween<double>(begin: 0.3, end: 2.8).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.30, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _newRankScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.36, 0.58, curve: Curves.elasticOut),
      ),
    );
    _newRankOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.34, 0.48, curve: Curves.easeOut),
      ),
    );

    // Phase 4: 0.55 - 0.78 → title and subtitle
    _titleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.55, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.55, 0.70, curve: Curves.easeOut),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.65, 0.80, curve: Curves.easeOut),
      ),
    );

    // Phase 5: 0.80+ → tap hint
    _hintOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _phaseController,
        curve: const Interval(0.82, 0.95, curve: Curves.easeOut),
      ),
    );

    _phaseController.forward();
    _particleController.forward();
    _glowPulseController.repeat(reverse: true);
    _shimmerController.repeat();

    HapticService.heavyImpact();
    SoundService().playRankUp();

    // Second haptic at burst
    Future.delayed(const Duration(milliseconds: 1140), () {
      if (mounted) HapticService.mediumImpact();
    });
    // Third haptic at new rank land
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) HapticService.lightImpact();
    });
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _particleController.dispose();
    _glowPulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Color _rankColor(String rankName) {
    return Color(LocalDuelStatsService.getDivisionColorValue(rankName));
  }

  String _localizedRank(BuildContext context, String rankName) {
    final l10n = AppLocalizations.of(context);
    switch (rankName) {
      case 'Bronze':
        return l10n.bronze;
      case 'Silver':
        return l10n.silver;
      case 'Gold':
        return l10n.gold;
      case 'Platinum':
        return l10n.platinum;
      case 'Diamond':
        return l10n.diamond;
      case 'Master':
        return l10n.master;
      case 'Grandmaster':
        return l10n.grandmaster;
      case 'Champion':
        return l10n.champion;
      default:
        return rankName;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final rankColor = _rankColor(widget.toRank);
    final fromColor = _rankColor(widget.fromRank);

    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _phaseController,
          _particleController,
          _glowPulseController,
          _shimmerController,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Backdrop gradient
              Opacity(
                opacity: _backdropOpacity.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Color.lerp(rankColor, Colors.black, 0.85)!,
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),

              // Layer 2: Ambient star particles
              CustomPaint(
                painter: _StarFieldPainter(
                  progress: _particleController.value,
                  color: rankColor,
                ),
                size: Size.infinite,
              ),

              // Layer 3: Rising spark particles (from bottom)
              CustomPaint(
                painter: _RisingSparksPainter(
                  progress: _particleController.value,
                  color: rankColor,
                ),
                size: Size.infinite,
              ),

              // Layer 4: Light burst
              if (_burstOpacity.value > 0.01)
                Center(
                  child: Opacity(
                    opacity: _burstOpacity.value,
                    child: Transform.scale(
                      scale: _burstScale.value,
                      child: Container(
                        width: 200.w,
                        height: 200.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              rankColor.withValues(alpha: 0.7),
                              rankColor.withValues(alpha: 0.3),
                              rankColor.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Layer 5: Confetti
              CustomPaint(
                painter: _PremiumConfettiPainter(
                  progress: _particleController.value,
                  color: rankColor,
                ),
                size: Size.infinite,
              ),

              // Layer 6: Content
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // PROMOTED title
                    Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: Opacity(
                        opacity: _titleOpacity.value,
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            final shimmerT = _shimmerController.value;
                            return LinearGradient(
                              begin: Alignment(-1.0 + 3.0 * shimmerT, 0),
                              end: Alignment(1.0 + 3.0 * shimmerT, 0),
                              colors: [
                                rankColor,
                                Colors.white,
                                rankColor,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            AppLocalizations.of(context).promoted.toUpperCase(),
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32.w),

                    // Rank badge area
                    SizedBox(
                      height: 200.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Old rank (dissolves)
                          if (_oldRankDissolve.value < 1.0)
                            Opacity(
                              opacity: (1.0 - _oldRankDissolve.value) *
                                  _oldRankOpacity.value,
                              child: Transform.scale(
                                scale: _oldRankScale.value *
                                    (1.0 - _oldRankDissolve.value * 0.3),
                                child: _buildRankBadge(
                                  context,
                                  widget.fromRank,
                                  fromColor,
                                  isNew: false,
                                ),
                              ),
                            ),


                          // New rank badge
                          if (_newRankOpacity.value > 0.01)
                            Opacity(
                              opacity: _newRankOpacity.value,
                              child: Transform.scale(
                                scale: _newRankScale.value,
                                child: _buildRankBadge(
                                  context,
                                  widget.toRank,
                                  rankColor,
                                  isNew: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.w),

                    // Rank name text
                    Opacity(
                      opacity: _subtitleOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            _localizedRank(context, widget.toRank)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: rankColor,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: rankColor.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32.w,
                                height: 1,
                                color: rankColor.withValues(alpha: 0.4),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DivisionBadge(rank: widget.fromRank, size: 24.w),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                                      child: Text(
                                        '→',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    DivisionBadge(rank: widget.toRank, size: 24.w),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32.w,
                                height: 1,
                                color: rankColor.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Tap to continue hint
                    Opacity(
                      opacity: _hintOpacity.value,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40.w),
                        child: Text(
                          AppLocalizations.of(context).continueGame,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(
    BuildContext context,
    String rank,
    Color color, {
    required bool isNew,
  }) {
    final imagePath = LocalDuelStatsService.getRankImagePath(rank);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140.w,
          height: 140.w,
          child: imagePath != null
              ? Image.asset(
                  imagePath,
                  width: 140.w,
                  height: 140.w,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildFallbackIcon(rank, color),
                )
              : _buildFallbackIcon(rank, color),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon(String rank, Color color) {
    return Center(
      child: Text(
        LocalDuelStatsService.getRankEmoji(rank),
        style: TextStyle(fontSize: 52.sp),
      ),
    );
  }
}

// Ambient twinkling stars
class _StarFieldPainter extends CustomPainter {
  final double progress;
  final Color color;
  late final List<_Star> _stars;

  _StarFieldPainter({required this.progress, required this.color})
      : _stars = _generateStars(color);

  static List<_Star> _generateStars(Color color) {
    final rng = math.Random(7);
    return List.generate(50, (i) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble() * 2.5,
        twinkleSpeed: 1.5 + rng.nextDouble() * 3.0,
        twinkleOffset: rng.nextDouble() * math.pi * 2,
        color: Color.lerp(color, Colors.white, 0.3 + rng.nextDouble() * 0.7)!,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final twinkle =
          (math.sin(progress * math.pi * 2 * s.twinkleSpeed + s.twinkleOffset) +
                  1) /
              2;
      final opacity = (0.15 + twinkle * 0.6) * math.min(progress * 5, 1.0);
      final paint = Paint()
        ..color = s.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size * (0.6 + twinkle * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) =>
      old.progress != progress;
}

class _Star {
  final double x, y, size, twinkleSpeed, twinkleOffset;
  final Color color;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.color,
  });
}

// Rising sparks from bottom edges
class _RisingSparksPainter extends CustomPainter {
  final double progress;
  final Color color;
  late final List<_Spark> _sparks;

  _RisingSparksPainter({required this.progress, required this.color})
      : _sparks = _generateSparks(color);

  static List<_Spark> _generateSparks(Color color) {
    final rng = math.Random(13);
    return List.generate(35, (i) {
      return _Spark(
        startX: rng.nextDouble(),
        speed: 0.4 + rng.nextDouble() * 0.6,
        delay: rng.nextDouble() * 0.5,
        size: 2.0 + rng.nextDouble() * 3.0,
        swayAmp: 15 + rng.nextDouble() * 25,
        swayFreq: 2.0 + rng.nextDouble() * 3.0,
        color: Color.lerp(color, Colors.white, rng.nextDouble() * 0.5)!,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _sparks) {
      final t = ((progress - s.delay) * s.speed).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final y = size.height * (1.0 - t);
      final sway = math.sin(t * math.pi * s.swayFreq) * s.swayAmp;
      final x = s.startX * size.width + sway;
      final fadeIn = math.min(t * 8, 1.0);
      final fadeOut = t > 0.7 ? (1.0 - t) / 0.3 : 1.0;
      final opacity = (fadeIn * fadeOut * 0.7).clamp(0.0, 1.0);

      final paint = Paint()..color = s.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), s.size * (0.5 + t * 0.5), paint);

      // Trail
      if (t > 0.05) {
        final trailPaint = Paint()
          ..color = s.color.withValues(alpha: opacity * 0.3);
        canvas.drawCircle(
            Offset(x - sway * 0.15, y + 12), s.size * 0.5, trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RisingSparksPainter old) =>
      old.progress != progress;
}

class _Spark {
  final double startX, speed, delay, size, swayAmp, swayFreq;
  final Color color;
  const _Spark({
    required this.startX,
    required this.speed,
    required this.delay,
    required this.size,
    required this.swayAmp,
    required this.swayFreq,
    required this.color,
  });
}

// Premium confetti with rank-colored particles
class _PremiumConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  late final List<_ConfettiPiece> _pieces;

  _PremiumConfettiPainter({required this.progress, required this.color})
      : _pieces = _generate(color);

  static List<_ConfettiPiece> _generate(Color rankColor) {
    final rng = math.Random(42);
    final colors = [
      rankColor,
      Color.lerp(rankColor, Colors.white, 0.3)!,
      Color.lerp(rankColor, Colors.white, 0.6)!,
      Colors.white,
      Color.lerp(rankColor, const Color(0xFFFFD700), 0.4)!,
    ];
    return List.generate(80, (i) {
      return _ConfettiPiece(
        x: rng.nextDouble(),
        startY: -0.15 - rng.nextDouble() * 0.3,
        speed: 0.3 + rng.nextDouble() * 0.5,
        delay: 0.15 + rng.nextDouble() * 0.25,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 10,
        color: colors[rng.nextInt(colors.length)],
        width: 4 + rng.nextDouble() * 8,
        height: 2.5 + rng.nextDouble() * 5,
        shape: rng.nextInt(3),
        swayAmp: 20 + rng.nextDouble() * 35,
        swayFreq: 1.5 + rng.nextDouble() * 2.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fallDist = size.height * 1.4;

    for (final p in _pieces) {
      final t = ((progress - p.delay) * p.speed * 2).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final eased = Curves.easeOutQuad.transform(t);
      final y = p.startY * size.height + fallDist * eased;
      final sway =
          math.sin(t * math.pi * p.swayFreq + p.rotation) * p.swayAmp;
      final wobble = math.sin(t * math.pi * 4 + p.x * 8) * 6;
      final x = p.x * size.width + sway + wobble;

      final fadeIn = math.min(t * 6, 1.0);
      final fadeOut = t > 0.8 ? (1.0 - t) / 0.2 : 1.0;
      final opacity = (fadeIn * fadeOut).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.85);
      final rotation = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (p.shape) {
        case 0:
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.width, height: p.height),
            paint,
          );
          break;
        case 1:
          canvas.drawCircle(Offset.zero, p.width * 0.4, paint);
          break;
        case 2:
          final lPaint = Paint()
            ..color = p.color.withValues(alpha: opacity * 0.85)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
              Offset(-p.width * 0.5, 0), Offset(p.width * 0.5, 0), lPaint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumConfettiPainter old) =>
      old.progress != progress;
}

class _ConfettiPiece {
  final double x, startY, speed, delay, rotation, rotationSpeed;
  final double width, height, swayAmp, swayFreq;
  final Color color;
  final int shape;
  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.delay,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.width,
    required this.height,
    required this.shape,
    required this.swayAmp,
    required this.swayFreq,
  });
}
