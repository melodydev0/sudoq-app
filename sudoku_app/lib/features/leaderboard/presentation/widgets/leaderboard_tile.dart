import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/leaderboard_user.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/widgets/animated_frame.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';

class LeaderboardTile extends StatelessWidget {
  final LeaderboardUser user;
  final String type; // 'level' or 'ranked'
  final VoidCallback onTap;
  final bool isCurrentUser;

  const LeaderboardTile({
    super.key,
    required this.user,
    required this.type,
    required this.onTap,
    this.isCurrentUser = false,
  });

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375).clamp(0.85, 1.25);
    return baseSize * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final isTopThree = user.rank <= 3;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 12.w : 10.w),
        padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? theme.buttonPrimary
              : isTopThree
                  ? _getTopThreeColor(user.rank)
                      .withValues(alpha: theme.isDark ? 0.2 : 0.1)
                  : theme.card,
          borderRadius: AppTheme.cardRadius,
          border: isCurrentUser
              ? Border.all(color: theme.buttonPrimary, width: 2)
              : isTopThree
                  ? Border.all(
                      color:
                          _getTopThreeColor(user.rank).withValues(alpha: 0.5),
                      width: 1.5)
                  : Border.all(color: theme.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary
                  .withValues(alpha: isCurrentUser ? 0.15 : 0.06),
              blurRadius: isCurrentUser ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            _buildRankBadge(context, theme, isTablet),
            SizedBox(width: isTablet ? 14.w : 12.w),
            // Avatar with flag
            _buildAvatar(context, theme, isTablet),
            SizedBox(width: isTablet ? 14.w : 12.w),
            // User info
            Expanded(child: _buildUserInfo(context, theme, isTablet)),
            // Stats
            _buildStats(context, theme, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(
      BuildContext context, AppThemeColors theme, bool isTablet) {
    final isTopThree = user.rank <= 3;
    final badgeSize = isTablet ? 40.0 : 36.0;

    if (isTopThree) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: _getTopThreeColor(user.rank),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getTopThreeColor(user.rank).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getRankEmoji(user.rank),
            style: TextStyle(fontSize: _getResponsiveFontSize(context, 18)),
          ),
        ),
      );
    }

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.buttonText.withValues(alpha: 0.25)
            : theme.accentLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '${user.rank}',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? theme.buttonText : theme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Güvenli çerçeve araması – firstWhere atmayı önler, leaderboard kitlenmez.
  FrameReward? _frameById(String id) {
    for (final f in CosmeticRewards.frames) {
      if (f.id == id) return f;
    }
    for (final f in CosmeticRewards.rankedFrames) {
      if (f.id == id) return f;
    }
    return null;
  }

  Widget _buildAvatar(
      BuildContext context, AppThemeColors theme, bool isTablet) {
    // Get frame if user has one equipped (safe lookup – no firstWhere throw)
    FrameReward? frame;
    if (user.equippedFrame != null && user.equippedFrame!.isNotEmpty) {
      frame = _frameById(user.equippedFrame!);
    }

    final avatarSize = isTablet ? 42.0 : 36.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar with animated frame
        AnimatedAvatarFrame(
          frame: frame,
          size: avatarSize,
          showAnimation: frame != null,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(avatarSize * 0.28),
              border: Border.all(
                color: user.isOnline ? theme.success : Colors.transparent,
                width: 2,
              ),
            ),
            child: user.avatarUrl != null && user.avatarUrl!.length == 1
                ? _buildAvatarLetter(
                    context, theme, avatarSize, user.avatarUrl!)
                : user.avatarUrl != null && user.avatarUrl!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(avatarSize * 0.22),
                        child: Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultAvatar(context, theme, avatarSize),
                        ),
                      )
                    : _buildDefaultAvatar(context, theme, avatarSize),
          ),
        ),
        // Country flag
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              user.countryFlag,
              style: TextStyle(fontSize: _getResponsiveFontSize(context, 10)),
            ),
          ),
        ),
        // Online indicator
        if (user.isOnline)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: theme.success,
                shape: BoxShape.circle,
                border: Border.all(color: theme.card, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar(
      BuildContext context, AppThemeColors theme, double size) {
    return Center(
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: theme.accent,
        ),
      ),
    );
  }

  Widget _buildAvatarLetter(
      BuildContext context, AppThemeColors theme, double size, String letter) {
    return Center(
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: theme.accent,
        ),
      ),
    );
  }

  Widget _buildUserInfo(
      BuildContext context, AppThemeColors theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.username,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: isCurrentUser ? theme.buttonText : theme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                decoration: BoxDecoration(
                  color: theme.buttonText.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 9),
                    fontWeight: FontWeight.bold,
                    color: theme.buttonText,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 3.w),
        Wrap(
          spacing: 6.w,
          runSpacing: 4.w,
          children: [
            // Level badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? theme.buttonText.withValues(alpha: 0.25)
                    : theme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: Text(
                'Lv.${user.level}',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 10),
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? theme.buttonText : theme.accent,
                ),
              ),
            ),
            if (type == 'ranked' && user.division != null)
              // Division badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.buttonText.withValues(alpha: 0.25)
                      : _getDivisionColor(user.division!)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Text(
                  user.division!,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 10),
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? theme.buttonText
                        : _getDivisionColor(user.division!),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Achievements count
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: _getResponsiveFontSize(context, 12),
                  color: isCurrentUser
                      ? theme.buttonText.withValues(alpha: 0.9)
                      : theme.warning,
                ),
                SizedBox(width: 2.w),
                Text(
                  '${user.unlockedAchievementIds.length}',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 10),
                    color: isCurrentUser
                        ? theme.buttonText.withValues(alpha: 0.9)
                        : theme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(
      BuildContext context, AppThemeColors theme, bool isTablet) {
    final value = type == 'level' ? user.totalXp : user.rankedPoints;
    final label = type == 'level' ? 'XP' : 'RP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              color: isCurrentUser ? theme.buttonText : theme.textPrimary,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context, 11),
            color: isCurrentUser
                ? theme.buttonText.withValues(alpha: 0.9)
                : theme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Color _getTopThreeColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
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
