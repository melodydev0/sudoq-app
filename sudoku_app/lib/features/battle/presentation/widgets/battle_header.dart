import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/app_theme_manager.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/widgets/user_avatar_with_frame.dart';

/// Data class for a player in the battle header.
class BattlePlayerInfo {
  final String displayName;
  final String? photoUrl;
  final String? equippedFrame;
  final String? countryCode;
  final String? avatarAsset;
  final int mistakes;
  final int progress;

  const BattlePlayerInfo({
    required this.displayName,
    this.photoUrl,
    this.equippedFrame,
    this.countryCode,
    this.avatarAsset,
    required this.mistakes,
    required this.progress,
  });
}

/// Header widget for the battle game screen.
///
/// Shows player avatars, names, mistake indicators, progress bars, VS label,
/// score and timer.
class BattleHeader extends StatelessWidget {
  final BattlePlayerInfo myPlayer;
  final BattlePlayerInfo opponent;
  final int score;
  final Duration elapsedTime;
  final VoidCallback onResign;

  const BattleHeader({
    super.key,
    required this.myPlayer,
    required this.opponent,
    required this.score,
    required this.elapsedTime,
    required this.onResign,
  });

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _truncate(String name, [int max = 8]) =>
      name.length > max ? '${name.substring(0, max)}...' : name;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Top row: back + score
          Row(
            children: [
              GestureDetector(
                onTap: onResign,
                child: const Icon(Icons.arrow_back, size: 24),
              ),
              const Spacer(),
              Text(
                '${l10n.score}: $score',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const Spacer(),
              SizedBox(width: 20.w),
            ],
          ),

          const SizedBox(height: 8),

          // Players row
          Row(
            children: [
              // My info (left)
              Expanded(
                child: Row(
                  children: [
                    UserAvatarWithFrame.currentUser(
                      size: 40.w,
                      showCountryFlag: true,
                      showAnimation: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _truncate(myPlayer.displayName),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          _MistakeRow(
                            mistakes: myPlayer.mistakes,
                            mainAxisAlignment: MainAxisAlignment.start,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Center: VS + Timer
              Column(
                children: [
                  Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    _formatTime(elapsedTime),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),

              // Opponent info (right)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _truncate(opponent.displayName),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          _MistakeRow(
                            mistakes: opponent.mistakes,
                            mainAxisAlignment: MainAxisAlignment.end,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    UserAvatarWithFrame(
                      size: 40.w,
                      displayName: opponent.displayName,
                      photoUrl: opponent.photoUrl,
                      frameId: opponent.equippedFrame,
                      countryCode: opponent.countryCode,
                      avatarAsset: opponent.avatarAsset,
                      showCountryFlag: true,
                      showAnimation: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bars
          Row(
            children: [
              _ProgressBadge(value: myPlayer.progress, color: Colors.green),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: myPlayer.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'VS',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: opponent.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _ProgressBadge(value: opponent.progress, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

class _MistakeRow extends StatelessWidget {
  final int mistakes;
  final MainAxisAlignment mainAxisAlignment;

  const _MistakeRow({required this.mistakes, required this.mainAxisAlignment});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Text(
            'X',
            style: TextStyle(
              fontSize: 14.sp,
              color: i < mistakes ? Colors.red : Colors.grey.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int value;
  final Color color;

  const _ProgressBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
