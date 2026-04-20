import 'package:flutter/material.dart';
import '../services/local_duel_stats_service.dart';

/// Reusable widget that displays a duel division/rank icon.
/// Uses the premium PNG asset from assets/divisions/ with emoji fallback.
class DivisionBadge extends StatelessWidget {
  final String rank;
  final double size;
  final bool showGlow;

  const DivisionBadge({
    super.key,
    required this.rank,
    this.size = 32,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = LocalDuelStatsService.getRankImagePath(rank);
    final color = Color(LocalDuelStatsService.getDivisionColorValue(rank));

    return Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.15),
              child: Image.asset(
                imagePath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildEmojiFallback(),
              ),
            )
          : _buildEmojiFallback(),
    );
  }

  Widget _buildEmojiFallback() {
    return Center(
      child: Text(
        LocalDuelStatsService.getRankEmoji(rank),
        style: TextStyle(fontSize: size * 0.65),
      ),
    );
  }
}
