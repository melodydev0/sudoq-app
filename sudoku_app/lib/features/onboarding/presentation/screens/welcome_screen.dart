import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../home/presentation/screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _buttonController;
  late AnimationController _gridController;

  late Animation<double> _titleOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _gridScale;
  late Animation<double> _gridRotation;
  late Animation<double> _descriptionOpacity;
  late Animation<double> _descriptionSlide;
  late Animation<double> _buttonScale;
  late Animation<double> _buttonOpacity;

  final List<_AnimatedCell> _gridCells = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _initAnimations();
    _generateGridCells();
  }

  void _initAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _gridController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Title animations
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Grid animations
    _gridScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );

    _gridRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Description animations
    _descriptionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _descriptionSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    // Button animations
    _buttonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
      _gridController.forward();
    });
  }

  void _generateGridCells() {
    final numbers = [
      [7, 2, 0, 1, 4],
      [0, 0, 0, 8, 9],
      [3, 5, 7, 0, 2],
      [0, 4, 0, 3, 0],
      [1, 3, 2, 8, 0],
    ];

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        _gridCells.add(_AnimatedCell(
          number: numbers[row][col],
          row: row,
          col: col,
          delay: (row + col) * 0.05,
        ));
      }
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _onAccept() {
    HapticFeedback.mediumImpact();

    // Mark first launch as complete
    StorageService.setFirstLaunchComplete();

    // Go directly to home screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
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
                      cos(_backgroundController.value * 2 * pi) * 0.5,
                      sin(_backgroundController.value * 2 * pi) * 0.5 - 1,
                    ),
                    end: Alignment(
                      -cos(_backgroundController.value * 2 * pi) * 0.5,
                      -sin(_backgroundController.value * 2 * pi) * 0.5 + 1,
                    ),
                    colors: const [
                      Color(0xFFF0F4FF),
                      Color(0xFFE8EFFF),
                      Color(0xFFF5F0FF),
                    ],
                  ),
                ),
              );
            },
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _backgroundController.value * 2 * pi * 0.1,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gradientStart.withValues(alpha: 0.15),
                          AppColors.gradientStart.withValues(alpha: 0.05),
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
            bottom: -120,
            left: -80,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_backgroundController.value * 2 * pi * 0.08,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gradientEnd.withValues(alpha: 0.12),
                          AppColors.gradientEnd.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF1A1A2E),
                                    Color(0xFF3D5A80),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'Welcome to',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'SudoQ',
                                  style: TextStyle(
                                    fontSize: 42.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Animated Sudoku Grid
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_contentController, _gridController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _gridScale.value,
                        child: Transform.rotate(
                          angle: _gridRotation.value,
                          child: _buildAnimatedGrid(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Description
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _descriptionSlide.value),
                        child: Opacity(
                          opacity: _descriptionOpacity.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.gradientStart
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'To enhance your experience, please review our',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gradientStart,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' and ',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gradientStart,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Accept Button
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_contentController, _buttonController]),
                    builder: (context, child) {
                      final pulseScale =
                          1.0 + sin(_buttonController.value * 2 * pi) * 0.02;
                      return Transform.scale(
                        scale: _buttonScale.value * pulseScale,
                        child: Opacity(
                          opacity: _buttonOpacity.value,
                          child: _buildAcceptButton(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGrid() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Grid lines
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _WelcomeGridPainter(),
              ),
            ),
          ),
          // Pencil icon
          Positioned(
            right: 5,
            top: 25,
            child: Transform.rotate(
              angle: 0.3,
              child: Image.asset(
                'assets/images/pencil.png',
                width: 70,
                height: 70,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),
          // Numbers
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  final cell = _gridCells[index];
                  return AnimatedBuilder(
                    animation: _gridController,
                    builder: (context, child) {
                      final delay = cell.delay;
                      final progress =
                          ((_gridController.value - delay) / (1 - delay))
                              .clamp(0.0, 1.0);
                      final scale = Curves.elasticOut.transform(progress);

                      return Transform.scale(
                        scale: scale,
                        child: _buildGridCell(cell),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(_AnimatedCell cell) {
    final isHighlighted = (cell.row == 2 && cell.col == 1) ||
        (cell.row == 2 && cell.col == 3) ||
        (cell.row == 1 && cell.col == 2);

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.gradientStart.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          cell.number == 0 ? '' : '${cell.number}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: isHighlighted
                ? AppColors.gradientStart
                : AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptButton() {
    return GestureDetector(
      onTap: _onAccept,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF764BA2).withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Agree & Continue',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..strokeWidth = 1.5;

    // Draw grid lines
    for (int i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedCell {
  final int number;
  final int row;
  final int col;
  final double delay;

  _AnimatedCell({
    required this.number,
    required this.row,
    required this.col,
    required this.delay,
  });
}
