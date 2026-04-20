import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_manager.dart';

/// A themed card container that adapts to the current app theme.
///
/// Replaces duplicate `Container` + `BoxDecoration` + shadow patterns across screens.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;
    final radius = borderRadius ?? 16;

    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? theme.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? theme.cardBorder,
          width: borderWidth,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: theme.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}

/// A card with organic asymmetric radius matching AppTheme.cardRadius.
class AppOrganicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const AppOrganicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;

    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? theme.card,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: theme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: theme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }
}
