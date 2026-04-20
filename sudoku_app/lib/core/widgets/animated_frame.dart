import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cosmetic_rewards.dart';
import '../utils/lottie_loader.dart';
import '../utils/responsive_utils.dart';

/// Premium animated avatar frame widget with double-layer design
class AnimatedAvatarFrame extends StatefulWidget {
  final FrameReward? frame;
  final Widget child;
  final double size;
  final bool showAnimation;

  const AnimatedAvatarFrame({
    super.key,
    this.frame,
    required this.child,
    this.size = 72,
    this.showAnimation = true,
  });

  @override
  State<AnimatedAvatarFrame> createState() => _AnimatedAvatarFrameState();
}

class _AnimatedAvatarFrameState extends State<AnimatedAvatarFrame>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    if (widget.showAnimation && widget.frame != null) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    final frameId = widget.frame?.id ?? '';

    if (frameId.isNotEmpty && frameId != 'frame_basic') {
      _pulseController.repeat(reverse: true);
    }

    if (_isPremiumFrame(frameId)) {
      _shimmerController.repeat();
    }

    // Rotating animation for special frames
    if (frameId == 'frame_legendary' ||
        frameId == 'frame_gold' ||
        frameId == 'frame_rainbow' ||
        frameId == 'ranked_frame_champion' ||
        frameId == 'ranked_frame_legend' ||
        frameId == 'ranked_frame_grandmaster' ||
        frameId == 'ranked_frame_master') {
      _rotationController.repeat();
    }
  }

  bool _isPremiumFrame(String frameId) {
    return [
      'frame_gold', 'frame_platinum', 'frame_rainbow', 'frame_emerald',
      'frame_ruby', 'frame_sapphire', 'frame_amethyst', 'frame_crystal',
      'frame_obsidian', 'frame_legendary',
      // Ranked frames
      'ranked_frame_platinum', 'ranked_frame_diamond', 'ranked_frame_master',
      'ranked_frame_grandmaster', 'ranked_frame_champion',
      'ranked_frame_legend',
    ].contains(frameId);
  }

  @override
  void didUpdateWidget(AnimatedAvatarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame?.id != widget.frame?.id) {
      _rotationController.stop();
      _rotationController.reset();
      _pulseController.stop();
      _pulseController.reset();
      _shimmerController.stop();
      _shimmerController.reset();

      if (widget.showAnimation && widget.frame != null) {
        _startAnimations();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);

    if (widget.frame == null || widget.frame!.id == 'frame_basic') {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_rotationController, _pulseController, _shimmerController]),
      builder: (context, child) => _buildDoubleLayerFrame(),
    );
  }

  Widget _buildDoubleLayerFrame() {
    final frame = widget.frame!;
    final frameId = frame.id;
    final innerSize = widget.size.w;
    final outerBorderWidth = 4.w;
    final innerBorderWidth = 2.w;
    final totalSize = innerSize + (outerBorderWidth + innerBorderWidth) * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          _buildOuterGlow(frameId, totalSize),

          // Outer frame layer
          _buildOuterFrame(frameId, totalSize, outerBorderWidth),

          // Inner frame layer (metallic/accent)
          _buildInnerFrame(
              frameId, innerSize + innerBorderWidth * 2, innerBorderWidth),

          // Shimmer effect
          if (_isPremiumFrame(frameId)) _buildShimmerEffect(totalSize),

          // Avatar content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildOuterGlow(String frameId, double size) {
    final colors = _getFrameColors(frameId);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: size + 8.w,
          height: size + 8.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.w),
            boxShadow: [
              BoxShadow(
                color: colors['primary']!
                    .withValues(alpha: 0.4 * _pulseAnimation.value),
                blurRadius: 12 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
              if (colors['secondary'] != null)
                BoxShadow(
                  color: colors['secondary']!
                      .withValues(alpha: 0.2 * _pulseAnimation.value),
                  blurRadius: 20 * _pulseAnimation.value,
                  spreadRadius: 4 * _pulseAnimation.value,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOuterFrame(String frameId, double size, double borderWidth) {
    final colors = _getFrameColors(frameId);

    // Special rotating gradient for legendary and gold
    if (frameId == 'frame_legendary') {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFF0000),
                  Color(0xFFFF7F00),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF0000FF),
                  Color(0xFF4B0082),
                  Color(0xFF9400D3),
                  Color(0xFFFF0000),
                ],
                transform:
                    GradientRotation(_rotationController.value * 2 * math.pi),
              ),
            ),
          );
        },
      );
    }

    if (frameId == 'frame_gold') {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFF8DC),
                  Color(0xFFFFD700),
                  Color(0xFFDAA520),
                  Color(0xFFFFD700),
                  Color(0xFFFFF8DC),
                  Color(0xFFFFD700),
                ],
                transform:
                    GradientRotation(_rotationController.value * 2 * math.pi),
              ),
            ),
          );
        },
      );
    }

    // Rainbow frame - rotating rainbow gradient
    if (frameId == 'frame_rainbow') {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFF0000), // Red
                  Color(0xFFFF7F00), // Orange
                  Color(0xFFFFFF00), // Yellow
                  Color(0xFF00FF00), // Green
                  Color(0xFF0000FF), // Blue
                  Color(0xFF4B0082), // Indigo
                  Color(0xFF9400D3), // Violet
                  Color(0xFFFF0000), // Red (repeat for seamless)
                ],
                transform:
                    GradientRotation(_rotationController.value * 2 * math.pi),
              ),
            ),
          );
        },
      );
    }

    // Platinum frame - shiny metallic
    if (frameId == 'frame_platinum' || frameId == 'ranked_frame_platinum') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.w),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE5E4E2),
              Color(0xFFFFFFFF),
              Color(0xFF6DD5FA),
              Color(0xFFE5E4E2),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6DD5FA).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }

    // Champion frame - rotating gold/orange
    if (frameId == 'ranked_frame_champion') {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFF6F00),
                  Color(0xFFFFD700),
                  Color(0xFFFFA000),
                  Color(0xFFFFE135),
                  Color(0xFFFF6F00),
                ],
                transform:
                    GradientRotation(_rotationController.value * 2 * math.pi),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
          );
        },
      );
    }

    // Grandmaster frame - rotating purple
    if (frameId == 'ranked_frame_grandmaster') {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF9400D3),
                  Color(0xFFDA70D6),
                  Color(0xFF8A2BE2),
                  Color(0xFFBA55D3),
                  Color(0xFF9400D3),
                ],
                transform:
                    GradientRotation(_rotationController.value * 2 * math.pi),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9400D3).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
          );
        },
      );
    }

    // Master frame - rotating gold
    if (frameId == 'ranked_frame_master') {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFF8DC),
                  Color(0xFFFFE135),
                  Color(0xFFFFA500),
                  Color(0xFFFFD700),
                ],
                transform:
                    GradientRotation(_rotationController.value * 2 * math.pi),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      );
    }

    // Diamond frame - shiny cyan
    if (frameId == 'ranked_frame_diamond') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.w),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00BFFF),
              Color(0xFF87CEEB),
              Color(0xFF00CED1),
              Color(0xFF1E90FF),
              Color(0xFF00BFFF),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFFF).withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.w),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors['primary']!,
            colors['highlight']!,
            colors['primary']!,
            colors['dark']!,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildInnerFrame(String frameId, double size, double borderWidth) {
    final colors = _getFrameColors(frameId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.w),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors['innerLight']!,
            colors['innerDark']!,
          ],
        ),
        border: Border.all(
          color: colors['borderAccent']!.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildShimmerEffect(double size) {
    return LottieLoader.lottieOrFallback(
      assetPath: 'assets/lottie/frames/frame_shimmer.json',
      width: size,
      height: size,
      repeat: true,
      fallback: _buildProgrammaticShimmer(size),
    );
  }

  Widget _buildProgrammaticShimmer(double size) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16.w),
          child: SizedBox(
            width: size,
            height: size,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: [
                    (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                    _shimmerAnimation.value.clamp(0.0, 1.0),
                    (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        );
      },
    );
  }

  Map<String, Color> _getFrameColors(String frameId) {
    switch (frameId) {
      case 'frame_silver':
        return {
          'primary': const Color(0xFFC0C0C0),
          'highlight': const Color(0xFFE8E8E8),
          'dark': const Color(0xFF808080),
          'secondary': const Color(0xFFD3D3D3),
          'innerLight': const Color(0xFFF5F5F5),
          'innerDark': const Color(0xFFDCDCDC),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      case 'frame_gold':
        return {
          'primary': const Color(0xFFFFD700),
          'highlight': const Color(0xFFFFF8DC),
          'dark': const Color(0xFFB8860B),
          'secondary': const Color(0xFFFFA500),
          'innerLight': const Color(0xFFFFFACD),
          'innerDark': const Color(0xFFFFE4B5),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      case 'frame_bronze':
        return {
          'primary': const Color(0xFFCD7F32),
          'highlight': const Color(0xFFDEB887),
          'dark': const Color(0xFF8B4513),
          'secondary': const Color(0xFFD2691E),
          'innerLight': const Color(0xFFFFE4C4),
          'innerDark': const Color(0xFFDEB887),
          'borderAccent': const Color(0xFFFFDEAD),
        };
      case 'frame_platinum':
        return {
          'primary': const Color(0xFFE5E4E2),
          'highlight': const Color(0xFFFFFFFF),
          'dark': const Color(0xFFA8A8A8),
          'secondary': const Color(0xFF6DD5FA),
          'innerLight': const Color(0xFFF8F8FF),
          'innerDark': const Color(0xFFE6E6FA),
          'borderAccent': const Color(0xFF87CEEB),
        };
      case 'frame_rainbow':
        return {
          'primary': const Color(0xFFFF0000),
          'highlight': const Color(0xFFFFFF00),
          'dark': const Color(0xFF0000FF),
          'secondary': const Color(0xFF00FF00),
          'innerLight': const Color(0xFFFFF0F5),
          'innerDark': const Color(0xFFE6E6FA),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      case 'frame_emerald':
        return {
          'primary': const Color(0xFF50C878),
          'highlight': const Color(0xFF98FF98),
          'dark': const Color(0xFF228B22),
          'secondary': const Color(0xFF00FF7F),
          'innerLight': const Color(0xFFE0FFE0),
          'innerDark': const Color(0xFFB0FFB0),
          'borderAccent': const Color(0xFFADFF2F),
        };
      case 'frame_ruby':
        return {
          'primary': const Color(0xFFE0115F),
          'highlight': const Color(0xFFFF6B6B),
          'dark': const Color(0xFF8B0000),
          'secondary': const Color(0xFFFF1744),
          'innerLight': const Color(0xFFFFE4E1),
          'innerDark': const Color(0xFFFFB6C1),
          'borderAccent': const Color(0xFFFF69B4),
        };
      case 'frame_sapphire':
        return {
          'primary': const Color(0xFF0F52BA),
          'highlight': const Color(0xFF6495ED),
          'dark': const Color(0xFF00008B),
          'secondary': const Color(0xFF4169E1),
          'innerLight': const Color(0xFFE6E6FA),
          'innerDark': const Color(0xFFB0C4DE),
          'borderAccent': const Color(0xFF87CEEB),
        };
      case 'frame_amethyst':
        return {
          'primary': const Color(0xFF9966CC),
          'highlight': const Color(0xFFDA70D6),
          'dark': const Color(0xFF4B0082),
          'secondary': const Color(0xFFBA55D3),
          'innerLight': const Color(0xFFE6E6FA),
          'innerDark': const Color(0xFFDDA0DD),
          'borderAccent': const Color(0xFFEE82EE),
        };
      case 'frame_crystal':
        return {
          'primary': const Color(0xFFADD8E6),
          'highlight': const Color(0xFFFFFFFF),
          'dark': const Color(0xFF87CEEB),
          'secondary': const Color(0xFFE0FFFF),
          'innerLight': const Color(0xFFF0FFFF),
          'innerDark': const Color(0xFFE0FFFF),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      case 'frame_obsidian':
        return {
          'primary': const Color(0xFF1A1A2E),
          'highlight': const Color(0xFF3D3D5C),
          'dark': const Color(0xFF0D0D0D),
          'secondary': const Color(0xFF6366F1),
          'innerLight': const Color(0xFF2D2D44),
          'innerDark': const Color(0xFF1A1A2E),
          'borderAccent': const Color(0xFF8B5CF6),
        };
      case 'frame_legendary':
        return {
          'primary': const Color(0xFFFFD700),
          'highlight': const Color(0xFFFFFFFF),
          'dark': const Color(0xFFFF6B6B),
          'secondary': const Color(0xFF00FFFF),
          'innerLight': const Color(0xFFFFFACD),
          'innerDark': const Color(0xFFFFE4B5),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      // ===== RANKED FRAMES =====
      case 'ranked_frame_warrior':
        return {
          'primary': const Color(0xFF8B0000),
          'highlight': const Color(0xFFDC143C),
          'dark': const Color(0xFF4A0E0E),
          'secondary': const Color(0xFFB22222),
          'innerLight': const Color(0xFFFFCCCC),
          'innerDark': const Color(0xFFFF9999),
          'borderAccent': const Color(0xFFFF6B6B),
        };
      case 'ranked_frame_gladiator':
        return {
          'primary': const Color(0xFF4A0E0E),
          'highlight': const Color(0xFFDC143C),
          'dark': const Color(0xFF2D0808),
          'secondary': const Color(0xFF8B0000),
          'innerLight': const Color(0xFFFFCCCC),
          'innerDark': const Color(0xFFFF9999),
          'borderAccent': const Color(0xFFFF4444),
        };
      case 'ranked_frame_platinum':
        return {
          'primary': const Color(0xFFE5E4E2),
          'highlight': const Color(0xFFFFFFFF),
          'dark': const Color(0xFFA8A8A8),
          'secondary': const Color(0xFF87CEEB),
          'innerLight': const Color(0xFFF8F8FF),
          'innerDark': const Color(0xFFE6E6FA),
          'borderAccent': const Color(0xFF87CEEB),
        };
      case 'ranked_frame_diamond':
        return {
          'primary': const Color(0xFF00BFFF),
          'highlight': const Color(0xFF87CEEB),
          'dark': const Color(0xFF1E90FF),
          'secondary': const Color(0xFF00CED1),
          'innerLight': const Color(0xFFE0FFFF),
          'innerDark': const Color(0xFFB0E0E6),
          'borderAccent': const Color(0xFF00FFFF),
        };
      case 'ranked_frame_master':
        return {
          'primary': const Color(0xFFFFD700),
          'highlight': const Color(0xFFFFF8DC),
          'dark': const Color(0xFFFFA500),
          'secondary': const Color(0xFFFFE135),
          'innerLight': const Color(0xFFFFFACD),
          'innerDark': const Color(0xFFFFE4B5),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      case 'ranked_frame_grandmaster':
        return {
          'primary': const Color(0xFF9400D3),
          'highlight': const Color(0xFFDA70D6),
          'dark': const Color(0xFF8A2BE2),
          'secondary': const Color(0xFFBA55D3),
          'innerLight': const Color(0xFFE6E6FA),
          'innerDark': const Color(0xFFDDA0DD),
          'borderAccent': const Color(0xFFEE82EE),
        };
      case 'ranked_frame_champion':
        return {
          'primary': const Color(0xFFFF6F00),
          'highlight': const Color(0xFFFFD700),
          'dark': const Color(0xFFE65100),
          'secondary': const Color(0xFFFFA000),
          'innerLight': const Color(0xFFFFE0B2),
          'innerDark': const Color(0xFFFFCC80),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      case 'ranked_frame_legend':
        return {
          'primary': const Color(0xFFFF0000),
          'highlight': const Color(0xFFFFD700),
          'dark': const Color(0xFF8B0000),
          'secondary': const Color(0xFFFF4500),
          'innerLight': const Color(0xFFFFE4E1),
          'innerDark': const Color(0xFFFFCCCC),
          'borderAccent': const Color(0xFFFFFFFF),
        };
      default:
        return {
          'primary': const Color(0xFFCD7F32), // Bronze
          'highlight': const Color(0xFFDEB887),
          'dark': const Color(0xFF8B4513),
          'secondary': const Color(0xFFD2691E),
          'innerLight': const Color(0xFFFFE4C4),
          'innerDark': const Color(0xFFDEB887),
          'borderAccent': const Color(0xFFFFDEAD),
        };
    }
  }
}

/// Compact frame preview for rewards screen
class FramePreview extends StatelessWidget {
  final FrameReward frame;
  final double size;
  final bool isSelected;
  final bool isUnlocked;

  const FramePreview({
    super.key,
    required this.frame,
    this.size = 60,
    this.isSelected = false,
    this.isUnlocked = true,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.7;

    return AnimatedAvatarFrame(
      frame: isUnlocked ? frame : null,
      size: size,
      showAnimation: isUnlocked && isSelected,
      child: _buildFrameContent(innerSize),
    );
  }

  Widget _buildFrameContent(double innerSize) {
    if (isUnlocked && frame.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(innerSize * 0.2),
        child: Image.asset(
          frame.imagePath!,
          width: innerSize,
          height: innerSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildIconFallback(innerSize);
          },
        ),
      );
    }
    return _buildIconFallback(innerSize);
  }

  Widget _buildIconFallback(double innerSize) {
    return Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: frame.gradientColors,
              )
            : null,
        color: isUnlocked ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(innerSize * 0.2),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: frame.gradientColors.first.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          frame.iconData ?? Icons.star,
          color: isUnlocked ? Colors.white : Colors.grey,
          size: innerSize * 0.5,
        ),
      ),
    );
  }
}
