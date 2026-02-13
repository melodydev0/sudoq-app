import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

class GameActions extends StatelessWidget {
  final bool isPencilMode;
  final bool isFastPencilMode;
  final int hintsRemaining;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onPencilToggle;
  final VoidCallback onFastPencilToggle;
  final VoidCallback onHint;

  const GameActions({
    super.key,
    required this.isPencilMode,
    required this.isFastPencilMode,
    required this.hintsRemaining,
    required this.onUndo,
    required this.onErase,
    required this.onPencilToggle,
    required this.onFastPencilToggle,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.undo,
            label: 'Undo',
            onTap: onUndo,
          ),
          _ActionButton(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            onTap: onErase,
          ),
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Pencil',
            isActive: isPencilMode,
            onTap: onPencilToggle,
          ),
          _ActionButton(
            icon: Icons.flash_on_outlined,
            label: 'Fast',
            isActive: isFastPencilMode,
            onTap: onFastPencilToggle,
          ),
          _ActionButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            badge: hintsRemaining > 0 ? '$hintsRemaining' : null,
            onTap: hintsRemaining > 0 ? onHint : null,
            isDisabled: hintsRemaining <= 0,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final String? badge;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDisabled = false,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : isActive
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : isActive
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
