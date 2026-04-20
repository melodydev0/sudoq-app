import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/models/statistics.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_theme_manager.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Summary statistics card on the profile screen.
///
/// Shows total games, win rate, best streak, and perfect games in a single row.
class ProfileStatsCard extends StatelessWidget {
  final Statistics statistics;

  const ProfileStatsCard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.horizontalPadding()),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
                label: l10n.games,
                value: '${statistics.totalGamesPlayed}',
                theme: theme),
            _StatItem(
                label: l10n.winRate,
                value: '${statistics.winRate.toStringAsFixed(0)}%',
                theme: theme),
            _StatItem(
                label: l10n.bestStreak,
                value: '${statistics.bestStreak}',
                theme: theme),
            _StatItem(
                label: l10n.perfect,
                value: '${statistics.perfectGames}',
                theme: theme),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors theme;

  const _StatItem(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: theme.accent,
          ),
        ),
        SizedBox(height: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: theme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
