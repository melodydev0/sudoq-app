import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/game_icons.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/models/daily_challenge_system.dart';

/// Monthly Badge Widget - Using professional Game Icons
class MonthlyBadgeWidget extends StatelessWidget {
  final MonthBadgeInfo badgeInfo;
  final bool isEarned;
  final bool isLocked;
  final double size;
  final int? completedDays;
  final int? totalDays;
  final bool showProgress;
  final bool showBackground;
  final VoidCallback? onTap;
  final bool animated;

  const MonthlyBadgeWidget({
    super.key,
    required this.badgeInfo,
    this.isEarned = false,
    this.isLocked = false,
    this.size = 100,
    this.completedDays,
    this.totalDays,
    this.showProgress = true,
    this.showBackground = false,
    this.onTap,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final monthData = _MonthIconData.getForMonth(badgeInfo.month);

    return GestureDetector(
      onTap: onTap,
      child: ShaderMask(
        shaderCallback: (bounds) {
          if (isLocked) {
            return LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade500],
            ).createShader(bounds);
          }
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEarned
                ? monthData.gradientColors
                : [
                    monthData.gradientColors[0].withValues(alpha: 0.5),
                    monthData.gradientColors[1].withValues(alpha: 0.5),
                  ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: Iconify(
          isLocked ? GameIcons.padlock : monthData.icon,
          size: size.w,
          color: Colors.white, // Will be replaced by shader
        ),
      ),
    );
  }
}

/// Large Badge Widget for detail view - Creates desire to own the badge
class LargeBadgeWidget extends StatelessWidget {
  final MonthBadgeInfo badgeInfo;
  final bool isEarned;
  final int completedDays;
  final int totalDays;
  final String monthName;
  final int year;

  const LargeBadgeWidget({
    super.key,
    required this.badgeInfo,
    required this.isEarned,
    required this.completedDays,
    required this.totalDays,
    required this.monthName,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final monthData = _MonthIconData.getForMonth(badgeInfo.month);
    final progress = totalDays > 0 ? completedDays / totalDays : 0.0;
    final remaining = totalDays - completedDays;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge preview - ALWAYS show in full color to create desire
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: monthData.gradientColors[0]
                        .withValues(alpha: isEarned ? 0.6 : 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Main badge - always colorful
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: monthData.gradientColors,
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Iconify(
                monthData.icon,
                size: 120.w,
                color: Colors.white,
              ),
            ),

            // Lock overlay for unearned badges
            if (!isEarned)
              Positioned(
                right: 10.w,
                bottom: 10.w,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 20.w,
                  ),
                ),
              ),

            // Checkmark for earned badges
            if (isEarned)
              Positioned(
                right: 5.w,
                bottom: 5.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20.w,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 20.w),

        // Badge name - always colorful
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: monthData.gradientColors,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            monthData.name,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(height: 4.w),

        // Date
        Text(
          '$monthName $year',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade500,
          ),
        ),

        SizedBox(height: 20.w),

        // Progress section
        if (isEarned)
          // Earned celebration
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  monthData.gradientColors[0].withValues(alpha: 0.15),
                  monthData.gradientColors[1].withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(
                color: monthData.gradientColors[0].withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: monthData.gradientColors[0],
                  size: 24.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  'Badge Earned!',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: monthData.gradientColors[0],
                  ),
                ),
              ],
            ),
          )
        else
          // Progress to unlock
          Column(
            children: [
              // Progress bar
              Container(
                width: 200.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient:
                              LinearGradient(colors: monthData.gradientColors),
                          borderRadius: BorderRadius.circular(6.w),
                          boxShadow: [
                            BoxShadow(
                              color: monthData.gradientColors[0]
                                  .withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.w),

              // Progress text
              RichText(
                text: TextSpan(
                  style:
                      TextStyle(fontSize: 15.sp, color: Colors.grey.shade700),
                  children: [
                    TextSpan(
                      text: '$completedDays',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: monthData.gradientColors[0],
                        fontSize: 18.sp,
                      ),
                    ),
                    TextSpan(text: ' / $totalDays days'),
                  ],
                ),
              ),

              SizedBox(height: 16.w),

              // Motivational text
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
                decoration: BoxDecoration(
                  color: monthData.gradientColors[0].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_outline,
                      color: monthData.gradientColors[0],
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      remaining > 0
                          ? 'Complete $remaining more days!'
                          : 'Almost there!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: monthData.gradientColors[0],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Month icon data - Professional game icons for each month
class _MonthIconData {
  final String icon;
  final String name;
  final List<Color> gradientColors;

  const _MonthIconData({
    required this.icon,
    required this.name,
    required this.gradientColors,
  });

  static _MonthIconData getForMonth(int month) {
    switch (month) {
      case 1: // January - Frozen/Ice Crystal
        return const _MonthIconData(
          icon: GameIcons.frozen_orb,
          name: 'Frost Master',
          gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      case 2: // February - Heart/Love
        return const _MonthIconData(
          icon: GameIcons.glass_heart,
          name: 'Heart Keeper',
          gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        );
      case 3: // March - Sprouting plant
        return const _MonthIconData(
          icon: GameIcons.vine_flower,
          name: 'Spring Bloom',
          gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        );
      case 4: // April - Diamond/Gem
        return const _MonthIconData(
          icon: GameIcons.cut_diamond,
          name: 'Diamond Soul',
          gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case 5: // May - Flower
        return const _MonthIconData(
          icon: GameIcons.lotus_flower,
          name: 'Lotus Warrior',
          gradientColors: [Color(0xFFfa709a), Color(0xFFfee140)],
        );
      case 6: // June - Sun
        return const _MonthIconData(
          icon: GameIcons.sun,
          name: 'Sun Champion',
          gradientColors: [Color(0xFFf6d365), Color(0xFFfda085)],
        );
      case 7: // July - Trophy (Peak Summer)
        return const _MonthIconData(
          icon: GameIcons.trophy,
          name: 'Summer Legend',
          gradientColors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        );
      case 8: // August - Crown
        return const _MonthIconData(
          icon: GameIcons.crown,
          name: 'Royal Victor',
          gradientColors: [Color(0xFFf5af19), Color(0xFFf12711)],
        );
      case 9: // September - Falling leaf
        return const _MonthIconData(
          icon: GameIcons.falling_leaf,
          name: 'Autumn Spirit',
          gradientColors: [Color(0xFFee9ca7), Color(0xFFffdde1)],
        );
      case 10: // October - Ghost/Halloween
        return const _MonthIconData(
          icon: GameIcons.spectre,
          name: 'Shadow Hunter',
          gradientColors: [Color(0xFFff9a44), Color(0xFFfc6076)],
        );
      case 11: // November - Fire/Harvest
        return const _MonthIconData(
          icon: GameIcons.flame,
          name: 'Fire Keeper',
          gradientColors: [Color(0xFFd299c2), Color(0xFFfef9d7)],
        );
      case 12: // December - Snowflake/Winter
        return const _MonthIconData(
          icon: GameIcons.snowflake_1,
          name: 'Winter Hero',
          gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      default:
        return const _MonthIconData(
          icon: GameIcons.trophy,
          name: 'Champion',
          gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
    }
  }
}
