import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

class DifficultyDialog extends StatelessWidget {
  final Function(String) onDifficultySelected;

  const DifficultyDialog({
    super.key,
    required this.onDifficultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gridLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'New Game',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 24),

            // Difficulty options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildDifficultyOption(context, 'Beginner', null, true),
                  _buildDifficultyOption(context, 'Easy', null, true),
                  _buildDifficultyOption(context, 'Medium', null, true),
                  _buildDifficultyOption(context, 'Hard', null, true),
                  _buildDifficultyOption(
                    context,
                    'Expert',
                    'Complete 3 hard games to unlock',
                    true, // Set to false when locked
                  ),
                  _buildDifficultyOption(
                    context,
                    'Extreme',
                    'Complete 5 expert games to unlock',
                    true, // Set to false when locked
                  ),

                  const SizedBox(height: 16),

                  // Special modes row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecialMode(context, 'Fast', true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSpecialMode(
                          context,
                          '16×16',
                          true, // Set to false when locked
                          subtitle: 'Complete 5 expert\ngames to unlock',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String title,
    String? lockMessage,
    bool isUnlocked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked ? () => onDifficultySelected(title) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isUnlocked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (lockMessage != null && !isUnlocked)
                        Text(
                          lockMessage,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  Icon(
                    Icons.lock,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialMode(
    BuildContext context,
    String title,
    bool isUnlocked, {
    String? subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnlocked ? () => onDifficultySelected(title) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (!isUnlocked) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.lock,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
