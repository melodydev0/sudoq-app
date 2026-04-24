import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Glowing "Complete Now" button shown when ≤5 cells remain.
///
/// Uses its own AnimationController for a smooth repeating glow pulse
/// without blocking the tap handler.
class AutoCompleteButton extends StatefulWidget {
  const AutoCompleteButton({
    super.key,
    required this.l10n,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  State<AutoCompleteButton> createState() => _AutoCompleteButtonState();
}

class _AutoCompleteButtonState extends State<AutoCompleteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glow = _glowAnim.value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue
                      .withValues(alpha: 0.30 + 0.35 * glow),
                  blurRadius: 8 + 16 * glow,
                  spreadRadius: 0 + 3 * glow,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: const Color(0xFF7B7EC7)
                      .withValues(alpha: 0.18 * glow),
                  blurRadius: 22 * glow,
                  spreadRadius: 2 * glow,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Bootstrap.check2_all,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.l10n.autoCompleteNow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
