import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';

class GameCompleteDialog extends StatefulWidget {
  final bool won;
  final int score;
  final Duration time;
  final int mistakes;
  final String difficulty;
  final VoidCallback onNewGame;
  final VoidCallback onHome;

  const GameCompleteDialog({
    super.key,
    required this.won,
    required this.score,
    required this.time,
    required this.mistakes,
    required this.difficulty,
    required this.onNewGame,
    required this.onHome,
  });

  @override
  State<GameCompleteDialog> createState() => _GameCompleteDialogState();
}

class _GameCompleteDialogState extends State<GameCompleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dialogScale;
  late Animation<double> _dialogFade;
  late Animation<double> _iconLift;
  late Animation<double> _iconScale;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _statsFade;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _dialogScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _dialogFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _iconLift = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _iconScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.52, curve: Curves.elasticOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final won = widget.won;

    return FadeTransition(
      opacity: _dialogFade,
      child: ScaleTransition(
        scale: _dialogScale,
        child: Dialog(
          backgroundColor: theme.card,
          shape: const RoundedRectangleBorder(
            borderRadius: AppTheme.cardRadius,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, _iconLift.value),
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: won
                                  ? theme.success.withValues(alpha: 0.18)
                                  : AppColors.error.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (won ? theme.success : AppColors.error)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              won
                                  ? Icons.emoji_events
                                  : Icons.sentiment_dissatisfied,
                              size: 44,
                              color: won ? theme.accent : AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        won ? 'Congratulations!' : 'Game Over',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        won
                            ? 'You solved the puzzle!'
                            : 'You made too many mistakes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: theme.textSecondary,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _statsFade,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.accentLight,
                          borderRadius: AppTheme.cardRadius,
                          border: Border.all(color: theme.divider, width: 1),
                        ),
                        child: Column(
                          children: [
                            _StatRow(
                                label: 'Difficulty',
                                value: widget.difficulty,
                                theme: theme),
                            const SizedBox(height: 8),
                            _StatRow(
                                label: 'Time',
                                value: _formatTime(widget.time),
                                theme: theme),
                            if (won) ...[
                              const SizedBox(height: 8),
                              _StatRow(
                                label: 'Score',
                                value: '${widget.score}',
                                highlight: true,
                                theme: theme,
                              ),
                            ],
                            const SizedBox(height: 8),
                            _StatRow(
                              label: 'Mistakes',
                              value: '${widget.mistakes}/3',
                              isError: widget.mistakes > 0,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _buttonsFade,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onHome,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppTheme.buttonRadius,
                                ),
                                side: BorderSide(
                                    color: theme.accent.withValues(alpha: 0.5)),
                              ),
                              child: const Text('Home'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onNewGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.buttonPrimary,
                                foregroundColor: theme.buttonText,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppTheme.buttonRadius,
                                ),
                                elevation: 1,
                                shadowColor:
                                    theme.textPrimary.withValues(alpha: 0.08),
                              ),
                              child: const Text('New Game'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isError;
  final AppThemeColors theme;

  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? theme.accent
                : isError
                    ? AppColors.error
                    : theme.textPrimary,
            fontSize: 14.sp,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
