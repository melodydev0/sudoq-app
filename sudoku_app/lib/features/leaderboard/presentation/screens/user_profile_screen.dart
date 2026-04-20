import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import '../../../../core/models/leaderboard_user.dart';
import '../../../../core/models/achievement.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/widgets/animated_frame.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/widgets/division_badge.dart';

class UserProfileScreen extends StatelessWidget {
  final LeaderboardUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    final isDark = theme.isDark;

    // Get screen info for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.backgroundGradientStart,
              theme.backgroundGradientEnd
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header with back button
              SliverToBoxAdapter(child: _buildHeader(context, isDark)),
              // Profile card
              SliverToBoxAdapter(
                child: _buildProfileCard(
                    context, l10n, isDark, isTablet, isLargeScreen),
              ),
              // Stats grid
              SliverToBoxAdapter(
                child: _buildStatsGrid(
                    context, l10n, isDark, isTablet, isLargeScreen),
              ),
              // Badges section
              SliverToBoxAdapter(
                child: _buildBadgesSection(context, l10n, isDark, isTablet),
              ),
              // Achievements section
              SliverToBoxAdapter(
                child: _buildAchievementsSection(
                    context, l10n, isDark, isTablet, isLargeScreen),
              ),
              // Bottom padding
              SliverToBoxAdapter(child: SizedBox(height: 24.w)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticService.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20.w,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context).profile,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 22),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final cardPadding = isTablet ? 28.0 : 20.0;
    final avatarSize = isLargeScreen ? 100.0 : (isTablet ? 88.0 : 72.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      constraints:
          BoxConstraints(maxWidth: isLargeScreen ? 600 : double.infinity),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gradientStart.withValues(alpha: isDark ? 0.4 : 0.15),
            AppColors.gradientEnd.withValues(alpha: isDark ? 0.4 : 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color: AppColors.gradientStart.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Avatar with animated frame and country
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Avatar with Frame
              _buildFramedUserAvatar(isDark, avatarSize),
              // Country flag
              Positioned(
                bottom: -5,
                right: -5,
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 8.w : 6.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    user.countryFlag,
                    style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 22)),
                  ),
                ),
              ),
              // Online indicator
              if (user.isOnline)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10.w : 8.w,
                      vertical: isTablet ? 5.w : 4.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    child: Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 9),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 20.w : 16.w),
          // Username
          Text(
            user.username,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 10.w),
          // Level and XP
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.w,
            runSpacing: 8.w,
            children: [
              _buildInfoChip(
                context: context,
                icon: Icons.trending_up,
                label: '${l10n.level} ${user.level}',
                color: AppColors.primaryBlue,
                isTablet: isTablet,
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.star,
                label: '${_formatNumber(user.totalXp)} XP',
                color: Colors.amber,
                isTablet: isTablet,
              ),
            ],
          ),
          SizedBox(height: 10.w),
          // Rank and Division
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.w,
            runSpacing: 8.w,
            children: [
              _buildInfoChip(
                context: context,
                icon: Icons.leaderboard,
                label: '#${user.rank}',
                color: _getRankColor(user.rank),
                isTablet: isTablet,
              ),
              if (user.division != null)
                _buildDivisionChip(
                  context: context,
                  division: user.division!,
                  color: _getDivisionColor(user.division!),
                  isTablet: isTablet,
                ),
            ],
          ),
          SizedBox(height: 14.w),
          // Join date
          Text(
            '${l10n.memberSince}: ${_formatDate(context, user.joinedAt)}',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 12),
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Güvenli çerçeve araması – firstWhere atmayı önler.
  FrameReward? _frameById(String id) {
    for (final f in CosmeticRewards.frames) {
      if (f.id == id) return f;
    }
    for (final f in CosmeticRewards.rankedFrames) {
      if (f.id == id) return f;
    }
    return null;
  }

  Widget _buildFramedUserAvatar(bool isDark, double avatarSize) {
    // Get frame if user has one equipped (safe lookup)
    FrameReward? frame;
    if (user.equippedFrame != null && user.equippedFrame!.isNotEmpty) {
      frame = _frameById(user.equippedFrame!);
    }

    return AnimatedAvatarFrame(
      frame: frame,
      size: avatarSize,
      showAnimation: true,
      child: _buildAvatarContent(isDark, avatarSize, frame),
    );
  }

  Widget _buildAvatarContent(bool isDark, double avatarSize, FrameReward? frame) {
    // When frame is selected, show frame's icon with gradient (like profile)
    if (frame != null) {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: frame.gradientColors,
          ),
          borderRadius: BorderRadius.circular(avatarSize * 0.25),
          boxShadow: [
            BoxShadow(
              color: frame.gradientColors.first.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            frame.iconData ?? Icons.star,
            color: Colors.white,
            size: avatarSize * 0.5,
          ),
        ),
      );
    }

    // No frame - show avatar or default
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(avatarSize * 0.18),
        border: Border.all(
          color: user.isOnline ? Colors.green : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: user.avatarUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(avatarSize * 0.15),
              child: Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(avatarSize),
              ),
            )
          : _buildDefaultAvatar(avatarSize),
    );
  }

  Widget _buildDefaultAvatar(double avatarSize) {
    return Center(
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: avatarSize * 0.45,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    final fontSize = _getResponsiveFontSize(context, 12);
    final iconSize = isTablet ? 18.0 : 16.0;
    final horizontalPad = isTablet ? 14.0 : 12.0;
    final verticalPad = isTablet ? 8.0 : 6.0;
    
    // Darken the color for better text readability
    final textColor = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness * 0.6).clamp(0.0, 1.0))
        .withSaturation((HSLColor.fromColor(color).saturation * 1.2).clamp(0.0, 1.0))
        .toColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionChip({
    required BuildContext context,
    required String division,
    required Color color,
    required bool isTablet,
  }) {
    final fontSize = _getResponsiveFontSize(context, 12);
    final horizontalPad = isTablet ? 14.0 : 12.0;
    final verticalPad = isTablet ? 8.0 : 6.0;

    final textColor = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness * 0.6).clamp(0.0, 1.0))
        .withSaturation((HSLColor.fromColor(color).saturation * 1.2).clamp(0.0, 1.0))
        .toColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DivisionBadge(rank: division, size: isTablet ? 18 : 16),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              division,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final stats = [
      {
        'label': l10n.gamesWon,
        'value': '${user.gamesWon}',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
      {
        'label': l10n.perfect,
        'value': '${user.perfectGames}',
        'icon': Icons.star,
        'color': Colors.purple,
      },
      {
        'label': l10n.winRate,
        'value': '${user.winRate.toStringAsFixed(1)}%',
        'icon': Icons.pie_chart,
        'color': Colors.green,
      },
      {
        'label': 'RP',
        'value': '${user.rankedPoints}',
        'icon': Icons.military_tech,
        'color': Colors.orange,
      },
    ];

    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final crossAxisCount = isLargeScreen ? 4 : 2;
    final childAspectRatio = isLargeScreen ? 1.5 : (isTablet ? 2.0 : 1.6);

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statistics,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14.w),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12.w,
              crossAxisSpacing: 12.w,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildStatCard(
                context: context,
                icon: stat['icon'] as IconData,
                value: stat['value'] as String,
                label: stat['label'] as String,
                color: stat['color'] as Color,
                isDark: isDark,
                isTablet: isTablet,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14.w),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isTablet ? 28.w : 24.w,
            color: color,
          ),
          SizedBox(height: 6.w),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 11),
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isTablet,
  ) {
    if (user.equippedBadgeIds.isEmpty) return const SizedBox.shrink();

    final badges = _getBadgeData(l10n);
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.badges,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.w),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.w,
            children: badges.map((badge) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16.w : 14.w,
                  vertical: isTablet ? 10.w : 8.w,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: badge['colors'] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(20.w),
                  boxShadow: [
                    BoxShadow(
                      color: (badge['colors'] as List<Color>)[0]
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge['imagePath'] != null)
                      Image.asset(
                        badge['imagePath'] as String,
                        width: _getResponsiveFontSize(context, 20),
                        height: _getResponsiveFontSize(context, 20),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            badge['icon'] as String,
                            style: TextStyle(
                                fontSize:
                                    _getResponsiveFontSize(context, 16)),
                          );
                        },
                      )
                    else
                      Text(
                        badge['icon'] as String,
                        style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 16)),
                      ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        badge['name'] as String,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.w),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final allAchievements = Achievements.getDefaultAchievements();
    final achievements = allAchievements
        .where((a) => user.unlockedAchievementIds.contains(a.id))
        .toList();

    if (achievements.isEmpty) return const SizedBox.shrink();

    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  l10n.achievements,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: Text(
                  '${achievements.length}/${Achievements.totalAvailable}',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 12),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.w),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal width for achievement chips
              final maxChipWidth = isLargeScreen
                  ? constraints.maxWidth / 3 - 10
                  : (isTablet
                      ? constraints.maxWidth / 2 - 10
                      : constraints.maxWidth);

              return Wrap(
                spacing: 10.w,
                runSpacing: 10.w,
                children: achievements.map((achievement) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxChipWidth),
                    child: _buildAchievementChip(
                      context: context,
                      achievement: achievement,
                      l10n: l10n,
                      isDark: isDark,
                      isTablet: isTablet,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementChip({
    required BuildContext context,
    required Achievement achievement,
    required AppLocalizations l10n,
    required bool isDark,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14.w : 12.w,
        vertical: isTablet ? 10.w : 8.w,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            achievement.imagePath,
            width: _getResponsiveFontSize(context, 20),
            height: _getResponsiveFontSize(context, 20),
            errorBuilder: (_, __, ___) => Text(
              achievement.icon,
              style: TextStyle(fontSize: _getResponsiveFontSize(context, 18)),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.achievementTitle(achievement.id),
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 11),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 2.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: _getResponsiveFontSize(context, 10),
                      color: AppColors.success,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '+${achievement.xpReward} XP',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 9),
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getBadgeData(AppLocalizations l10n) {
    final badgeDefinitions = {
      'early_bird': {
        'name': 'Early Bird',
        'icon': '🐦',
        'colors': [Colors.orange, Colors.deepOrange],
        'imagePath': 'assets/badges/profile/badge_early_bird.png',
      },
      'week_warrior': {
        'name': 'Week Warrior',
        'icon': '⚔️',
        'colors': [Colors.blue, Colors.indigo],
        'imagePath': 'assets/badges/profile/badge_week_warrior.png',
      },
      'puzzle_master': {
        'name': 'Puzzle Master',
        'icon': '🧩',
        'colors': [Colors.purple, Colors.deepPurple],
        'imagePath': 'assets/badges/profile/badge_puzzle_master.png',
      },
      'legend': {
        'name': 'Legend',
        'icon': '🌟',
        'colors': [Colors.amber, Colors.orange],
        'imagePath': 'assets/badges/profile/badge_legend.png',
      },
      'champion': {
        'name': 'Champion',
        'icon': '🏆',
        'colors': [Colors.pink, Colors.red],
        'imagePath': 'assets/badges/profile/badge_champion.png',
      },
    };

    return user.equippedBadgeIds
        .where((id) => badgeDefinitions.containsKey(id))
        .map((id) => badgeDefinitions[id]!)
        .toList();
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375).clamp(0.85, 1.3);
    return baseSize * scaleFactor;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(BuildContext context, DateTime date) {
    // Use locale-aware date formatting
    final locale = Localizations.localeOf(context).languageCode;

    switch (locale) {
      case 'tr':
        return '${date.day}.${date.month}.${date.year}';
      case 'zh':
      case 'ja':
        return '${date.year}/${date.month}/${date.day}';
      case 'ar':
        return '${date.day}/${date.month}/${date.year}';
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    if (rank <= 10) return Colors.purple;
    if (rank <= 50) return Colors.blue;
    if (rank <= 100) return Colors.teal;
    return Colors.grey;
  }

  Color _getDivisionColor(String division) {
    switch (division.toLowerCase()) {
      case 'champion':
        return const Color(0xFFFF4081);
      case 'grandmaster':
        return const Color(0xFFE040FB);
      case 'master':
        return const Color(0xFF7C4DFF);
      case 'diamond':
        return const Color(0xFF00BCD4);
      case 'platinum':
        return const Color(0xFF26C6DA);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'iron':
        return const Color(0xFF8D8D8D);
      default:
        return Colors.grey;
    }
  }
}
