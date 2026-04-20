import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Top bar for the game screen: back button, difficulty badge, settings button.
class GameTopBar extends StatelessWidget {
  final String difficulty;
  final Color textColor;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const GameTopBar({
    super.key,
    required this.difficulty,
    required this.textColor,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Bootstrap.arrow_left, size: 22.w),
            color: textColor,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              difficulty,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSettings,
            icon: Icon(Bootstrap.gear, size: 22.w),
            color: textColor,
          ),
        ],
      ),
    );
  }
}
