import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/battle_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'matchmaking_screen.dart';
import 'battle_game_screen.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';

class BattleLobbyScreen extends ConsumerStatefulWidget {
  const BattleLobbyScreen({super.key});

  @override
  ConsumerState<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends ConsumerState<BattleLobbyScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isSyncing = false;

  // For animated rank progress
  double _previousProgress = 0.0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeAndLoadStats() async {
    // Initialize local stats
    await LocalDuelStatsService.init();

    // Clear any pending ELO animations (we show them in result screen now)
    LocalDuelStatsService.clearPendingEloChange();

    // Load local stats immediately (don't wait for cloud sync)
    if (mounted) {
      setState(() {
        _stats = LocalDuelStatsService.getAllStats();
        _isLoading = false;
        _isFirstLoad = false;
      });
    }

    // Cloud sync in background (non-blocking)
    if (AuthService.isSignedIn && !AuthService.isAnonymous) {
      _syncWithCloud(); // Don't await - run in background
    }

    // Anonymous sign-in only when user taps "Start Duel" – avoids double call
    // and native crash from two simultaneous signInAnonymously() calls.
  }

  Future<void> _syncWithCloud() async {
    if (!AuthService.isSignedIn || AuthService.isAnonymous) return;

    try {
      final cloudStats = await AuthService.getBattleStats();
      if (cloudStats != null) {
        await LocalDuelStatsService.importFromCloud(cloudStats);
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _onStartDuel() async {
    HapticFeedback.mediumImpact();

    if (!AuthService.isSignedIn) {
      // Don't call signInAnonymously() – it can freeze on some devices.
      // Offer Google sign-in or Play vs AI instead.
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in to play Duel'),
          content: const Text(
            'To play online you need to sign in. Sign in with Google to find opponents, or play vs AI without an account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _startAiBattle('easy');
              },
              child: const Text('Play vs AI'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _signInWithGoogle();
                if (mounted && AuthService.isSignedIn) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchmakingScreen(),
                    ),
                  );
                }
              },
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MatchmakingScreen(),
        ),
      );
    } catch (e, st) {
      debugPrint('Start Duel / Matchmaking error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Three small AI difficulty buttons (no pop-up). Integrated like home difficulty grid.
  Widget _buildPlayVsAiRow(AppThemeColors theme) {
    final nav = Navigator.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildAiDifficultyChip(
            theme,
            difficulty: 'easy',
            label: 'Rookie',
            color: theme.success,
            icon: Bootstrap.emoji_smile,
            onTap: () => _startAiBattle('easy', navigator: nav),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAiDifficultyChip(
            theme,
            difficulty: 'medium',
            label: 'Pro',
            color: theme.accent,
            icon: Bootstrap.emoji_neutral,
            onTap: () => _startAiBattle('medium', navigator: nav),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAiDifficultyChip(
            theme,
            difficulty: 'hard',
            label: 'Master',
            color: AppColors.error,
            icon: Bootstrap.emoji_angry,
            onTap: () => _startAiBattle('hard', navigator: nav),
          ),
        ),
      ],
    );
  }

  Widget _buildAiDifficultyChip(
    AppThemeColors theme, {
    required String difficulty,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAiBattle(String difficulty,
      {NavigatorState? navigator}) async {
    final ctx = navigator?.context ?? context;
    debugPrint('[PlayAI] _startAiBattle entered: $difficulty');
    HapticFeedback.mediumImpact();

    // Show loading dialog (use navigator context so it works when lobby is unmounted)
    final theme = AppThemeManager.colors;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: AppTheme.cardRadius,
            boxShadow: [
              BoxShadow(
                color: theme.textPrimary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Builder(
                builder: (ctx) => Text(
                  AppLocalizations.of(ctx).preparingBattle,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Small delay to let UI render
    await Future.delayed(const Duration(milliseconds: 100));

    // Create test battle with selected AI difficulty (runs puzzle generation)
    debugPrint('[PlayAI] Calling createTestBattle...');
    final battle =
        await BattleService.createTestBattle(aiDifficulty: difficulty);
    debugPrint(
        '[PlayAI] createTestBattle returned: ${battle != null ? battle.id : "null"}');

    // Hide loading (use same context)
    if (ctx.mounted) Navigator.of(ctx).pop();

    if (battle != null && ctx.mounted) {
      debugPrint('[PlayAI] Pushing BattleGameScreen');
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (context) => BattleGameScreen(battleId: battle.id),
        ),
      );
    } else if (ctx.mounted) {
      debugPrint('[PlayAI] Battle null, showing error');
      final l10n = AppLocalizations.of(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToCreateBattle),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isSyncing = true);
    final result = await AuthService.signInWithApple();
    if (result != null && mounted) {
      await _syncWithCloud();
      setState(() {
        _stats = LocalDuelStatsService.getAllStats();
        _isSyncing = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('${l10n.syncedAs} ${AuthService.displayName}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSyncing = true);

    final result = await AuthService.signInWithGoogle();

    if (result != null && mounted) {
      // Sync local stats to cloud
      await _syncWithCloud();

      // Upload local progress to cloud if needed
      if (LocalDuelStatsService.totalGames > 0) {
        await AuthService.syncBattleStatsFromLocal(
            LocalDuelStatsService.exportForCloud());
        await LocalDuelStatsService.markSynced();
      }

      setState(() {
        _stats = LocalDuelStatsService.getAllStats();
        _isSyncing = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('${l10n.syncedAs} ${AuthService.displayName}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.backgroundGradientStart,
              theme.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Player Card
                            _buildPlayerCard(theme),

                            const SizedBox(height: 24),

                            // Start Duel Button
                            _buildStartDuelButton(theme, size),

                            const SizedBox(height: 12),

                            // Play vs AI — 3 small buttons (no pop-up)
                            Row(
                              children: [
                                Icon(Bootstrap.robot,
                                    size: 16, color: theme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Play vs AI',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textSecondary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildPlayVsAiRow(theme),

                            const SizedBox(height: 24),

                            // Stats Grid
                            _buildStatsGrid(theme),

                            const SizedBox(height: 24),

                            // Rank Progress
                            _buildRankProgress(theme),

                            const SizedBox(height: 24),

                            // Sync Section (if not signed in with Google)
                            if (!AuthService.isSignedIn ||
                                AuthService.isAnonymous)
                              _buildSyncSection(theme),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors theme) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Title (left)
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: AppTheme.buttonRadius,
                  boxShadow: [
                    BoxShadow(
                      color: theme.textPrimary.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Bootstrap.lightning_charge_fill,
                  color: theme.buttonText,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.duel,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  Text(
                    'ELO-based competition',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Leaderboard button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LeaderboardScreen(initialTab: 1)),
              );
            },
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: theme.buttonSecondary,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: theme.cardBorder),
              ),
              child: Icon(
                Bootstrap.bar_chart_fill,
                color: theme.iconPrimary,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Info button
          GestureDetector(
            onTap: () => _showDuelInfoSheet(theme, l10n),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: theme.buttonSecondary,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: theme.cardBorder),
              ),
              child: Icon(
                Bootstrap.info_circle,
                color: theme.iconPrimary,
                size: 20.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDuelInfoSheet(AppThemeColors theme, AppLocalizations l10n) {
    HapticFeedback.mediumImpact();
    final isDark = theme.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.w),
              width: 40.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: theme.accent,
                      borderRadius: AppTheme.buttonRadius,
                    ),
                    child: Icon(
                      Bootstrap.lightning_charge_fill,
                      color: theme.buttonText,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.duelDivisions,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          l10n.climbTheRanks,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              height: 1,
            ),

            // Divisions list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                children: [
                  _buildDivisionTile('Champion', '2300+',
                      const Color(0xFFFF4500), '🔥', true, isDark, theme),
                  _buildDivisionTile('Grandmaster', '2000 - 2299',
                      const Color(0xFF9400D3), '👑', false, isDark, theme),
                  _buildDivisionTile('Master', '1700 - 1999',
                      const Color(0xFFFFA500), '🏆', false, isDark, theme),
                  _buildDivisionTile('Diamond', '1400 - 1699',
                      const Color(0xFF1E90FF), '💠', false, isDark, theme),
                  _buildDivisionTile('Platinum', '1100 - 1399',
                      const Color(0xFF00BFFF), '💎', false, isDark, theme),
                  _buildDivisionTile('Gold', '800 - 1099',
                      const Color(0xFFFF8C00), '🥇', false, isDark, theme),
                  _buildDivisionTile('Silver', '500 - 799',
                      const Color(0xFFC0C0C0), '🥈', false, isDark, theme),
                  _buildDivisionTile('Bronze', '0 - 499',
                      const Color(0xFFCD7F32), '🥉', false, isDark, theme),
                ],
              ),
            ),

            // Rules section
            _buildDuelRulesSection(theme, l10n, isDark),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16.w),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionTile(String name, String eloRange, Color color,
      String emoji, bool isTop, bool isDark, AppThemeColors theme) {
    final currentRank = _stats['rank'] ?? 'Bronze';
    final isCurrentDivision = name == currentRank;

    return Container(
      margin: EdgeInsets.only(bottom: 10.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: isCurrentDivision
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.15),
                ],
              )
            : null,
        color: isCurrentDivision
            ? null
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(14.w),
        border: isCurrentDivision
            ? Border.all(color: color, width: 2)
            : Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
        boxShadow: isCurrentDivision
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Division emoji
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isCurrentDivision ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
          ),
          SizedBox(width: 14.w),

          // Division info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isCurrentDivision
                              ? color
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentDivision) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.w),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6.w),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.w),
                Text(
                  '$eloRange ELO',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuelRulesSection(
      AppThemeColors theme, AppLocalizations l10n, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.accentLight,
        borderRadius: AppTheme.buttonRadius,
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Bootstrap.info_circle,
                size: 18.w,
                color: theme.accent,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.duelRules,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          _buildRuleRow('⚔️', l10n.duelRuleCompete, isDark),
          SizedBox(height: 6.w),
          _buildRuleRow('🚫', l10n.duelRuleNoHints, isDark),
          SizedBox(height: 6.w),
          _buildRuleRow('📈', l10n.duelRuleElo, isDark),
          SizedBox(height: 6.w),
          _buildRuleRow('❌', l10n.duelRuleMistakes, isDark),
          SizedBox(height: 12.w),
          Divider(
              color: isDark ? Colors.white24 : Colors.grey.shade300, height: 1),
          SizedBox(height: 12.w),
          _buildEloInfoRow(Icons.emoji_events, Colors.green, l10n.duelWin,
              '+15-30 ELO', isDark),
          SizedBox(height: 8.w),
          _buildEloInfoRow(
              Icons.close, Colors.red, l10n.duelLoss, '-10-20 ELO', isDark),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String emoji, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: 13.sp)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEloInfoRow(
      IconData icon, Color color, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: color),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6.w),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(AppThemeColors theme) {
    final elo = _stats['elo'] ?? 1000;
    final rank = _stats['rank'] ?? 'Row';
    final isGoogleSignedIn = AuthService.isSignedIn && !AuthService.isAnonymous;

    // Rank colors
    final rankColor = _getRankColor(rank);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGoogleSignedIn ? Colors.green : Colors.amber,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: isGoogleSignedIn && AuthService.photoUrl != null
                      ? Image.network(
                          AuthService.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultAvatar(theme),
                        )
                      : _buildDefaultAvatar(theme),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isGoogleSignedIn
                                ? AuthService.displayName
                                : 'Guest Player',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isGoogleSignedIn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Local',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ELO
              Column(
                children: [
                  Text(
                    '$elo',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.accent,
                    ),
                  ),
                  Text(
                    'ELO',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rank Badge - Big and visible!
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor.withValues(alpha: 0.15),
                  rankColor.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: rankColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  LocalDuelStatsService.getRankEmoji(rank),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Rank',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.textSecondary,
                      ),
                    ),
                    Text(
                      rank.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        letterSpacing: 2,
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

  Color _getRankColor(String rank) {
    // Division colors matching Ranked system
    switch (rank) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFF8C00);
      case 'Platinum':
        return const Color(0xFF00BFFF);
      case 'Diamond':
        return const Color(0xFF1E90FF);
      case 'Master':
        return const Color(0xFFFFA500);
      case 'Grandmaster':
        return const Color(0xFF9400D3);
      case 'Champion':
        return const Color(0xFFFF4500);
      default:
        return const Color(0xFFCD7F32); // Default to Bronze
    }
  }

  Widget _buildDefaultAvatar(AppThemeColors theme) {
    return Container(
      color: theme.accent.withValues(alpha: 0.2),
      child: Icon(
        Icons.person,
        size: 32,
        color: theme.accent,
      ),
    );
  }

  Widget _buildStartDuelButton(AppThemeColors theme, Size size) {
    return GestureDetector(
      onTap: _onStartDuel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.buttonPrimary,
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Bootstrap.lightning_charge_fill,
              color: theme.buttonText,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Start Duel',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: theme.buttonText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppThemeColors theme) {
    final wins = _stats['wins'] ?? 0;
    final losses = _stats['losses'] ?? 0;
    final winRate = (_stats['winRate'] ?? 0.0).toStringAsFixed(1);
    final winStreak = _stats['winStreak'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'Wins',
            '$wins',
            Colors.green,
            Bootstrap.check_circle_fill,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'Losses',
            '$losses',
            Colors.red,
            Bootstrap.x_circle_fill,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'Win Rate',
            '$winRate%',
            Colors.blue,
            Bootstrap.percent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'Streak',
            '$winStreak',
            Colors.orange,
            Bootstrap.fire,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    AppThemeColors theme,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankProgress(AppThemeColors theme) {
    final elo = _stats['elo'] ?? 1000;
    final rank = _stats['rank'] ?? 'Bronze';

    // Calculate progress to next rank (correct division names)
    final rankThresholds = {
      'Bronze': [0, 500],
      'Silver': [500, 800],
      'Gold': [800, 1100],
      'Platinum': [1100, 1400],
      'Diamond': [1400, 1700],
      'Master': [1700, 2000],
      'Grandmaster': [2000, 2300],
      'Champion': [2300, 9999],
    };

    final currentRange = rankThresholds[rank] ?? [0, 500];
    final rangeSize = currentRange[1] - currentRange[0];
    final rawProgress = ((elo - currentRange[0]) / rangeSize).clamp(0.0, 1.0);
    // Minimum visual progress of 5% so bar is always visible
    final targetProgress = rawProgress < 0.05 ? 0.05 : rawProgress;
    final toNextRank = (currentRange[1] - elo).clamp(0, 9999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rank Progress',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              if (rank != 'Champion')
                Text(
                  '+$toNextRank ELO to next rank',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Progress bar with percentage
          LayoutBuilder(
            builder: (context, constraints) {
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(
                  begin: _isFirstLoad ? 0 : _previousProgress,
                  end: targetProgress,
                ),
                onEnd: () {
                  _previousProgress = targetProgress;
                },
                builder: (context, animatedProgress, child) {
                  final barWidth = constraints.maxWidth * animatedProgress;
                  final progressPercent = (animatedProgress * 100).toInt();

                  return Stack(
                    children: [
                      // Background
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      // Animated filled progress
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: barWidth,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: theme.accent.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      // Percentage text
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: progressPercent > 40
                                  ? Colors.white
                                  : theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Rank badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${LocalDuelStatsService.getRankEmoji(rank)} $rank',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                '${currentRange[0]} - ${currentRange[1]} ELO',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection(AppThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload,
                    color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Your Progress',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to save your progress across devices',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _signInWithGoogle,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Bootstrap.google, size: 18),
              label: Text(_isSyncing ? 'Syncing...' : 'Sign In with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Sign in with Apple only on iOS (IPA)
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSyncing ? null : _signInWithApple,
                icon: const Icon(Bootstrap.apple, size: 18),
                label: const Text('Sign in with Apple'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textPrimary,
                  side: BorderSide(color: theme.divider),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (LocalDuelStatsService.totalGames > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: theme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${LocalDuelStatsService.totalGames} games will be synced',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
