import 'package:flutter/material.dart';
import '../../../../core/models/game_state.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/lottie_loader.dart';

/// Data class for tracking completed sections
class CompletedSection {
  final String type; // 'row', 'col', 'box'
  final int index;
  final DateTime completedAt;

  CompletedSection({
    required this.type,
    required this.index,
    required this.completedAt,
  });

  bool get isAnimating {
    return DateTime.now().difference(completedAt).inMilliseconds < 420;
  }
}

class SudokuGrid extends StatefulWidget {
  final GameState gameState;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int row, int col) onCellTap;
  final bool useCustomTheme;
  final List<CompletedSection> completedSections;
  final Set<int> droppingCells;

  const SudokuGrid({
    super.key,
    required this.gameState,
    this.selectedRow,
    this.selectedCol,
    required this.onCellTap,
    this.useCustomTheme = true,
    this.completedSections = const [],
    this.droppingCells = const {},
  });

  @override
  State<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends State<SudokuGrid> with TickerProviderStateMixin {
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};

  // Drop animation controllers for auto-complete cells
  final Map<int, AnimationController> _dropControllers = {};
  final Map<int, Animation<double>> _dropAnimations = {};
  final Map<int, Animation<double>> _dropBounceAnimations = {};

  @override
  void didUpdateWidget(SudokuGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger drop animations for newly dropping cells
    for (final cellKey in widget.droppingCells) {
      if (!_dropControllers.containsKey(cellKey)) {
        _createDropAnimation(cellKey);
      }
    }
    // Clean up finished drop animations
    final dropKeysToRemove = _dropControllers.keys
        .where((k) => !widget.droppingCells.contains(k) &&
            (_dropControllers[k]?.isCompleted ?? true))
        .toList();
    for (final key in dropKeysToRemove) {
      _dropControllers[key]?.dispose();
      _dropControllers.remove(key);
      _dropAnimations.remove(key);
      _dropBounceAnimations.remove(key);
    }

    // Check for new completed sections
    for (var section in widget.completedSections) {
      final key = '${section.type}_${section.index}';
      if (!_animationControllers.containsKey(key) && section.isAnimating) {
        _createAnimationForSection(key);
      }
    }

    // Remove old animations
    final activeKeys = widget.completedSections
        .where((s) => s.isAnimating)
        .map((s) => '${s.type}_${s.index}')
        .toSet();

    final keysToRemove = _animationControllers.keys
        .where((k) => !activeKeys.contains(k))
        .toList();

    for (var key in keysToRemove) {
      _animationControllers[key]?.dispose();
      _animationControllers.remove(key);
      _animations.remove(key);
    }
  }

  void _createAnimationForSection(String key) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    // Premium: pop in with slight overshoot, brief hold, then smooth settle out
    final animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(controller);

    _animationControllers[key] = controller;
    _animations[key] = animation;

    controller.forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _animationControllers[key]?.dispose();
          _animationControllers.remove(key);
          _animations.remove(key);
        });
      }
    });
  }

  void _createDropAnimation(int cellKey) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    // Drop from above with bounce
    final dropAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.bounceOut),
    );

    // Scale: start small, overshoot slightly, settle to 1.0
    final bounceAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut),
    );

    _dropControllers[cellKey] = controller;
    _dropAnimations[cellKey] = dropAnim;
    _dropBounceAnimations[cellKey] = bounceAnim;

    controller.forward();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    for (var controller in _dropControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get current GRID STYLE only (not app theme)
  // Ranked themes (champion, grandmaster) should NOT affect grid
  ThemeReward? get _gridStyle {
    final id = LevelService.selectedThemeId;
    // Skip ranked themes - they are APP themes, not grid styles
    if (id.startsWith('ranked_theme_')) return null;
    return LevelService.selectedTheme;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.gameState.gridSize;
    final boxSize = size == 9 ? 3 : 4;

    // Use app theme manager for consistent dark/light mode detection
    final isDark = AppThemeManager.colors.isDark;

    // Apply GRID STYLE colors ONLY in light mode - dark mode always uses dark colors
    final theme = isDark ? null : _gridStyle;

    // Grid uses dark colors in dark mode, theme colors or light colors otherwise
    final gridBorderColor = isDark
        ? AppColors.primaryLight
        : (theme?.primaryColor ?? AppColors.primary);
    final gridBackgroundColor = isDark
        ? AppColors.surfaceDark
        : (theme?.backgroundColor ?? AppColors.surfaceLight);

    // Default grid style values
    const borderRadius = 0.0;
    const cellSpacing = 0.5;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gridBorderColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: gridBorderColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3 + cellSpacing),
        child: Container(
          decoration: BoxDecoration(
            color: gridBackgroundColor,
            borderRadius:
                BorderRadius.circular(borderRadius > 0 ? borderRadius - 2 : 0),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / size;
              return Stack(
                children: [
                  // Grid cells
                  Column(
                    children: List.generate(size, (row) {
                      return Row(
                        children: List.generate(size, (col) {
                          return _buildCell(context, row, col, size, boxSize,
                              cellSize, cellSpacing, borderRadius);
                        }),
                      );
                    }),
                  ),
                  // Box borders
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _BoxBorderPainter(
                          size, boxSize, gridBorderColor, borderRadius),
                    ),
                  ),
                  // Completion effects overlay
                  ..._buildCompletionEffects(
                      constraints, size, boxSize, cellSize),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCompletionEffects(
      BoxConstraints constraints, int size, int boxSize, double cellSize) {
    final effects = <Widget>[];
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    for (var section in widget.completedSections) {
      final key = '${section.type}_${section.index}';
      final animation = _animations[key];

      if (animation == null) continue;

      effects.add(
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final value = animation.value;
            if (value <= 0) return const SizedBox.shrink();

            return IgnorePointer(
              child: LottieLoader.lottieOrFallback(
                assetPath: 'assets/lottie/effects/row_complete.json',
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.fill,
                fallback: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CompletionEffectPainter(
                    type: section.type,
                    index: section.index,
                    progress: value,
                    cellSize: cellSize,
                    boxSize: boxSize,
                    gridSize: size,
                    isDark: isDark,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return effects;
  }

  Widget _buildCell(BuildContext context, int row, int col, int size,
      int boxSize, double cellSize, double cellSpacing, double borderRadius) {
    // Use app theme manager for consistent dark/light mode detection
    final isDark = AppThemeManager.colors.isDark;
    final value = widget.gameState.currentGrid[row][col];
    final isFixed = widget.gameState.isFixedCell(row, col);
    final isSelected = row == widget.selectedRow && col == widget.selectedCol;
    final isInSameRowOrCol =
        row == widget.selectedRow || col == widget.selectedCol;
    final isInSameBox = widget.selectedRow != null &&
        widget.selectedCol != null &&
        (row ~/ boxSize) == (widget.selectedRow! ~/ boxSize) &&
        (col ~/ boxSize) == (widget.selectedCol! ~/ boxSize);

    final selectedValue = (widget.selectedRow != null &&
            widget.selectedCol != null)
        ? widget.gameState.currentGrid[widget.selectedRow!][widget.selectedCol!]
        : 0;
    final isSameNumber = value != 0 && value == selectedValue;
    final isError = value != 0 && value != widget.gameState.solution[row][col];
    final notes = widget.gameState.notes[row][col];

    // Apply GRID STYLE colors ONLY in light mode - dark mode always uses dark colors
    final theme = isDark ? null : _gridStyle;
    
    // Dark mode uses dedicated dark colors for proper contrast
    final backgroundColor = isDark
        ? AppColors.surfaceDark
        : (theme?.backgroundColor ?? AppColors.surfaceLight);
    final selectedColor = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.35)
        : (theme?.primaryColor.withValues(alpha: 0.4) ??
            AppColors.primary.withValues(alpha: 0.2));
    final highlightColor = isDark
        ? const Color(0xFF2A292E)
        : (theme?.cellHighlightColor ?? const Color(0xFFEBE8E2));
    final sameNumberColor = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.2)
        : (theme?.secondaryColor.withValues(alpha: 0.3) ??
            AppColors.primary.withValues(alpha: 0.12));
    final errorColor = isDark
        ? const Color(0xFF5C2A2A)
        : AppColors.error.withValues(alpha: 0.25);
    final gridLineColor =
        isDark ? const Color(0xFF3A393E) : const Color(0xFFE0DED9);

    Color bgColor = backgroundColor;

    if (isSelected) {
      bgColor = selectedColor;
    } else if (isSameNumber && value != 0) {
      bgColor = sameNumberColor;
    } else if (isInSameRowOrCol || isInSameBox) {
      bgColor = highlightColor;
    }

    if (isError && !isSelected) {
      bgColor = errorColor;
    }

    return Semantics(
      label: 'Row ${row + 1}, Column ${col + 1}',
      value: value != 0
          ? (size == 16 && value > 9
              ? String.fromCharCode(65 + value - 10)
              : '$value')
          : 'empty',
      hint: isFixed ? 'fixed' : (isError ? 'incorrect' : 'editable'),
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onCellTap(row, col);
        },
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              right: BorderSide(
                color: (col + 1) % boxSize == 0 && col != size - 1
                    ? Colors.transparent
                    : gridLineColor,
                width: 1,
              ),
              bottom: BorderSide(
                color: (row + 1) % boxSize == 0 && row != size - 1
                    ? Colors.transparent
                    : gridLineColor,
                width: 1,
              ),
            ),
          ),
          child: _buildCellContentWithDrop(
              context, row, col, value, isFixed, isError, notes, size, cellSize),
        ),
      ),
    );
  }

  Widget _buildCellContentWithDrop(BuildContext context, int row, int col,
      int value, bool isFixed, bool isError, Set<int> notes, int size,
      double cellSize) {
    final cellKey = row * widget.gameState.gridSize + col;
    final dropAnim = _dropAnimations[cellKey];
    final bounceAnim = _dropBounceAnimations[cellKey];
    final controller = _dropControllers[cellKey];

    if (dropAnim != null && bounceAnim != null && controller != null &&
        controller.isAnimating) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, dropAnim.value * cellSize),
            child: Transform.scale(
              scale: bounceAnim.value.clamp(0.3, 1.2),
              child: Opacity(
                opacity: (1.0 + dropAnim.value * 0.5).clamp(0.0, 1.0),
                child: _buildCellContent(context, value, isFixed, isError, notes, size),
              ),
            ),
          );
        },
      );
    }

    return _buildCellContent(context, value, isFixed, isError, notes, size);
  }

  Widget _buildCellContent(BuildContext context, int value, bool isFixed,
      bool isError, Set<int> notes, int size) {
    // Use app theme manager for consistent dark/light mode detection
    final isDark = AppThemeManager.colors.isDark;

    // High-contrast colors - use very dark/light colors for maximum visibility
    const fixedColorLight = Color(0xFF000000); // Pure black for light mode
    const fixedColorDark = Color(0xFFFFFFFF); // Pure white for dark mode
    const userColorLight = Color(0xFF1565C0); // Strong blue for user input
    const userColorDark = Color(0xFF90CAF9); // Light blue for dark mode
    const errorColor = Color(0xFFD32F2F); // Strong red for errors

    final fixedColor = isDark ? fixedColorDark : fixedColorLight;
    final userColor = isDark ? userColorDark : userColorLight;

    if (value != 0) {
      return Center(
        child: Text(
          size == 16 && value > 9
              ? String.fromCharCode(65 + value - 10)
              : '$value',
          style: TextStyle(
            fontSize: size == 9 ? 28 : 18,
            fontWeight: isFixed ? FontWeight.w700 : FontWeight.w600,
            color: isError ? errorColor : (isFixed ? fixedColor : userColor),
          ),
        ),
      );
    } else if (notes.isNotEmpty) {
      return _buildNotes(context, notes, size);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNotes(BuildContext context, Set<int> notes, int size) {
    // Use app theme manager for consistent dark/light mode detection
    final isDark = AppThemeManager.colors.isDark;
    final noteGridSize = size == 9 ? 3 : 4;
    // Softer gray note colors - easier on the eyes
    const noteColorLight = Color(0xFF757575); // Medium gray for light mode
    const noteColorDark = Color(0xFF9E9E9E); // Softer gray for dark mode
    final noteColor = isDark ? noteColorDark : noteColorLight;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: noteGridSize,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(size, (index) {
          final num = index + 1;
          return Center(
            child: notes.contains(num)
                ? Text(
                    size == 16 && num > 9
                        ? String.fromCharCode(65 + num - 10)
                        : '$num',
                    style: TextStyle(
                      fontSize: size == 9 ? 10.5 : 7.5,
                      fontWeight: FontWeight.w500,
                      color: noteColor,
                    ),
                  )
                : null,
          );
        }),
      ),
    );
  }
}

class _BoxBorderPainter extends CustomPainter {
  final int size;
  final int boxSize;
  final Color borderColor;
  final double borderRadius;

  _BoxBorderPainter(
      this.size, this.boxSize, this.borderColor, this.borderRadius);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cellWidth = canvasSize.width / size;
    final cellHeight = canvasSize.height / size;

    for (int i = 1; i < size ~/ boxSize; i++) {
      final x = i * boxSize * cellWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, canvasSize.height),
        paint,
      );
    }

    for (int i = 1; i < size ~/ boxSize; i++) {
      final y = i * boxSize * cellHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(canvasSize.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}

/// Custom painter for completion effects
class _CompletionEffectPainter extends CustomPainter {
  final String type;
  final int index;
  final double progress;
  final double cellSize;
  final int boxSize;
  final int gridSize;
  final bool isDark;

  _CompletionEffectPainter({
    required this.type,
    required this.index,
    required this.progress,
    required this.cellSize,
    required this.boxSize,
    required this.gridSize,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Different colors for different completion types
    // Box completion is more special (gold/yellow), row/col is green
    final Color effectColor;
    if (type == 'box') {
      effectColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFFFA000);
    } else {
      effectColor = isDark ? const Color(0xFF10B981) : const Color(0xFF4CAF50);
    }

    final eased = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final glowColor =
        effectColor.withValues(alpha: (type == 'box' ? 0.35 : 0.28) * eased);
    final borderColor = effectColor.withValues(alpha: 0.92 * eased);

    Rect rect;
    switch (type) {
      case 'row':
        rect = Rect.fromLTWH(
          0,
          index * cellSize,
          size.width,
          cellSize,
        );
        break;
      case 'col':
        rect = Rect.fromLTWH(
          index * cellSize,
          0,
          cellSize,
          size.height,
        );
        break;
      case 'box':
        final boxRow = index ~/ (gridSize ~/ boxSize);
        final boxCol = index % (gridSize ~/ boxSize);
        rect = Rect.fromLTWH(
          boxCol * boxSize * cellSize,
          boxRow * boxSize * cellSize,
          boxSize * cellSize,
          boxSize * cellSize,
        );
        break;
      default:
        return;
    }

    final glowSize = type == 'box' ? 8.0 : 5.0;
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * eased + 2);

    canvas.drawRect(rect.inflate(glowSize * eased), glowPaint);

    if (type == 'box') {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectColor.withValues(alpha: 0.28 * eased),
            effectColor.withValues(alpha: 0.12 * eased),
            effectColor.withValues(alpha: 0.18 * eased),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    } else {
      final fillPaint = Paint()
        ..color = effectColor.withValues(alpha: 0.1 * eased)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (type == 'box' ? 3.2 : 2.2) * eased;

    if (type == 'box') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(5 * eased)),
        borderPaint,
      );
    } else {
      canvas.drawRect(rect, borderPaint);
    }

    final shineT = (eased - 0.08) / 0.5;
    if (shineT > 0 && shineT < 1) {
      final shineEased = Curves.easeInOutCubic.transform(shineT);
      final shineWidth = type == 'box' ? 72.0 : 48.0;
      final shineRect = Rect.fromLTWH(
        rect.left + rect.width * shineEased - shineWidth / 2,
        rect.top,
        shineWidth,
        rect.height,
      ).intersect(rect);

      if (!shineRect.isEmpty) {
        final shinePaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(shineRect);
        canvas.drawRect(shineRect, shinePaint);
      }
    }

    if (type == 'box' && eased > 0.25 && eased < 0.75) {
      final innerGlow = (eased - 0.25) / 0.5;
      final innerAlpha =
          (1 - (innerGlow - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.12;
      final innerPaint = Paint()
        ..color = effectColor.withValues(alpha: innerAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(4),
          const Radius.circular(3),
        ),
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.index != index;
  }
}
