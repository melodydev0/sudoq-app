import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/daily_challenge_service.dart';
import '../../../../core/models/daily_challenge_system.dart';
import '../widgets/monthly_badge_widget.dart';

class TrophyRoomScreen extends ConsumerStatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  ConsumerState<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends ConsumerState<TrophyRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);
    // Use current year (minimum 2026)
    final now = DateTime.now();
    final currentYear = now.year < 2026 ? 2026 : now.year;
    final currentMonth = now.year < 2026 ? 1 : now.month;

    // Group badges by year
    final allBadges = DailyChallengeService.earnedBadges;
    final badges = allBadges.where((b) => b.year >= 2026).toList();

    final currentYearMonths = <_MonthData>[];
    for (int month = 1; month <= 12; month++) {
      final progress =
          DailyChallengeService.getMonthProgress(currentYear, month);
      final monthBadges = badges
          .where((b) => b.year == currentYear && b.month == month)
          .toList();
      final badge = monthBadges.isEmpty ? null : monthBadges.first;
      final isFuture = (currentYear == now.year && month > currentMonth) ||
          (currentYear > now.year);
      currentYearMonths.add(_MonthData(
        month: month,
        year: currentYear,
        progress: progress,
        badge: badge,
        isFuture: isFuture,
      ));
    }

    // Stats
    final earnedCount = badges.where((b) => b.isComplete).length;
    final streak = DailyChallengeService.currentStreak;
    final totalDays = DailyChallengeService.totalDaysCompleted;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with theme support
            _buildHeader(
                l10n, theme, earnedCount, streak, totalDays, currentYear),
            Expanded(
              child: _buildBadgesGrid(
                currentYearMonths,
                theme,
                l10n,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    AppThemeColors theme,
    int earnedCount,
    int streak,
    int totalDays,
    int year,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 16.w),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(
          bottom: BorderSide(color: theme.divider, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: theme.accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Bootstrap.arrow_left,
                    color: theme.iconSecondary,
                    size: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trophyRoom.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: theme.textSecondary,
                      ),
                    ),
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 10.sp,
                        letterSpacing: 0.5,
                        color: theme.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.w),
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.w, horizontal: 16.w),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: AppTheme.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: theme.divider, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('$earnedCount', l10n.badges, theme.warning,
                    theme.textPrimary, theme),
                _buildDivider(theme.divider),
                _buildStat('$streak', l10n.streak, theme.warning,
                    theme.textPrimary, theme),
                _buildDivider(theme.divider),
                _buildStat('$totalDays', l10n.days, theme.success,
                    theme.textPrimary, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color accentColor,
      Color valueColor, AppThemeColors theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        SizedBox(height: 2.w),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: accentColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 36.w,
      color: color,
    );
  }

  Widget _buildBadgesGrid(
    List<_MonthData> months,
    AppThemeColors theme,
    AppLocalizations l10n,
  ) {
    // Sort months January to December
    final sortedMonths = List<_MonthData>.from(months)
      ..sort((a, b) => a.month.compareTo(b.month));

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Minimal padding
        final horizontalPadding = 4.w;

        // 4 columns - calculate cell size
        final cellWidth = (availableWidth - (2 * horizontalPadding)) / 4;
        final rowHeight = availableHeight / 3;

        // Badge size - 85% of cell width for maximum visibility
        final badgeSize = (cellWidth * 0.85).clamp(55.0, 90.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              for (int row = 0; row < 3; row++)
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      for (int col = 0; col < 4; col++)
                        Expanded(
                          child: _buildBadgeItem(
                            sortedMonths[row * 4 + col],
                            theme,
                            l10n,
                            badgeSize,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgeItem(
    _MonthData data,
    AppThemeColors theme,
    AppLocalizations l10n,
    double badgeSize,
  ) {
    final badgeInfo = MonthBadgeInfo.getForMonth(data.month);
    final isEarned = data.badge?.isComplete == true;
    final isFuture = data.isFuture;
    final completed =
        data.progress?.completedDays ?? data.badge?.completedDays ?? 0;
    final total = data.progress?.totalDays ?? data.badge?.totalDays ?? 30;
    final earnedTextColor = theme.warning;
    final defaultTextColor = theme.textSecondary;
    final futureTextColor = theme.textSecondary.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        if (!isFuture) {
          HapticService.selectionClick();
          _showBadgeDetails(data, badgeInfo, l10n, theme);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge - large icon only
          MonthlyBadgeWidget(
            badgeInfo: badgeInfo,
            isEarned: isEarned,
            isLocked: isFuture,
            size: badgeSize,
            completedDays: completed,
            totalDays: total,
            showProgress: false,
            animated: false,
          ),

          // Month name - directly below
          SizedBox(height: 4.w),
          Text(
            _getShortMonthName(l10n, data.month).toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isEarned
                  ? earnedTextColor
                  : isFuture
                      ? futureTextColor
                      : defaultTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetails(
    _MonthData data,
    MonthBadgeInfo badgeInfo,
    AppLocalizations l10n,
    AppThemeColors theme,
  ) {
    final isEarned = data.badge?.isComplete == true;
    final completed =
        data.progress?.completedDays ?? data.badge?.completedDays ?? 0;
    final total = data.progress?.totalDays ?? data.badge?.totalDays ?? 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
            boxShadow: [
              BoxShadow(
                color: theme.textPrimary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.w,
                margin: EdgeInsets.only(bottom: 16.w),
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              LargeBadgeWidget(
                badgeInfo: badgeInfo,
                isEarned: isEarned,
                completedDays: completed,
                totalDays: total,
                monthName: _getMonthName(l10n, data.month),
                year: data.year,
              ),
              SizedBox(height: 16.w),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isEarned ? theme.warning : theme.buttonPrimary,
                    foregroundColor: theme.buttonText,
                    padding: EdgeInsets.symmetric(vertical: 12.w),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonRadius,
                    ),
                  ),
                  child: Text(
                    l10n.close,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
            ],
          ),
        );
      },
    );
  }

  String _getShortMonthName(AppLocalizations l10n, int month) {
    final fullName = _getMonthName(l10n, month);
    // Return first 3 characters for short name
    return fullName.length > 3 ? fullName.substring(0, 3) : fullName;
  }

  String _getMonthName(AppLocalizations l10n, int month) {
    switch (month) {
      case 1:
        return l10n.january;
      case 2:
        return l10n.february;
      case 3:
        return l10n.march;
      case 4:
        return l10n.april;
      case 5:
        return l10n.may;
      case 6:
        return l10n.june;
      case 7:
        return l10n.july;
      case 8:
        return l10n.august;
      case 9:
        return l10n.september;
      case 10:
        return l10n.october;
      case 11:
        return l10n.november;
      case 12:
        return l10n.december;
      default:
        return '';
    }
  }
}

class _MonthData {
  final int month;
  final int year;
  final MonthProgress? progress;
  final MonthlyBadge? badge;
  final bool isFuture;

  _MonthData({
    required this.month,
    required this.year,
    this.progress,
    this.badge,
    this.isFuture = false,
  });
}
