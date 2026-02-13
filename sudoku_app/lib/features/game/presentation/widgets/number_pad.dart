import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/game_state.dart';
import '../../../../core/utils/responsive_utils.dart';

class NumberPad extends StatelessWidget {
  final GameState gameState;
  final Function(int) onNumberSelected;

  const NumberPad({
    super.key,
    required this.gameState,
    required this.onNumberSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = gameState.gridSize;

    if (size == 16) {
      return _build16x16Pad();
    }

    return _build9x9Pad();
  }

  Widget _build9x9Pad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final remaining = gameState.getRemainingCount(number);
          final isCompleted = remaining == 0;

          return _NumberButton(
            number: number,
            remaining: remaining,
            isCompleted: isCompleted,
            onTap: isCompleted ? null : () => onNumberSelected(number),
          );
        }),
      ),
    );
  }

  Widget _build16x16Pad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(8, (index) {
              final number = index + 1;
              final remaining = gameState.getRemainingCount(number);
              return _NumberButton(
                number: number,
                remaining: remaining,
                isCompleted: remaining == 0,
                onTap: remaining == 0 ? null : () => onNumberSelected(number),
                is16x16: true,
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(8, (index) {
              final number = index + 9;
              final remaining = gameState.getRemainingCount(number);
              return _NumberButton(
                number: number,
                remaining: remaining,
                isCompleted: remaining == 0,
                onTap: remaining == 0 ? null : () => onNumberSelected(number),
                is16x16: true,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final int remaining;
  final bool isCompleted;
  final VoidCallback? onTap;
  final bool is16x16;

  const _NumberButton({
    required this.number,
    required this.remaining,
    required this.isCompleted,
    this.onTap,
    this.is16x16 = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = is16x16 && number > 9
        ? String.fromCharCode(65 + number - 10)
        : '$number';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: is16x16 ? 38 : 36,
        height: is16x16 ? 50 : 56,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.backgroundLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayText,
              style: TextStyle(
                fontSize: is16x16 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: isCompleted
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.primaryBlue,
              ),
            ),
            if (!isCompleted)
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
