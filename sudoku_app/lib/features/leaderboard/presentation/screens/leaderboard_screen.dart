import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/models/leaderboard_user.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_sync_service.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../widgets/leaderboard_tile.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final int initialTab;

  const LeaderboardScreen({super.key, this.initialTab = 0});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late TabController _tabController;
  List<LeaderboardUser> _levelLeaderboard = [];
  List<LeaderboardUser> _rankedLeaderboard = [];
  LeaderboardUser? _currentUser;
  bool _isLoading = true;
  bool _routeObserverSubscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route != null) {
        appRouteObserver.subscribe(this, route);
        _routeObserverSubscribed = true;
      }
    }
  }

  @override
  void didPopNext() {
    // Returned to this screen (e.g. from battle result) – refresh so anonymous user's rank updates
    if (mounted) _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      _loadData();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
      _routeObserverSubscribed = false;
    }
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get real user data
    final levelData = LevelService.levelData;
    final duelStats = LocalDuelStatsService.getAllStats();
    final duelWins = duelStats['wins'] as int? ?? 0;
    final duelLosses = duelStats['losses'] as int? ?? 0;
    final duelElo = duelStats['elo'] as int? ?? 1000;
    final duelRank = duelStats['rank'] as String? ?? 'Bronze';

    // Create current user from real data
    _currentUser = LeaderboardUser(
      id: 'current_user',
      username: AuthService.displayName,
      countryCode: 'TR', // [Future] Get from user settings
      level: levelData.level,
      totalXp: levelData.totalXp,
      rank: 1, // Will be calculated from leaderboard
      gamesWon: duelWins,
      perfectGames: 0, // [Future] Track perfect games
      winRate: (duelWins + duelLosses) > 0
          ? (duelWins / (duelWins + duelLosses) * 100)
          : 0.0,
      rankedPoints: duelElo,
      division: duelRank,
      unlockedAchievementIds: [],
      equippedBadgeIds: [],
      equippedFrame: LevelService.selectedFrameId,
      joinedAt: DateTime.now().subtract(const Duration(days: 7)),
      isOnline: true,
    );

    // Fetch duel leaderboard from Firestore
    await _loadDuelLeaderboard();

    // Level leaderboard - use mock data with current user injected
    _levelLeaderboard = _generateLevelLeaderboardWithUser();

    setState(() {
      _isLoading = false;
    });
  }

  /// Load Duel Leaderboard from Firestore
  Future<void> _loadDuelLeaderboard() async {
    try {
      // Try to fetch from Firestore
      final cloudData = await UserSyncService.getTopPlayers(
        orderBy: 'duelElo',
        limit: 100,
      );

      if (cloudData.isNotEmpty) {
        _rankedLeaderboard = cloudData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return LeaderboardUser(
            id: data['uid'] ?? 'user_$index',
            username: data['displayName'] ?? 'Player',
            countryCode: data['countryCode'] ?? 'UN',
            level: data['level'] ?? 1,
            totalXp: data['totalXp'] ?? 0,
            rank: index + 1,
            gamesWon: data['duelWins'] ?? 0,
            perfectGames: 0,
            winRate: 0.0,
            rankedPoints: data['duelElo'] ?? 450,
            division: data['duelRank'] ?? 'Bronze',
            unlockedAchievementIds: [],
            equippedBadgeIds: [],
            equippedFrame: _getFrameForRP(data['duelElo'] ?? 450),
            joinedAt: DateTime.now(),
            isOnline: false,
          );
        }).toList();

        // Add current user if not in list
        final currentUserId = UserSyncService.currentUserId;
        final hasCurrentUser =
            _rankedLeaderboard.any((u) => u.id == currentUserId);
        if (!hasCurrentUser && _currentUser != null) {
          // Find correct position for current user
          int position = _rankedLeaderboard.length + 1;
          for (int i = 0; i < _rankedLeaderboard.length; i++) {
            if (_currentUser!.rankedPoints >
                _rankedLeaderboard[i].rankedPoints) {
              position = i + 1;
              break;
            }
          }
          _currentUser = LeaderboardUser(
            id: _currentUser!.id,
            username: _currentUser!.username,
            countryCode: _currentUser!.countryCode,
            level: _currentUser!.level,
            totalXp: _currentUser!.totalXp,
            rank: position,
            gamesWon: _currentUser!.gamesWon,
            perfectGames: _currentUser!.perfectGames,
            winRate: _currentUser!.winRate,
            rankedPoints: _currentUser!.rankedPoints,
            division: _currentUser!.division,
            unlockedAchievementIds: _currentUser!.unlockedAchievementIds,
            equippedBadgeIds: _currentUser!.equippedBadgeIds,
            equippedFrame: _currentUser!.equippedFrame,
            joinedAt: _currentUser!.joinedAt,
            isOnline: _currentUser!.isOnline,
          );
        }
      } else {
        // Fallback to local data only
        _rankedLeaderboard = [_currentUser!];
      }
    } catch (e) {
      debugPrint('Error loading duel leaderboard: $e');
      // Fallback to local data
      _rankedLeaderboard = [_currentUser!];
    }
  }

  /// Get frame based on ELO
  String? _getFrameForRP(int elo) {
    if (elo >= 2300) return 'ranked_frame_champion';
    if (elo >= 2000) return 'ranked_frame_grandmaster';
    if (elo >= 1700) return 'ranked_frame_master';
    if (elo >= 1400) return 'ranked_frame_diamond';
    if (elo >= 1100) return 'ranked_frame_platinum';
    return null;
  }

  /// Generate level leaderboard with current user
  List<LeaderboardUser> _generateLevelLeaderboardWithUser() {
    final mockUsers = MockLeaderboardData.getLevelLeaderboard();
    final levelData = LevelService.levelData;
    final duelStats = LocalDuelStatsService.getAllStats();
    final duelWins = duelStats['wins'] as int? ?? 0;
    final duelLosses = duelStats['losses'] as int? ?? 0;
    final duelElo = duelStats['elo'] as int? ?? 1000;
    final duelRank = duelStats['rank'] as String? ?? 'Bronze';

    // Create current user entry for level leaderboard
    final currentUserLevel = LeaderboardUser(
      id: 'current_user',
      username: AuthService.displayName,
      countryCode: 'TR',
      level: levelData.level,
      totalXp: levelData.totalXp,
      rank: 0,
      gamesWon: duelWins,
      perfectGames: 0,
      winRate: (duelWins + duelLosses) > 0
          ? (duelWins / (duelWins + duelLosses) * 100)
          : 0.0,
      rankedPoints: duelElo,
      division: duelRank,
      unlockedAchievementIds: [],
      equippedBadgeIds: [],
      equippedFrame: LevelService.selectedFrameId,
      joinedAt: DateTime.now().subtract(const Duration(days: 7)),
      isOnline: true,
    );

    // Insert user into sorted list
    final allUsers = [...mockUsers];
    allUsers.add(currentUserLevel);

    // Sort by level (descending), then by XP
    allUsers.sort((a, b) {
      final levelCompare = b.level.compareTo(a.level);
      if (levelCompare != 0) return levelCompare;
      return b.totalXp.compareTo(a.totalXp);
    });

    // Update ranks
    final result = <LeaderboardUser>[];
    for (int i = 0; i < allUsers.length; i++) {
      result.add(LeaderboardUser(
        id: allUsers[i].id,
        username: allUsers[i].username,
        avatarUrl: allUsers[i].avatarUrl,
        countryCode: allUsers[i].countryCode,
        level: allUsers[i].level,
        totalXp: allUsers[i].totalXp,
        rank: i + 1,
        gamesWon: allUsers[i].gamesWon,
        perfectGames: allUsers[i].perfectGames,
        winRate: allUsers[i].winRate,
        rankedPoints: allUsers[i].rankedPoints,
        division: allUsers[i].division,
        unlockedAchievementIds: allUsers[i].unlockedAchievementIds,
        equippedBadgeIds: allUsers[i].equippedBadgeIds,
        equippedFrame: allUsers[i].equippedFrame,
        joinedAt: allUsers[i].joinedAt,
        isOnline: allUsers[i].isOnline,
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;

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
          child: Column(
            children: [
              _buildHeader(l10n, theme),
              _buildTabBar(l10n, theme),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: theme.accent))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLeaderboardList(_levelLeaderboard, 'level'),
                          _buildLeaderboardList(_rankedLeaderboard, 'ranked'),
                        ],
                      ),
              ),
              if (_currentUser != null) _buildCurrentUserCard(theme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppThemeColors theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 10.w : 8.w),
              decoration: BoxDecoration(
                color: theme.accentLight,
                borderRadius: AppTheme.buttonRadius,
                border: Border.all(color: theme.divider, width: 1),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: _getResponsiveFontSize(18),
                color: theme.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              l10n.leaderboard,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(22),
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isLoading = true);
              _loadData();
            },
            icon: Icon(
              Bootstrap.arrow_clockwise,
              size: _getResponsiveFontSize(24),
              color: theme.iconSecondary,
            ),
          ),
        ],
      ),
    );
  }

  double _getResponsiveFontSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375).clamp(0.85, 1.25);
    return baseSize * scaleFactor;
  }

  Widget _buildTabBar(AppLocalizations l10n, AppThemeColors theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: theme.accentLight,
        borderRadius: AppTheme.buttonRadius,
        border: Border.all(color: theme.divider, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.buttonPrimary,
          borderRadius: BorderRadius.circular(10.w),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: theme.buttonText,
        unselectedLabelColor: theme.textSecondary,
        labelStyle: TextStyle(
          fontSize: _getResponsiveFontSize(13),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: _getResponsiveFontSize(13),
          letterSpacing: 0.2,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: _getResponsiveFontSize(18)),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    l10n.level,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: _getResponsiveFontSize(18)),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    l10n.duel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardUser> users, String type) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(horizontalPadding),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isCurrentUserItem = user.id == 'current_user';
          return LeaderboardTile(
            user: user,
            type: type,
            isCurrentUser: isCurrentUserItem,
            onTap: () => _openUserProfile(user),
          );
        },
      ),
    );
  }

  Widget _buildCurrentUserCard(AppThemeColors theme, AppLocalizations l10n) {
    if (_currentUser == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final rankBadgeSize = isTablet ? 44.0 : 40.0;
    final avatarSize = isTablet ? 48.0 : 44.0;

    // Get correct rank based on current tab
    final currentTabIndex = _tabController.index;
    int displayRank = _currentUser!.rank;

    if (currentTabIndex == 0) {
      // Level tab - find user's rank in level leaderboard
      final levelUser = _levelLeaderboard.firstWhere(
        (u) => u.id == 'current_user',
        orElse: () => _currentUser!,
      );
      displayRank = levelUser.rank;
    } else {
      // Ranked tab - find user's rank in ranked leaderboard
      final rankedUser = _rankedLeaderboard.firstWhere(
        (u) => u.id == 'current_user',
        orElse: () => _currentUser!,
      );
      displayRank = rankedUser.rank;
    }

    return Container(
      margin: EdgeInsets.all(horizontalPadding),
      padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
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
      child: GestureDetector(
        onTap: () => _openUserProfile(_currentUser!),
        child: Row(
          children: [
            Container(
              width: rankBadgeSize,
              height: rankBadgeSize,
              decoration: BoxDecoration(
                color: theme.buttonText.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      '#$displayRank',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: theme.buttonText,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 14.w : 12.w),
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: theme.card,
                shape: BoxShape.circle,
                border: Border.all(
                    color: theme.buttonText.withValues(alpha: 0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  _currentUser!.countryFlag,
                  style: TextStyle(fontSize: _getResponsiveFontSize(22)),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 14.w : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.yourPosition,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(14),
                            fontWeight: FontWeight.w600,
                            color: theme.buttonText,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_currentUser!.isOnline) ...[
                        SizedBox(width: 6.w),
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: theme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    currentTabIndex == 0
                        ? '${l10n.level} ${_currentUser!.level} • ${_formatNumber(_currentUser!.totalXp)} XP'
                        : '${_currentUser!.division ?? 'Bronze'} • ${_formatNumber(_currentUser!.rankedPoints)} RP',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(12),
                      color: theme.buttonText.withValues(alpha: 0.9),
                      letterSpacing: 0.15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.buttonText,
              size: _getResponsiveFontSize(24),
            ),
          ],
        ),
      ),
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

  void _openUserProfile(LeaderboardUser user) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }
}
