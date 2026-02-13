import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/battle_service.dart';
import '../../../../core/models/battle_models.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'battle_game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearching = true;
  String _statusText = 'Searching for opponent...';
  int _searchSeconds = 0;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startMatchmaking();
    _startTimer();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isSearching) {
        setState(() {
          _searchSeconds++;
          _updateStatusText();
        });
      }
    });
  }

  void _updateStatusText() {
    if (_searchSeconds < 5) {
      _statusText = 'Searching for opponent...';
    } else if (_searchSeconds < 15) {
      _statusText = 'Expanding search range...';
    } else if (_searchSeconds < 25) {
      _statusText = 'Looking for available players...';
    } else {
      _statusText = 'Still searching...';
    }
  }

  void _startMatchmaking() async {
    await BattleService.joinMatchmaking(
      onMatchFound: (battle) {
        if (mounted) {
          setState(() => _isSearching = false);
          _navigateToBattle(battle);
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      },
    );
  }

  void _navigateToBattle(BattleRoom battle) {
    HapticFeedback.heavyImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BattleGameScreen(battleId: battle.id),
      ),
    );
  }

  void _cancelMatchmaking() async {
    await BattleService.leaveMatchmaking();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    if (_isSearching) {
      BattleService.leaveMatchmaking();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancelMatchmaking();
        }
      },
      child: Scaffold(
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _cancelMatchmaking,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: theme.textSecondary),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Finding Opponent',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const Spacer(),

                // Searching animation
                _buildSearchingAnimation(theme),

                const SizedBox(height: 40),

                // Status text
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.textSecondary,
                  ),
                ),

                const SizedBox(height: 12),

                // Timer
                Text(
                  _formatTime(_searchSeconds),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),

                const Spacer(),

                // Player info
                _buildPlayerInfo(theme),

                const SizedBox(height: 24),

                // Cancel button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelMatchmaking,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingAnimation(AppThemeColors theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                  const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.card,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Bootstrap.search,
                    size: 40,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerInfo(AppThemeColors theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Your avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: ClipOval(
              child: AuthService.photoUrl != null
                  ? Image.network(AuthService.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: theme.accent.withValues(alpha: 0.2),
                      child: Icon(Icons.person, color: theme.accent),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Your info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AuthService.displayName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Opponent placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '???',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textSecondary,
                  ),
                ),
                Text(
                  'Searching...',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Opponent avatar placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.textSecondary.withValues(alpha: 0.2),
              border: Border.all(
                  color: theme.textSecondary.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(
              Icons.person,
              color: theme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
