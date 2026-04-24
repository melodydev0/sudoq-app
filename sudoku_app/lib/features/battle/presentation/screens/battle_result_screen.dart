import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/battle_models.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/battle_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/lottie_loader.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/user_avatar_with_frame.dart';
import '../../../../core/widgets/division_badge.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../widgets/rank_up_celebration_overlay.dart';

class BattleResultScreen extends StatefulWidget {
  final String battleId;
  final Duration completionTime;
  final int mistakes;
  final String? forcedResult; // 'win' or 'lose' for test battles
  final int? eloChange; // ELO change based on AI difficulty
  // Pre-calculated ELO values to avoid race condition with recordWin/recordLoss
  final int? startElo;
  final int? newElo;
  final String? rankUpFrom;
  final String? rankUpTo;

  const BattleResultScreen({
    super.key,
    required this.battleId,
    required this.completionTime,
    required this.mistakes,
    this.forcedResult,
    this.eloChange,
    this.startElo,
    this.newElo,
    this.rankUpFrom,
    this.rankUpTo,
  });

  @override
  State<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends State<BattleResultScreen>
    with TickerProviderStateMixin {
  BattleRoom? _battle;
  bool _isLoading = true;
  bool _won = false;
  int _eloChange = 0;
  int _newElo = 800;
  int _startElo = 800; // ELO before the match
  int _displayedElo = 800; // Animated ELO display
  String _rankName = 'Bronze';
  int _earnedXp = 0;
  bool _showRankUpCelebration = false;
  String? _rankUpFrom;
  String? _rankUpTo;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // ELO counting animation
  late AnimationController _eloAnimController;
  late Animation<double> _eloCountAnimation;
  late Animation<double> _eloBadgeSlideAnimation;
  bool _showEloBadge = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBattleResult();
  }

  void _initAnimations() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 880),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic)),
    );

    // ELO counting animation
    _eloAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _eloCountAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _eloAnimController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _eloBadgeSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _eloAnimController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _eloAnimController.addListener(() {
      if (mounted) {
        setState(() {
          _displayedElo = _startElo +
              ((_newElo - _startElo) * _eloCountAnimation.value).round();
        });
      }
    });
  }

  Future<void> _loadBattleResult() async {
    // Check if this is a test battle
    final isTestBattle = widget.battleId.startsWith('test_');

    BattleRoom? battle;
    bool won;

    if (isTestBattle) {
      // For test battles, get from local storage
      battle = BattleService.getLocalTestBattle();
      // Use forcedResult if provided, otherwise determine from battle
      if (widget.forcedResult != null) {
        won = widget.forcedResult == 'win';
      } else {
        won = battle?.winnerId == battle?.player1?.oderId;
      }

      _eloChange = widget.eloChange ??
          LocalDuelStatsService.pendingEloChange ??
          (won ? 25 : 20);

      // Use pre-calculated ELO values if passed (avoids race condition with
      // recordWin/recordLoss running in a microtask after navigation).
      if (widget.newElo != null && widget.startElo != null) {
        _newElo = widget.newElo!;
        _startElo = widget.startElo!;
      } else {
        _newElo = LocalDuelStatsService.elo;
        _startElo = won ? (_newElo - _eloChange) : (_newElo + _eloChange);
      }
      _displayedElo = _startElo;
      _rankName = LocalDuelStatsService.getRankFromElo(_newElo);
    } else {
      // For real battles, fetch from Firestore
      battle = await BattleService.getBattle(widget.battleId);
      if (battle == null || !mounted) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final oderId = AuthService.userId;
      won = battle.winnerId == oderId;

      // ELO was already calculated & saved in BattleService._updatePlayerStats.
      // Use the actual recorded change from LocalDuelStatsService for consistency.
      _newElo = LocalDuelStatsService.elo;
      _rankName = LocalDuelStatsService.rank;

      final actualPendingChange = LocalDuelStatsService.pendingEloChange;
      if (actualPendingChange != null && actualPendingChange > 0) {
        _eloChange = actualPendingChange;
        _startElo = won ? (_newElo - _eloChange) : (_newElo + _eloChange);
        _displayedElo = _startElo;
      } else {
        // Fallback: recalculate from battle data
        final myPlayer = battle.getSelf(oderId ?? '');
        final opponent = battle.getOpponent(oderId ?? '');

        if (myPlayer != null && opponent != null) {
          _eloChange = EloCalculator.calculateEloChange(
            playerElo: myPlayer.elo,
            opponentElo: opponent.elo,
            won: won,
            gamesPlayed: LocalDuelStatsService.totalGames,
            multiplier: 2.0,
          ).abs();

          _startElo = won ? (_newElo - _eloChange) : (_newElo + _eloChange);
          _displayedElo = _startElo;
        } else {
          _startElo = _newElo;
          _eloChange = 0;
          _displayedElo = _newElo;
        }
      }
    }

    if (!mounted) return;

    // Grant XP on win (AI: by difficulty, live duel: Expert-level)
    int earnedXp = 0;
    if (won) {
      final difficultyForXp =
          isTestBattle ? (battle?.difficulty ?? 'Medium') : 'Expert';
      earnedXp = LevelService.previewXp(
        difficulty: difficultyForXp,
        completionTime: widget.completionTime,
        mistakes: widget.mistakes,
        isDailyChallenge: false,
        isRanked: true,
      );
      LevelService.addGameXp(
        difficulty: difficultyForXp,
        completionTime: widget.completionTime,
        mistakes: widget.mistakes,
        isDailyChallenge: false,
        isRanked: true,
      ); // fire-and-forget; XP already shown from preview
    }

    // Detect rank up for celebration (test: from pending; real: from ELO change)
    String? rankUpFrom;
    String? rankUpTo;
    if (won) {
      if (widget.rankUpFrom != null && widget.rankUpTo != null) {
        // Use pre-calculated rank-up info passed from game screen
        rankUpFrom = widget.rankUpFrom;
        rankUpTo = widget.rankUpTo;
      } else if (isTestBattle) {
        rankUpFrom = LocalDuelStatsService.pendingRankUpFrom;
        rankUpTo = LocalDuelStatsService.pendingRankUp;
      } else {
        final oldR = LocalDuelStatsService.getRankFromElo(_startElo);
        final newR = LocalDuelStatsService.getRankFromElo(_newElo);
        if (oldR != newR) {
          rankUpFrom = oldR;
          rankUpTo = newR;
        }
      }
    }

    setState(() {
      _battle = battle;
      _won = won;
      _isLoading = false;
      _earnedXp = earnedXp;
      if (rankUpFrom != null && rankUpTo != null) {
        _rankUpFrom = rankUpFrom;
        _rankUpTo = rankUpTo;
        _showRankUpCelebration = true;
      }
    });

    // Start animation immediately
    _animController.forward();

    // Start ELO counting animation after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showEloBadge = true);
        _eloAnimController.forward();
      }
    });

    // Play sound in background (non-blocking)
    if (_won) {
      Future.microtask(() => SoundService().playVictory());
      Future.microtask(() async {
        try {
          final achievementResult = await AchievementService.checkAfterDuelWin();
          if (achievementResult.totalXpBonus > 0) {
            await LevelService.addBonusXp(achievementResult.totalXpBonus);
          }
        } catch (e) {
          debugPrint('Duel achievement check failed (non-fatal): $e');
        }
      });
    } else {
      Future.microtask(() => SoundService().playGameLost());
    }
    HapticService.lightImpact();
  }

  @override
  void dispose() {
    _animController.dispose();
    _eloAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // For test battles use player2 directly, for real battles use getOpponent
    final isTestBattle = widget.battleId.startsWith('test_');
    final opponent = isTestBattle
        ? _battle?.player2
        : _battle?.getOpponent(AuthService.userId ?? '');

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _won
                    ? [const Color(0xFF1a472a), const Color(0xFF0d2818)]
                    : [const Color(0xFF4a1a1a), const Color(0xFF280d0d)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.03,
                      ),
                      child: Column(
                        children: [
                          // Result badge
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildResultBadge(theme),
                            ),
                          ),

                          SizedBox(height: 24.w),

                          // VS Display
                          _buildVsDisplay(theme, opponent),

                          SizedBox(height: 24.w),

                          // Stats
                          _buildStatsCard(theme),

                          SizedBox(height: 16.w),

                          // ELO change
                          _buildEloChange(theme),

                          SizedBox(height: 16.w),
                        ],
                      ),
                    ),
                  ),

                  // Buttons
                  _buildButtons(theme),

                  SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 8 : 16),
                ],
              ),
            ),
          ),
          // Rank-up celebration overlay (Bronze → Silver, etc.)
          if (_showRankUpCelebration &&
              _rankUpFrom != null &&
              _rankUpTo != null)
            RankUpCelebrationOverlay(
              fromRank: _rankUpFrom!,
              toRank: _rankUpTo!,
              onDismiss: () {
                LocalDuelStatsService.clearPendingEloChange();
                setState(() {
                  _showRankUpCelebration = false;
                  _rankUpFrom = null;
                  _rankUpTo = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultBadge(AppThemeColors theme) {
    final accent = _won ? Colors.green : Colors.red;
    final lottieAsset = _won
        ? 'assets/lottie/results/victory.json'
        : 'assets/lottie/results/defeat.json';

    return Column(
      children: [
        LottieLoader.lottieOrFallback(
          assetPath: lottieAsset,
          width: 100.w,
          height: 100.w,
          fallback: Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.22),
              border: Border.all(
                color: accent,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              _won ? Bootstrap.trophy_fill : Bootstrap.x_circle_fill,
              size: 50.w,
              color: _won ? Colors.amber : Colors.red.shade400,
            ),
          ),
        ),
        SizedBox(height: 16.w),
        Builder(
          builder: (ctx) {
            final l10n = AppLocalizations.of(ctx);
            return Text(
              _won ? l10n.victory : l10n.defeat,
              style: TextStyle(
                fontSize: 34.sp,
                fontWeight: FontWeight.bold,
                color: _won ? Colors.green.shade200 : Colors.red.shade200,
                letterSpacing: 5,
                shadows: [
                  Shadow(color: accent.withValues(alpha: 0.25), blurRadius: 4),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVsDisplay(AppThemeColors theme, BattlePlayer? opponent) {
    final avatarSize = ResponsiveUtils.isSmallScreen ? 48.0 : 56.w;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // You
          Flexible(
            child: Column(
              children: [
                UserAvatarWithFrame.currentUser(
                  size: avatarSize,
                  showCountryFlag: true,
                  showAnimation: _won,
                ),
                SizedBox(height: 6.w),
                Builder(
                  builder: (ctx) => Text(
                    AppLocalizations.of(ctx).you,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_won)
                  const Icon(Bootstrap.check_circle_fill,
                      color: Colors.green, size: 16),
              ],
            ),
          ),

          SizedBox(width: 20.w),

          // VS
          Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx).vs,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
          ),

          SizedBox(width: 20.w),

          // Opponent
          Flexible(
            child: Column(
              children: [
                UserAvatarWithFrame(
                  size: avatarSize,
                  displayName: opponent?.displayName ?? 'Opponent',
                  photoUrl: opponent?.photoUrl,
                  frameId: opponent?.equippedFrame,
                  countryCode: opponent?.countryCode,
                  avatarAsset: opponent?.avatarAsset,
                  showCountryFlag: true,
                  showAnimation: !_won,
                ),
                SizedBox(height: 6.w),
                Builder(
                  builder: (ctx) => Text(
                    opponent?.displayName ?? AppLocalizations.of(ctx).opponent,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_won)
                  const Icon(Bootstrap.check_circle_fill,
                      color: Colors.green, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _localizedDifficulty(BuildContext context) {
    final d = _battle?.difficulty ?? 'Medium';
    final l10n = AppLocalizations.of(context);
    switch (d) {
      case 'Easy':
        return l10n.easy;
      case 'Medium':
        return l10n.medium;
      case 'Hard':
        return l10n.hard;
      case 'Expert':
        return l10n.expert;
      default:
        return l10n.medium;
    }
  }

  String _localizedRank(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (_rankName) {
      case 'Bronze':
        return l10n.bronze;
      case 'Silver':
        return l10n.silver;
      case 'Gold':
        return l10n.gold;
      case 'Platinum':
        return l10n.platinum;
      case 'Diamond':
        return l10n.diamond;
      case 'Master':
        return l10n.master;
      case 'Grandmaster':
        return l10n.grandmaster;
      case 'Champion':
        return l10n.champion;
      default:
        return _rankName;
    }
  }

  Widget _buildStatsCard(AppThemeColors theme) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(l10n.time, _formatTime(widget.completionTime),
                  Bootstrap.stopwatch),
              _buildStatItem(
                  l10n.mistakes, '${widget.mistakes}', Bootstrap.x_circle),
              _buildStatItem(l10n.difficulty, _localizedDifficulty(context),
                  Bootstrap.bar_chart),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildEloChange(AppThemeColors theme) {
    // Use _won to determine if positive or negative, not the value itself
    final isPositive = _won;

    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.newRating,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$_displayedElo',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            ' ${l10n.elo}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DivisionBadge(rank: _rankName, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            _localizedRank(context),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Animated ELO change badge
                  AnimatedBuilder(
                    animation: _eloAnimController,
                    builder: (context, child) {
                      return AnimatedOpacity(
                        opacity: _showEloBadge ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Transform.translate(
                          offset: Offset(0, _eloBadgeSlideAnimation.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isPositive ? Colors.green : Colors.red)
                                          .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPositive
                                      ? Bootstrap.arrow_up
                                      : Bootstrap.arrow_down,
                                  color: isPositive
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isPositive ? '+' : '-'}$_eloChange',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isPositive
                                        ? Colors.green.shade300
                                        : Colors.red.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (_won && _earnedXp > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Bootstrap.star_fill,
                        color: Colors.amber.shade300, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '+$_earnedXp ${l10n.xp}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade300,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _goToDuelLobby() {
    // Navigate to home screen with Duel tab selected
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialTab: 1), // Duel tab
      ),
      (route) => false,
    );
  }

  Widget _buildButtons(AppThemeColors theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _goToDuelLobby,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx).continueGame,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
