import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../home/presentation/screens/home_screen.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key});

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _cardController;

  late Animation<double> _titleOpacity;
  late Animation<double> _titleSlide;

  int? _selectedIndex;

  final List<_ExperienceOption> _options = [
    _ExperienceOption(
      title: "I'm a Beginner",
      subtitle: 'New to Sudoku puzzles',
      icon: Icons.emoji_nature_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      ),
      level: 'beginner',
    ),
    _ExperienceOption(
      title: "I've Played Before",
      subtitle: 'Familiar with the basics',
      icon: Icons.trending_up_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      ),
      level: 'intermediate',
    ),
    _ExperienceOption(
      title: "I'm an Expert",
      subtitle: 'Ready for challenges',
      icon: Icons.workspace_premium_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      ),
      level: 'expert',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _contentController.forward();
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _onSelectOption(int index) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedIndex = index);

    await Future.delayed(const Duration(milliseconds: 300));

    final level = _options[index].level;
    await StorageService.setExperienceLevel(level);
    await StorageService.setFirstLaunchComplete();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      sin(_backgroundController.value * 2 * pi) * 0.5,
                      cos(_backgroundController.value * 2 * pi) * 0.5 - 1,
                    ),
                    end: Alignment(
                      -sin(_backgroundController.value * 2 * pi) * 0.5,
                      -cos(_backgroundController.value * 2 * pi) * 0.5 + 1,
                    ),
                    colors: const [
                      Color(0xFFF5F7FF),
                      Color(0xFFEEF2FF),
                      Color(0xFFFAF5FF),
                    ],
                  ),
                ),
              );
            },
          ),

          // Decorative elements
          _buildDecorativeElements(),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Title
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gradientStart
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.psychology_rounded,
                                      size: 18,
                                      color: AppColors.gradientStart,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Quick Setup',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gradientStart,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF1A1A2E),
                                    Color(0xFF3D5A80),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'What\'s your\nexperience level?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'We\'ll personalize your puzzle difficulty',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Options
                  ..._options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return _buildOptionCard(option, index);
                  }),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeElements() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _backgroundController.value * 2 * pi * 0.1,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gradientStart.withValues(alpha: 0.12),
                        AppColors.gradientStart.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -100,
          right: -60,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_backgroundController.value * 2 * pi * 0.08,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gradientEnd.withValues(alpha: 0.1),
                        AppColors.gradientEnd.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Floating numbers
        ..._buildFloatingNumbers(),
      ],
    );
  }

  List<Widget> _buildFloatingNumbers() {
    final numbers = [
      {'num': '9', 'top': 120.0, 'left': 30.0, 'size': 28.0, 'opacity': 0.08},
      {'num': '3', 'top': 200.0, 'right': 40.0, 'size': 32.0, 'opacity': 0.06},
      {
        'num': '7',
        'bottom': 250.0,
        'left': 50.0,
        'size': 36.0,
        'opacity': 0.07
      },
      {
        'num': '1',
        'bottom': 180.0,
        'right': 60.0,
        'size': 24.0,
        'opacity': 0.09
      },
      {'num': '5', 'top': 350.0, 'left': 20.0, 'size': 30.0, 'opacity': 0.05},
    ];

    return numbers.map((n) {
      return Positioned(
        top: n['top'] as double?,
        bottom: n['bottom'] as double?,
        left: n['left'] as double?,
        right: n['right'] as double?,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            final offset = sin(_backgroundController.value * 2 * pi) * 10;
            return Transform.translate(
              offset: Offset(offset, offset * 0.5),
              child: Text(
                n['num'] as String,
                style: TextStyle(
                  fontSize: n['size'] as double,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gradientStart
                      .withValues(alpha: n['opacity'] as double),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildOptionCard(_ExperienceOption option, int index) {
    final isSelected = _selectedIndex == index;

    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        final delay = index * 0.15;
        final progress =
            ((_cardController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        final slideOffset = Curves.easeOutCubic.transform(progress);
        final opacity = Curves.easeOut.transform(progress);

        return Transform.translate(
          offset: Offset(0, 50 * (1 - slideOffset)),
          child: Opacity(
            opacity: opacity,
            child: _buildCardContent(option, index, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(
      _ExperienceOption option, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _onSelectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.gradientStart.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.gradientStart.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 25 : 15,
              offset: Offset(0, isSelected ? 12 : 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: option.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (option.gradient.colors.first)
                              .withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                option.icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.gradientStart
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gradientStart.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: isSelected
                    ? AppColors.gradientStart
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String level;

  _ExperienceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.level,
  });
}
