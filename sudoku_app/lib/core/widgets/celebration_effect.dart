import 'dart:math';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _generateParticles();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 720),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  void _generateParticles() {
    final colors = [
      widget.color,
      widget.color.withValues(alpha: 0.9),
      Colors.white,
      const Color(0xFFFFD700),
      const Color(0xFF4ADE80),
      widget.color.withValues(alpha: 0.6),
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
    final burst =
        progress < 0.22 ? Curves.easeOut.transform(progress / 0.22) : 1.0;
    final float = progress < 0.22
        ? 0.0
        : Curves.easeOutCubic.transform((progress - 0.22) / 0.48);
    final fadeOut = progress > 0.55 ? (1.0 - (progress - 0.55) / 0.45) : 1.0;
    final opacity = (fadeOut * (0.95 - progress * 0.3)).clamp(0.0, 1.0);

    for (var particle in particles) {
      final distance = particle.speed * (burst * 0.85 + float * 0.45);
      final driftX = particle.drift * float * 0.8;
      final lift = -18 * float - progress * 12;
      final x = center.dx + cos(particle.angle) * distance + driftX;
      final y = center.dy + sin(particle.angle) * distance + lift;

      final particleSize = particle.size * (1.0 - progress * 0.35);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationSpeed * progress * 2 * pi);

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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    for (int i = 0; i < ringCount; i++) {
      final delay = i * 0.09;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
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

    final innerT = Curves.easeOutCubic.transform(progress);
    final innerRadius = maxRadius * 0.38 * innerT;
    final innerOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.4;
    final innerPaint = Paint()
      ..color = color.withValues(alpha: innerOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
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
    this.color = const Color(0xFF4ADE80),
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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
