import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/daily_challenge_service.dart';
import '../../../../core/services/global_stats_service.dart';
import '../../../../core/models/daily_challenge_system.dart';
import '../../../game/presentation/screens/game_screen.dart';
import '../widgets/monthly_badge_widget.dart';
import 'trophy_room_screen.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _badgeAnimation;

  // Global stats
  int _monthPlayersCompleted = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final year = now.year < 2026 ? 2026 : now.year;
    final month = now.year < 2026 ? 1 : now.month;
    final day = now.year < 2026 ? 1 : now.day;
    _currentMonth = DateTime(year, month, 1);
    _selectedDate = DateTime(year, month, day);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _badgeAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    // Load global stats for current month
    _loadMonthStats();
  }

  Future<void> _loadMonthStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final stats = await GlobalStatsService.instance.getMonthStats(
        _currentMonth.year,
        _currentMonth.month,
      );

      if (mounted) {
        setState(() {
          _monthPlayersCompleted = stats.fullMonthCompleters;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _monthPlayersCompleted = 0;
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    final minDate = DateTime(2026, 1, 1);
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);

    if (!prevMonth.isBefore(minDate)) {
      setState(() {
        _currentMonth = prevMonth;
        _selectedDate = null;
      });
      _loadMonthStats();
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1, 1))) {
      setState(() {
        _currentMonth = nextMonth;
        _selectedDate = null;
      });
      _loadMonthStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.isDark;

    final monthProgress = DailyChallengeService.getMonthProgress(
        _currentMonth.year, _currentMonth.month);
    final badgeInfo = MonthBadgeInfo.getForMonth(_currentMonth.month);

    // Theme colors
    final bgColor = theme.background;
    final headerBg = isDark ? theme.card : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF607D8B);
    final textMuted = isDark ? Colors.white38 : const Color(0xFF90A4AE);
    final cardBg = isDark ? theme.card : Colors.white;
    final dividerColor = isDark ? Colors.white12 : const Color(0xFFE8E8E8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section - compact
            _buildHeader(l10n, isDark, theme, headerBg, textPrimary,
                textSecondary, textMuted),

            // Badge and progress section
            _buildBadgeSection(
              monthProgress,
              badgeInfo,
              l10n,
              isDark,
              textPrimary,
              textSecondary,
              textMuted,
            ),

            // Month navigation
            _buildMonthNavigation(l10n, isDark, textSecondary),

            SizedBox(height: 8.w),

            // Calendar section - fills remaining space
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(color: dividerColor),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    _buildWeekdayHeader(isDark, theme),
                    Expanded(
                      child: _buildCalendarGrid(isDark, theme),
                    ),
                    if (_selectedDate != null)
                      _buildSelectedDateAction(isDark, theme, l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    bool isDark,
    AppThemeColors theme,
    Color headerBg,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final backBtnBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final backBtnIcon = isDark ? Colors.white70 : textPrimary;
    final trophyBtnBg = isDark ? theme.buttonPrimary : const Color(0xFF37474F);

    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 4.w, 8.w, 8.w),
      color: headerBg,
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: backBtnBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Bootstrap.arrow_left, color: backBtnIcon, size: 20.w),
            ),
          ),

          SizedBox(width: 12.w),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMonthName(l10n, _currentMonth.month).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'DAILY CHALLENGE',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Trophy room button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrophyRoomScreen()),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: trophyBtnBg,
                borderRadius: BorderRadius.circular(18.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Bootstrap.trophy_fill, color: Colors.white, size: 14.w),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.trophyRoom.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSection(
    MonthProgress progress,
    MonthBadgeInfo badgeInfo,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final progressBarBg = isDark ? Colors.white12 : const Color(0xFFE0E0E0);
    final progressBarFill = progress.isComplete
        ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
        : [const Color(0xFFD4B896), const Color(0xFFC4A060)];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      child: Row(
        children: [
          // Badge
          Expanded(
            flex: 2,
            child: Center(
              child: ScaleTransition(
                scale: _badgeAnimation,
                child: MonthlyBadgeWidget(
                  badgeInfo: badgeInfo,
                  isEarned: progress.isComplete,
                  size: 90,
                  completedDays: progress.completedDays,
                  totalDays: progress.totalDays,
                  showProgress: false,
                ),
              ),
            ),
          ),

          // Progress info
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress text
                  Text(
                    progress.isComplete
                        ? l10n.completed.toUpperCase()
                        : '${progress.completedDays} / ${progress.totalDays} ${l10n.days}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: progress.isComplete
                          ? const Color(0xFF4CAF50)
                          : textPrimary,
                    ),
                  ),

                  SizedBox(height: 6.w),

                  // Progress bar
                  Container(
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: progressBarBg,
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: progressBarFill),
                          borderRadius: BorderRadius.circular(3.w),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 8.w),

                  // Players completed
                  Row(
                    children: [
                      Icon(Bootstrap.people_fill, color: textMuted, size: 12.w),
                      SizedBox(width: 6.w),
                      if (_isLoadingStats)
                        SizedBox(
                          width: 12.w,
                          height: 12.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textMuted,
                          ),
                        )
                      else
                        Text(
                          '${_formatNumber(_monthPlayersCompleted)} ${l10n.playersCompleted}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(
      AppLocalizations l10n, bool isDark, Color textSecondary) {
    final navBtnBg =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF0F0F0);
    final navBtnIcon = isDark ? Colors.white70 : textSecondary;
    final monthPillBg =
        isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF37474F);
    final monthPillText = isDark ? Colors.white : Colors.white;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: navBtnBg,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Bootstrap.chevron_left, color: navBtnIcon, size: 16.w),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.w),
            decoration: BoxDecoration(
              color: monthPillBg,
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Text(
              '${_getMonthName(l10n, _currentMonth.month)} ${_currentMonth.year}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: monthPillText,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: navBtnBg,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Bootstrap.chevron_right, color: navBtnIcon, size: 16.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(bool isDark, AppThemeColors theme) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final weekdayColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final weekendColor =
        isDark ? Colors.orange.shade300 : Colors.orange.shade600;

    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 12.w, 8.w, 4.w),
      child: Row(
        children: days.asMap().entries.map((entry) {
          final isWeekend = entry.key == 0 || entry.key == 6;
          return Expanded(
            child: Text(
              entry.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isWeekend ? weekendColor : weekdayColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark, AppThemeColors theme) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate number of rows needed
    final totalCells = firstWeekday + daysInMonth;
    final numRows = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / numRows;

        return Column(
          children: List.generate(numRows, (row) {
            return SizedBox(
              height: cellHeight,
              child: Row(
                children: List.generate(7, (col) {
                  final dayIndex = row * 7 + col - firstWeekday;

                  if (dayIndex < 0 || dayIndex >= daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }

                  final day = dayIndex + 1;
                  final date =
                      DateTime(_currentMonth.year, _currentMonth.month, day);
                  final isToday = date.isAtSameMomentAs(today);
                  final isPast = date.isBefore(today);
                  final isFuture = date.isAfter(today);
                  final isSelected = _selectedDate != null &&
                      date.year == _selectedDate!.year &&
                      date.month == _selectedDate!.month &&
                      date.day == _selectedDate!.day;
                  final isCompleted =
                      DailyChallengeService.isDateCompleted(date);

                  return Expanded(
                    child: _buildDayCell(
                      day: day,
                      date: date,
                      isToday: isToday,
                      isPast: isPast,
                      isFuture: isFuture,
                      isSelected: isSelected,
                      isCompleted: isCompleted,
                      isDark: isDark,
                      theme: theme,
                      cellHeight: cellHeight,
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required bool isToday,
    required bool isPast,
    required bool isFuture,
    required bool isSelected,
    required bool isCompleted,
    required bool isDark,
    required AppThemeColors theme,
    required double cellHeight,
  }) {
    Color backgroundColor = Colors.transparent;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color? borderColor;

    if (isSelected) {
      backgroundColor = AppColors.primaryBlue;
      textColor = Colors.white;
    } else if (isToday) {
      borderColor = AppColors.primaryBlue;
    }

    if (isFuture) {
      textColor = isDark ? Colors.white24 : Colors.grey.shade400;
    }

    final circleSize = (cellHeight * 0.7).clamp(28.0, 40.0);
    final fontSize = (cellHeight * 0.28).clamp(11.0, 14.0);
    final dotSize = (cellHeight * 0.12).clamp(4.0, 7.0);

    return GestureDetector(
      onTap: () {
        if (!isFuture) {
          setState(() => _selectedDate = date);
          HapticFeedback.selectionClick();
        }
      },
      child: Center(
        child: Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              if (isCompleted && !isSelected)
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                )
              else if (!isCompleted && !isFuture && !isSelected)
                Container(
                  width: dotSize * 0.7,
                  height: dotSize * 0.7,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateAction(
      bool isDark, AppThemeColors theme, AppLocalizations l10n) {
    if (_selectedDate == null) return const SizedBox.shrink();

    final isCompleted = DailyChallengeService.isDateCompleted(_selectedDate!);
    final canPlay = DailyChallengeService.canPlayDate(_selectedDate!);

    final bgColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.w, 12.w, 12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.w),
          bottomRight: Radius.circular(20.w),
        ),
      ),
      child: Row(
        children: [
          // Date info
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.15)
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Bootstrap.check_circle_fill
                        : Bootstrap.calendar_event,
                    color: isCompleted
                        ? Colors.green
                        : (isDark ? Colors.white54 : Colors.grey),
                    size: 18.w,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(_selectedDate!, l10n),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isCompleted
                          ? l10n.completed
                          : canPlay
                              ? l10n.notCompleted
                              : l10n.comingSoon,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isCompleted
                            ? Colors.green
                            : (isDark ? Colors.white38 : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action button
          if (canPlay && !isCompleted)
            ElevatedButton(
              onPressed: () => _playChallenge(_selectedDate!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.w),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Bootstrap.play_fill, size: 14.w),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.playNow,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (isCompleted)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Bootstrap.trophy_fill, color: Colors.green, size: 14.w),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.completed,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _playChallenge(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: 'Medium',
          isDailyChallenge: true,
          dailyChallengeDate: date,
        ),
      ),
    );
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

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final month = _getMonthName(l10n, date.month);
    return '${month.substring(0, 3)} ${date.day}, ${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }
}
