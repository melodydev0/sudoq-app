import 'package:flutter/material.dart';
import '../theme/app_theme_manager.dart';

/// Helpers for displaying consistent, themed SnackBar notifications app-wide.
///
/// Replaces manual `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` calls
/// with hard-coded `Colors.red` / `Colors.green` scattered across screens.
class AppSnackbar {
  AppSnackbar._();

  /// Show an error snackbar (red background).
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F),
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Show a success snackbar (green background).
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppThemeManager.colors.success,
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  /// Show an info snackbar (accent background).
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppThemeManager.colors.accent,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }
}
