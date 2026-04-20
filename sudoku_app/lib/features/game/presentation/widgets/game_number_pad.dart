import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Number input pad (1–9) for the game screen.
class GameNumberPad extends StatelessWidget {
  final int gridSize;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Map<int, int> remainingCounts;
  final ValueChanged<int> onNumberSelected;

  const GameNumberPad({
    super.key,
    this.gridSize = 9,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.remainingCounts,
    required this.onNumberSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(gridSize, (index) {
          final number = index + 1;
          final remaining = remainingCounts[number] ?? 0;
          final isCompleted = remaining == 0;

          return Semantics(
            label: 'Number $number',
            value: isCompleted ? 'completed' : '$remaining remaining',
            enabled: !isCompleted,
            button: true,
            child: GestureDetector(
              onTap: isCompleted ? null : () => onNumberSelected(number),
              child: Container(
                width: 35.w,
                height: 58.w,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? (isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200)
                      : cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? (isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400)
                            : textColor,
                      ),
                    ),
                    if (!isCompleted)
                      Text(
                        '$remaining',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
