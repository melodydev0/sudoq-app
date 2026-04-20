import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Info bar showing mistakes, score (with combo), and elapsed time.
class GameInfoBar extends StatelessWidget {
  final int mistakes;
  final int maxMistakes;
  final int score;
  final int comboStreak;
  final double comboMultiplier;
  final Duration elapsedTime;
  final bool showComboMilestone;
  final int lastMilestoneCombo;
  final Color textColor;
  final bool isDark;

  const GameInfoBar({
    super.key,
    required this.mistakes,
    required this.maxMistakes,
    required this.score,
    required this.comboStreak,
    required this.comboMultiplier,
    required this.elapsedTime,
    required this.showComboMilestone,
    required this.lastMilestoneCombo,
    required this.textColor,
    required this.isDark,
  });

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mistakeColor = mistakes > 0
        ? Colors.red
        : (isDark ? Colors.grey.shade400 : Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoItem(
            icon: Bootstrap.x_circle,
            label: l10n.mistakes,
            value: '$mistakes/$maxMistakes',
            color: mistakeColor,
            isDark: isDark,
          ),
          _ScoreWithCombo(
            l10n: l10n,
            score: score,
            multiplier: comboMultiplier,
            showComboMilestone: showComboMilestone,
            lastMilestoneCombo: lastMilestoneCombo,
            isDark: isDark,
          ),
          _InfoItem(
            icon: Bootstrap.stopwatch,
            label: l10n.time,
            value: _formatTime(elapsedTime),
            color: textColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _ScoreWithCombo extends StatelessWidget {
  final AppLocalizations l10n;
  final int score;
  final double multiplier;
  final bool showComboMilestone;
  final int lastMilestoneCombo;
  final bool isDark;

  const _ScoreWithCombo({
    required this.l10n,
    required this.score,
    required this.multiplier,
    required this.showComboMilestone,
    required this.lastMilestoneCombo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor = const Color(0xFFFFB300);
    if (multiplier >= 3.0) {
      scoreColor = Colors.deepOrange;
    } else if (multiplier >= 2.0) {
      scoreColor = Colors.orange;
    }

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Bootstrap.star_fill, size: 18, color: scoreColor),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.score,
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            if (showComboMilestone) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${lastMilestoneCombo}x 🔥',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
