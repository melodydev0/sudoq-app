import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_manager.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// A themed button that adapts to the current app theme.
///
/// Replaces duplicate ElevatedButton / OutlinedButton + manual BoxDecoration
/// patterns across screens.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? fontSize;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
  });

  const AppPrimaryButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
  })  : variant = AppButtonVariant.secondary;

  const AppPrimaryButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
  })  : variant = AppButtonVariant.outline;

  const AppPrimaryButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
  })  : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;

    final Color bg;
    final Color fg;
    final Color border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = theme.buttonPrimary;
        fg = theme.buttonText;
        border = theme.buttonPrimary;
      case AppButtonVariant.secondary:
        bg = theme.buttonSecondary;
        fg = theme.accent;
        border = theme.buttonSecondary;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = theme.accent;
        border = theme.accent;
      case AppButtonVariant.danger:
        bg = theme.isDark ? const Color(0xFF5C2A2A) : const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        border = const Color(0xFFD32F2F);
    }

    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize ?? 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: AppTheme.buttonRadius,
        child: InkWell(
          onTap: (onPressed != null && !isLoading) ? onPressed : null,
          borderRadius: AppTheme.buttonRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: AppTheme.buttonRadius,
              border: Border.all(color: border),
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
