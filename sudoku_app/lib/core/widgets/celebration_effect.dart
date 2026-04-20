import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/lottie_loader.dart';
import '../utils/responsive_utils.dart';

/// Celebratory particle effect for correct number placement
class CelebrationEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  const CelebrationEffect({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  @override
  State<CelebrationEffect> createState() => _CelebrationEffectState();
}

class _CelebrationEffectState extends State<CelebrationEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  bool? _useLottie;

  @override
  void initState() {
    super.initState();
    _generateParticles();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _checkLottie();
  }

  Future<void> _checkLottie() async {
    final exists = await LottieLoader.assetExists('assets/lottie/effects/celebration.json');
    if (mounted) {
      setState(() => _useLottie = exists);
      if (!exists) _controller.forward();
    }
  }

  void _generateParticles() {
    final colors = [
      widget.color,
      widget.color.withValues(alpha: 0.9),
      Colors.white,
      const Color(0xFFDEE4EE),
      const Color(0xFFC4CEDB),
      widget.color.withValues(alpha: 0.65),
    ];

    const count = 20;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _random.nextDouble() * 0.5;
      final speed = _random.nextDouble() * 42 + 52;
      final size = _random.nextDouble() * 4 + 5;
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
        size: size,
        color: colors[_random.nextInt(colors.length)],
        rotationSpeed: (_random.nextDouble() - 0.5) * 14,
        shape: _random.nextInt(3),
        drift: (_random.nextDouble() - 0.5) * 18,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useLottie == true) {
      final lottieSize = 200.w;
      return IgnorePointer(
        child: Positioned(
          left: widget.position.dx - lottieSize / 2,
          top: widget.position.dy - lottieSize / 2,
          child: Lottie.asset(
            'assets/lottie/effects/celebration.json',
            width: lottieSize,
            height: lottieSize,
            repeat: false,
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                if (mounted) widget.onComplete();
              });
            },
            errorBuilder: (_, __, ___) {
              _controller.forward();
              return _buildProgrammatic();
            },
          ),
        ),
      );
    }
    return IgnorePointer(child: _buildProgrammatic());
  }

  Widget _buildProgrammatic() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CelebrationPainter(
            particles: _particles,
            progress: _controller.value,
            center: widget.position,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final int shape;
  final double drift;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    this.shape = 0,
    this.drift = 0,
  });
}

class _CelebrationPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Offset center;

  _CelebrationPainter({
    required this.particles,
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final burst =
        t < 0.22 ? Curves.easeOut.transform((t / 0.22).clamp(0.0, 1.0)) : 1.0;
    final floatInput = t < 0.22 ? 0.0 : ((t - 0.22) / 0.48).clamp(0.0, 1.0);
    final float = Curves.easeOutCubic.transform(floatInput);
    final fadeOut = t > 0.55 ? (1.0 - ((t - 0.55) / 0.45).clamp(0.0, 1.0)) : 1.0;
    final opacity = (fadeOut * (0.95 - t * 0.3)).clamp(0.0, 1.0);

    for (var particle in particles) {
      final distance = particle.speed * (burst * 0.85 + float * 0.45);
      final driftX = particle.drift * float * 0.8;
      final lift = -18 * float - t * 12;
      final x = center.dx + cos(particle.angle) * distance + driftX;
      final y = center.dy + sin(particle.angle) * distance + lift;

      final particleSize = particle.size * (1.0 - t * 0.35).clamp(0.1, double.infinity);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationSpeed * t * 2 * pi);

      switch (particle.shape) {
        case 1:
          canvas.drawCircle(Offset.zero, particleSize * 0.65, paint);
          break;
        case 2:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particleSize * 1.1,
              height: particleSize * 0.5,
            ),
            paint,
          );
          break;
        default:
          canvas.drawPath(_createStarPath(particleSize), paint);
      }

      canvas.restore();
    }
  }

  Path _createStarPath(double size) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;

      if (i == 0) {
        path.moveTo(
          cos(outerAngle) * outerRadius,
          sin(outerAngle) * outerRadius,
        );
      } else {
        path.lineTo(
          cos(outerAngle) * outerRadius,
          sin(outerAngle) * outerRadius,
        );
      }
      path.lineTo(
        cos(innerAngle) * innerRadius,
        sin(innerAngle) * innerRadius,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Ripple effect for cell selection
class RippleEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  const RippleEffect({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool? _useLottie;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 620),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _checkLottie();
  }

  Future<void> _checkLottie() async {
    final exists = await LottieLoader.assetExists('assets/lottie/effects/ripple.json');
    if (mounted) {
      setState(() => _useLottie = exists);
      if (!exists) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useLottie == true) {
      final rippleSize = 200.w;
      return Positioned(
        left: widget.position.dx - rippleSize / 2,
        top: widget.position.dy - rippleSize / 2,
        child: Lottie.asset(
          'assets/lottie/effects/ripple.json',
          width: rippleSize,
          height: rippleSize,
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              if (mounted) widget.onComplete();
            });
          },
          errorBuilder: (_, __, ___) {
            _controller.forward();
            return _buildProgrammaticRipple();
          },
        ),
      );
    }
    return _buildProgrammaticRipple();
  }

  Widget _buildProgrammaticRipple() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RipplePainter(
            progress: _controller.value,
            center: widget.position,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Offset center;
  final Color color;

  _RipplePainter({
    required this.progress,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const ringCount = 4;
    const maxRadius = 62.0;
    final p = progress.clamp(0.0, 1.0);

    for (int i = 0; i < ringCount; i++) {
      final delay = i * 0.09;
      final t = ((p - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(t);
      final radius = maxRadius * eased;
      final ringOpacity = (1.0 - t * t).clamp(0.0, 1.0) * 0.48;
      final strokeWidth = 3.0 * (1.0 - t) * (0.6 + 0.4 * (1 - t)) + 0.8;

      final paint = Paint()
        ..color = color.withValues(alpha: ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, radius, paint);
    }

    final innerT = Curves.easeOutCubic.transform(p);
    final innerRadius = maxRadius * 0.38 * innerT;
    final innerOpacity = (1.0 - p).clamp(0.0, 1.0) * 0.4;
    final innerPaint = Paint()
      ..color = color.withValues(alpha: innerOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Full-board completion sweep effect used after auto-complete.
class BoardCompletionEffect extends StatefulWidget {
  final Rect boardRect;
  final int gridSize;
  final VoidCallback onComplete;

  const BoardCompletionEffect({
    super.key,
    required this.boardRect,
    required this.onComplete,
    this.gridSize = 9,
  });

  @override
  State<BoardCompletionEffect> createState() => _BoardCompletionEffectState();
}

class _BoardCompletionEffectState extends State<BoardCompletionEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SparkleParticle> _sparkles;
  bool? _useLottie;

  @override
  void initState() {
    super.initState();
    _sparkles = _generateSparkles();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _checkLottie();
  }

  List<_SparkleParticle> _generateSparkles() {
    final rng = Random();
    final particles = <_SparkleParticle>[];
    final bw = widget.boardRect.width;
    final bh = widget.boardRect.height;
    final maxDist = sqrt(bw * bw + bh * bh) * 0.5;

    for (int i = 0; i < 42; i++) {
      final x = rng.nextDouble() * bw;
      final y = rng.nextDouble() * bh;
      final dx = x - bw * 0.5;
      final dy = y - bh * 0.5;
      final dist = sqrt(dx * dx + dy * dy) / maxDist;
      particles.add(_SparkleParticle(
        x: x,
        y: y,
        size: rng.nextDouble() * 3.5 + 1.5,
        delay: dist * 0.55 + rng.nextDouble() * 0.08,
        lifespan: 0.18 + rng.nextDouble() * 0.12,
        rotation: rng.nextDouble() * pi * 2,
        isStar: rng.nextBool(),
      ));
    }
    return particles;
  }

  Future<void> _checkLottie() async {
    final exists = await LottieLoader.assetExists('assets/lottie/effects/board_complete.json');
    if (mounted) {
      setState(() => _useLottie = exists);
      if (!exists) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useLottie == true) {
      return IgnorePointer(
        child: Lottie.asset(
          'assets/lottie/effects/board_complete.json',
          width: widget.boardRect.width,
          height: widget.boardRect.height,
          fit: BoxFit.fill,
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              if (mounted) widget.onComplete();
            });
          },
          errorBuilder: (_, __, ___) {
            _controller.forward();
            return _buildProgrammaticBoard();
          },
        ),
      );
    }
    return _buildProgrammaticBoard();
  }

  Widget _buildProgrammaticBoard() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _BoardCompletionPainter(
              progress: _controller.value,
              boardRect: widget.boardRect,
              gridSize: widget.gridSize,
              sparkles: _sparkles,
            ),
          );
        },
      ),
    );
  }
}

class _SparkleParticle {
  final double x, y, size, delay, lifespan, rotation;
  final bool isStar;
  const _SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.lifespan,
    required this.rotation,
    required this.isStar,
  });
}

class _BoardCompletionPainter extends CustomPainter {
  final double progress;
  final Rect boardRect;
  final int gridSize;
  final List<_SparkleParticle> sparkles;

  _BoardCompletionPainter({
    required this.progress,
    required this.boardRect,
    required this.gridSize,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boardRect.width <= 0 || boardRect.height <= 0 || gridSize <= 0) return;

    final t = progress.clamp(0.0, 1.0);
    final cell = boardRect.width / gridSize;
    final cx = boardRect.center.dx;
    final cy = boardRect.center.dy;
    final maxDist = sqrt(boardRect.width * boardRect.width +
            boardRect.height * boardRect.height) *
        0.5;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
    );

    // --- Layer 1: Radial golden glow expanding from center ---
    final waveT = Curves.easeOutCubic.transform((t * 1.3).clamp(0.0, 1.0));
    final waveRadius = maxDist * waveT;
    final waveOpacity = (1.0 - t * 0.7).clamp(0.0, 1.0) * 0.35;

    final wavePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: waveOpacity),
          const Color(0xFFFFA726).withValues(alpha: waveOpacity * 0.5),
          const Color(0xFFFFD54F).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: waveRadius.clamp(1.0, double.infinity),
      ));
    canvas.drawCircle(Offset(cx, cy), waveRadius, wavePaint);

    // --- Layer 2: Per-cell golden highlight based on distance from center ---
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cellCx = boardRect.left + col * cell + cell * 0.5;
        final cellCy = boardRect.top + row * cell + cell * 0.5;
        final dx = cellCx - cx;
        final dy = cellCy - cy;
        final dist = sqrt(dx * dx + dy * dy) / maxDist;

        final cellDelay = dist * 0.55;
        final cellT = ((t - cellDelay) / 0.35).clamp(0.0, 1.0);

        if (cellT <= 0) continue;

        // Fade in and out
        final cellFade = cellT < 0.5
            ? Curves.easeOut.transform(cellT * 2)
            : Curves.easeIn.transform(1.0 - (cellT - 0.5) * 2);
        final alpha = cellFade * 0.38;

        final cellRect = Rect.fromCenter(
          center: Offset(cellCx, cellCy),
          width: cell - 1,
          height: cell - 1,
        );

        // Warm golden cell glow
        final cellPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE082).withValues(alpha: alpha),
              const Color(0xFFFFC107).withValues(alpha: alpha * 0.3),
            ],
          ).createShader(cellRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(3)),
          cellPaint,
        );

        // Brief white flash at peak
        if (cellT > 0.3 && cellT < 0.6) {
          final flashT = ((cellT - 0.3) / 0.3).clamp(0.0, 1.0);
          final flashAlpha = sin(flashT * pi) * 0.25;
          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect, const Radius.circular(3)),
            Paint()
              ..color = Colors.white.withValues(alpha: flashAlpha),
          );
        }
      }
    }

    // --- Layer 3: Moving ring of light ---
    final ringT = Curves.easeOutQuart.transform((t * 1.2).clamp(0.0, 1.0));
    final ringRadius = maxDist * ringT;
    final ringWidth = 12.0 + 8.0 * (1.0 - t);
    final ringOpacity = (1.0 - t).clamp(0.0, 1.0) * 0.5;

    if (ringOpacity > 0.01) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..shader = SweepGradient(
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: ringOpacity),
            const Color(0xFFFFAB40).withValues(alpha: ringOpacity * 0.7),
            Colors.white.withValues(alpha: ringOpacity * 0.9),
            const Color(0xFFFFD54F).withValues(alpha: ringOpacity),
          ],
          stops: const [0.0, 0.33, 0.66, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(cx, cy),
          radius: ringRadius.clamp(1.0, double.infinity),
        ));

      canvas.drawCircle(Offset(cx, cy), ringRadius, ringPaint);
    }

    // --- Layer 4: Sparkle particles ---
    for (final sp in sparkles) {
      final spT = ((t - sp.delay) / sp.lifespan).clamp(0.0, 1.0);
      if (spT <= 0 || spT >= 1) continue;

      final spAlpha = sin(spT * pi);
      final spScale = 0.5 + spAlpha * 0.5;
      final sx = boardRect.left + sp.x;
      final sy = boardRect.top + sp.y;

      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(sp.rotation + spT * 1.5);
      canvas.scale(spScale);

      final spPaint = Paint()
        ..color = Colors.white.withValues(alpha: spAlpha * 0.85);

      if (sp.isStar) {
        _drawStar(canvas, sp.size * 2, spPaint);
      } else {
        canvas.drawCircle(Offset.zero, sp.size, spPaint);
      }

      canvas.restore();
    }

    // --- Layer 5: Final full-board pulse ---
    if (t > 0.7) {
      final pulseT = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
      final pulseAlpha = sin(pulseT * pi) * 0.12;
      canvas.drawRect(
        boardRect,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: pulseAlpha),
      );
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      path.moveTo(0, 0);
      path.lineTo(
        cos(angle) * size,
        sin(angle) * size,
      );
    }
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardCompletionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.boardRect != boardRect ||
        oldDelegate.gridSize != gridSize;
  }
}

/// Glow pulse effect for highlighting
class GlowPulseEffect extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool isActive;

  const GlowPulseEffect({
    super.key,
    required this.child,
    required this.color,
    this.isActive = true,
  });

  @override
  State<GlowPulseEffect> createState() => _GlowPulseEffectState();
}

class _GlowPulseEffectState extends State<GlowPulseEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowPulseEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    final t = _controller.value;
    final curveValue = Curves.easeInOutCubic.transform(t);
    final outer = 0.12 + curveValue * 0.2;
    final mid = 0.2 + curveValue * 0.35;
    final inner = 0.25 + curveValue * 0.4;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: inner),
                blurRadius: 6 + curveValue * 18,
                spreadRadius: curveValue * 4,
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: mid),
                blurRadius: 14 + curveValue * 22,
                spreadRadius: curveValue * 2,
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: outer),
                blurRadius: 28 + curveValue * 24,
                spreadRadius: curveValue * 1,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Success checkmark animation
class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final VoidCallback? onComplete;

  const SuccessCheckmark({
    super.key,
    this.size = 60,
    this.color = const Color(0xFFD8E0EB),
    this.onComplete,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;
  bool? _useLottie;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1150),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _checkLottie();
  }

  Future<void> _checkLottie() async {
    final exists = await LottieLoader.assetExists('assets/lottie/effects/checkmark.json');
    if (mounted) {
      setState(() => _useLottie = exists);
      if (!exists) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useLottie == true) {
      return Lottie.asset(
        'assets/lottie/effects/checkmark.json',
        width: widget.size,
        height: widget.size,
        repeat: false,
        onLoaded: (composition) {
          Future.delayed(composition.duration, () {
            if (mounted) widget.onComplete?.call();
          });
        },
        errorBuilder: (_, __, ___) {
          _controller.forward();
          return _buildProgrammaticCheckmark();
        },
      );
    }
    return _buildProgrammaticCheckmark();
  }

  Widget _buildProgrammaticCheckmark() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            painter: _CheckmarkPainter(
              circleProgress: _circleAnimation.value,
              checkProgress: _checkAnimation.value,
              color: widget.color,
            ),
            size: Size(widget.size, widget.size),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final circleRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      circleRect,
      -pi / 2,
      2 * pi * circleProgress,
      false,
      circlePaint,
    );

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final startX = size.width * 0.25;
      final startY = size.height * 0.5;
      final midX = size.width * 0.45;
      final midY = size.height * 0.65;
      final endX = size.width * 0.75;
      final endY = size.height * 0.35;

      path.moveTo(startX, startY);

      if (checkProgress <= 0.5) {
        final progress = checkProgress * 2;
        path.lineTo(
          startX + (midX - startX) * progress,
          startY + (midY - startY) * progress,
        );
      } else {
        path.lineTo(midX, midY);
        final progress = (checkProgress - 0.5) * 2;
        path.lineTo(
          midX + (endX - midX) * progress,
          midY + (endY - midY) * progress,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      circleProgress != oldDelegate.circleProgress ||
      checkProgress != oldDelegate.checkProgress;
}
