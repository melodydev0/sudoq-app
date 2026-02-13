import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Full-screen overlay shown when the user ranks up (e.g. Bronze → Silver).
/// Shows old rank fading out, new rank scaling in with glow, and confetti.
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
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late Animation<double> _backdropOpacity;
  late Animation<double> _oldRankScale;
  late Animation<Offset> _oldRankSlide;
  late Animation<double> _oldRankOpacity;
  late Animation<double> _newRankScale;
  late Animation<double> _newRankOpacity;
  late Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );

    _backdropOpacity = Tween<double>(begin: 0, end: 0.9).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0, 0.12, curve: Curves.easeOut)),
    );
    _oldRankScale = Tween<double>(begin: 1, end: 0.4).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.08, 0.28, curve: Curves.easeInCubic)),
    );
    _oldRankSlide =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.22, 0)).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.06, 0.26, curve: Curves.easeInCubic)),
    );
    _oldRankOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.14, 0.34, curve: Curves.easeOut)),
    );
    _newRankScale = Tween<double>(begin: 0.18, end: 1.22).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.28, 0.62, curve: Curves.elasticOut)),
    );
    _newRankOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.36, 0.56, curve: Curves.easeOutCubic)),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.48, 0.7, curve: Curves.easeOutCubic)),
    );

    _mainController.forward();
    _confettiController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _localizedRank(BuildContext context, String rankName) {
    final l10n = AppLocalizations.of(context);
    final emoji = LocalDuelStatsService.getRankEmoji(rankName);
    switch (rankName) {
      case 'Bronze':
        return '$emoji ${l10n.bronze}';
      case 'Silver':
        return '$emoji ${l10n.silver}';
      case 'Gold':
        return '$emoji ${l10n.gold}';
      case 'Platinum':
        return '$emoji ${l10n.platinum}';
      case 'Diamond':
        return '$emoji ${l10n.diamond}';
      case 'Master':
        return '$emoji ${l10n.master}';
      case 'Grandmaster':
        return '$emoji ${l10n.grandmaster}';
      case 'Champion':
        return '$emoji ${l10n.champion}';
      default:
        return '$emoji $rankName';
    }
  }

  Color _rankColor(String rankName) {
    return Color(LocalDuelStatsService.getDivisionColorValue(rankName));
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _confettiController]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop
              Opacity(
                opacity: _backdropOpacity.value,
                child: Container(color: Colors.black),
              ),
              // Confetti
              _buildConfetti(),
              // Content
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0)
                            .animate(CurvedAnimation(
                          parent: _mainController,
                          curve: const Interval(0.5, 0.72,
                              curve: Curves.elasticOut),
                        )),
                        child: Text(
                          AppLocalizations.of(context).promoted,
                          style: TextStyle(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade100,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withValues(alpha: 0.9),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2)),
                              Shadow(
                                  color: Colors.amber.withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  offset: Offset.zero),
                              Shadow(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  blurRadius: 32,
                                  offset: Offset.zero),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.w),
                    // Old rank → New rank
                    SizedBox(
                      height: 160.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FadeTransition(
                            opacity: _oldRankOpacity,
                            child: SlideTransition(
                              position: _oldRankSlide,
                              child: ScaleTransition(
                                scale: _oldRankScale,
                                child: _RankBadge(
                                  label:
                                      _localizedRank(context, widget.fromRank),
                                  color: _rankColor(widget.fromRank),
                                ),
                              ),
                            ),
                          ),
                          // New rank (scale up, fade in)
                          FadeTransition(
                            opacity: _newRankOpacity,
                            child: ScaleTransition(
                              scale: _newRankScale,
                              child: _RankBadge(
                                label: _localizedRank(context, widget.toRank),
                                color: _rankColor(widget.toRank),
                                glow: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.w),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          '${AppLocalizations.of(context).promoted} ${_localizedRank(context, widget.toRank)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Tap to continue
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 32.w),
                        child: Text(
                          AppLocalizations.of(context).continueGame,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white54,
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

  Widget _buildConfetti() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(progress: _confettiController.value),
        size: Size.infinite,
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool glow;

  const _RankBadge(
      {required this.label, required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: color, width: 3),
        boxShadow: glow
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: 32,
                    spreadRadius: 3),
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 56,
                    spreadRadius: 6),
                BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 80,
                    spreadRadius: 2),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double rotationSpeed;
  final Color color;
  final int shape; // 0 rect, 1 circle, 2 line
  final double w;
  final double h;
  final double swayAmplitude;
  final double swayFreq;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.rotationSpeed,
    required this.color,
    required this.shape,
    required this.w,
    required this.h,
    required this.swayAmplitude,
    required this.swayFreq,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> _particles;

  _ConfettiPainter({required this.progress})
      : _particles = _generateParticles();

  static List<_ConfettiParticle> _generateParticles() {
    final rng = math.Random(42);
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
      Colors.amber.shade300,
      Colors.white,
      const Color(0xFFFFE082),
      const Color(0xFFFFF8DC),
      Colors.amber.shade100,
    ];
    final list = <_ConfettiParticle>[];
    for (int i = 0; i < 90; i++) {
      final isSlow = i % 3 == 0;
      list.add(_ConfettiParticle(
        x: rng.nextDouble(),
        startY:
            isSlow ? -60 - rng.nextDouble() * 120 : -15 - rng.nextDouble() * 70,
        speed: isSlow
            ? 0.45 + rng.nextDouble() * 0.35
            : 0.75 + rng.nextDouble() * 0.55,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        color: colors[rng.nextInt(colors.length)],
        shape: rng.nextInt(3),
        w: 3.5 + rng.nextDouble() * 8,
        h: 2 + rng.nextDouble() * 5,
        swayAmplitude: 18 + rng.nextDouble() * 28,
        swayFreq: 1.8 + rng.nextDouble() * 2.4,
      ));
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fallDistance = size.height + 140;

    for (final p in _particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final sway = math.sin(progress * math.pi * p.swayFreq) * p.swayAmplitude;
      final wobble = math.sin(progress * math.pi * 3 + p.x * 10) * 8;
      final y = p.startY + fallDistance * t + wobble;
      final x = p.x * size.width + sway;
      final rotation = p.rotationSpeed * progress * math.pi;
      final opacity = t < 0.88 ? 1.0 : ((1.0 - t) / 0.12).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (p.shape) {
        case 1:
          canvas.drawCircle(Offset.zero, p.w * 0.65, paint);
          break;
        case 2:
          final linePaint = Paint()
            ..color = p.color.withValues(alpha: opacity)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(-p.w, 0), Offset(p.w, 0), linePaint);
          break;
        default:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
