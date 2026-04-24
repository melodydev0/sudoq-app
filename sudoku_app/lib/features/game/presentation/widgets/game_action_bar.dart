import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Action toolbar: Undo, Erase, Notes/Pencil, Fast Pencil, Hint.
class GameActionBar extends StatelessWidget {
  final bool isPencilMode;
  final bool fastPencilEnabled;
  final bool isAdsFree;
  final int hintsUsed;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onTogglePencil;
  final VoidCallback onFastPencil;
  final VoidCallback onHint;

  const GameActionBar({
    super.key,
    required this.isPencilMode,
    required this.fastPencilEnabled,
    required this.isAdsFree,
    required this.hintsUsed,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onUndo,
    required this.onErase,
    required this.onTogglePencil,
    required this.onFastPencil,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hintsLeft = AppConstants.maxHints - hintsUsed;
    final hintLimitReached = hintsUsed >= AppConstants.maxHints;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Bootstrap.arrow_counterclockwise,
            label: l10n.undo,
            onTap: onUndo,
            isDark: isDark,
            textColor: textColor,
          ),
          _ActionButton(
            icon: Bootstrap.eraser,
            label: l10n.erase,
            onTap: onErase,
            isDark: isDark,
            textColor: textColor,
          ),
          _ActionButton(
            icon: Bootstrap.pencil,
            label: l10n.notes,
            onTap: onTogglePencil,
            isActive: isPencilMode,
            isDark: isDark,
            textColor: textColor,
          ),
          _ActionButton(
            icon: fastPencilEnabled
                ? Bootstrap.lightning_charge_fill
                : Bootstrap.lightning_charge,
            label: fastPencilEnabled ? l10n.fastPencilOn : l10n.fast,
            onTap: onFastPencil,
            isActive: fastPencilEnabled,
            isDark: isDark,
            textColor: textColor,
            showAdBadge: !fastPencilEnabled && !isAdsFree,
          ),
          _ActionButton(
            icon: Bootstrap.lightbulb,
            label: hintLimitReached
                ? '${l10n.hint} 0/${AppConstants.maxHints}'
                : '${l10n.hint} $hintsLeft/${AppConstants.maxHints}',
            onTap: onHint,
            isDark: isDark,
            textColor: textColor,
            isDisabled: hintLimitReached,
            showAdBadge:
                !isAdsFree && hintsUsed >= AppConstants.freeHintsWithoutAd && !hintLimitReached,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool showAdBadge;
  final bool isDisabled;
  final bool isDark;
  final Color textColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.showAdBadge = false,
    this.isDisabled = false,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDisabled
        ? Colors.grey.shade400
        : isActive
            ? AppColors.gradientStart
            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final labelColor = isDisabled
        ? Colors.grey.shade400
        : isActive
            ? AppColors.gradientStart
            : textColor;

    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.gradientStart.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.gradientStart.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 26, color: iconColor),
                    if (showAdBadge)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Bootstrap.play_fill,
                            size: 10,
                            color: Colors.white,
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
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
