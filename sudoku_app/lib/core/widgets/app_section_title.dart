import 'package:flutter/material.dart';
import '../theme/app_theme_manager.dart';

/// A themed section title / header widget.
///
/// Replaces duplicate Text + padding patterns used as section separators across screens.
class AppSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize ?? 12,
                fontWeight: FontWeight.w700,
                color: theme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
