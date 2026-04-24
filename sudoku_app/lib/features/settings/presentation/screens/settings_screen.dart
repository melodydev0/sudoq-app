import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/models/statistics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';
import '../../../onboarding/presentation/screens/welcome_screen.dart';
import 'animations_debug_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isRestoring = false;
  bool _pushNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    PurchaseService.onPurchaseResult = _handlePurchaseResult;
    _pushNotificationsEnabled = NotificationService.isEnabled;
  }

  @override
  void dispose() {
    if (PurchaseService.onPurchaseResult == _handlePurchaseResult) {
      PurchaseService.onPurchaseResult = null;
    }
    super.dispose();
  }

  void _handlePurchaseResult(PurchaseResult result, String? message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isRestoring = false;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    switch (result) {
      case PurchaseResult.success:
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message ?? l10n.premiumActivated),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(adsFreeProvider.notifier).state = true;
        break;
      case PurchaseResult.restored:
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message ?? l10n.purchaseRestored),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(adsFreeProvider.notifier).state = true;
        break;
      case PurchaseResult.alreadyOwned:
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(message ?? l10n.alreadyPurchased)),
        );
        ref.read(adsFreeProvider.notifier).state = true;
        break;
      case PurchaseResult.error:
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message ?? l10n.purchaseFailed),
            backgroundColor: AppColors.error,
          ),
        );
        break;
      case PurchaseResult.cancelled:
        // Don't show message for cancellation
        break;
      case PurchaseResult.pending:
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(message ?? 'Processing...')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final isAdsFree = ref.watch(adsFreeProvider);
    // Rebuild when theme changes so selected theme applies immediately on this page
    return ValueListenableBuilder<AppThemeType>(
      valueListenable: AppThemeManager.themeNotifier,
      builder: (context, themeType, _) {
        final theme = AppThemeManager.colors;
        return Scaffold(
          backgroundColor: theme.background,
          body: Container(
            color: theme.background,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: theme.textPrimary,
                        ),
                        Text(
                          l10n.settings,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Game Settings Section
                        _buildSectionTitle(l10n.game, theme),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            title: l10n.autoRemoveNotes,
                            subtitle: l10n.autoRemoveNotesSubtitle,
                            value: settings.autoRemoveNotes,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(autoRemoveNotes: value),
                                  );
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            title: l10n.highlightSameNumbers,
                            subtitle: l10n.highlightSameNumbersSubtitle,
                            value: settings.highlightSameNumbers,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(
                                        highlightSameNumbers: value),
                                  );
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            title: l10n.showMistakes,
                            subtitle: l10n.showMistakesSubtitle,
                            value: settings.showMistakes,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(showMistakes: value),
                                  );
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            title: l10n.showTimer,
                            subtitle: l10n.showTimerSubtitle,
                            value: settings.showTimer,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(showTimer: value),
                                  );
                            },
                            theme: theme,
                          ),
                        ], theme),

                        const SizedBox(height: 24),

                        // Appearance Section
                        _buildSectionTitle(l10n.appearance, theme),
                        _buildSettingsCard([
                          _buildLanguageTile(
                              settings.languageCode, theme, l10n),
                          _buildDivider(),
                          _buildAppThemeTile(theme, l10n),
                        ], theme),

                        const SizedBox(height: 24),

                        // Sound & Haptics Section
                        _buildSectionTitle(l10n.soundHaptics, theme),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            title: l10n.soundEffects,
                            subtitle: l10n.soundEffectsSubtitle,
                            value: settings.soundEnabled,
                            onChanged: (value) {
                              ref.read(settingsProvider.notifier).toggleSound();
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            title: l10n.vibration,
                            subtitle: l10n.vibrationSubtitle,
                            value: settings.vibrationEnabled,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleVibration();
                            },
                            theme: theme,
                          ),
                        ], theme),

                        const SizedBox(height: 24),

                        // Notifications Section
                        _buildSectionTitle(l10n.notifications, theme),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            title: l10n.pushNotifications,
                            subtitle: l10n.pushNotificationsSubtitle,
                            value: _pushNotificationsEnabled,
                            onChanged: (value) async {
                              await NotificationService.setEnabled(value);
                              setState(() {
                                _pushNotificationsEnabled = value;
                              });
                            },
                            theme: theme,
                          ),
                        ], theme),

                        const SizedBox(height: 24),

                        // Premium Section
                        if (!isAdsFree) ...[
                          _buildSectionTitle(l10n.premium, theme),
                          _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.workspace_premium,
                              title: l10n.goPremium,
                              subtitle: l10n.goPremiumSubtitle,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.buttonPrimary,
                                  borderRadius: AppTheme.buttonRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.textPrimary
                                          .withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  l10n.viewAll.toUpperCase(),
                                  style: TextStyle(
                                    color: theme.buttonText,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SubscriptionScreen()),
                                );
                              },
                              theme: theme,
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.restore,
                              title: l10n.restorePurchase,
                              subtitle: l10n.restorePurchaseSubtitle,
                              trailing: _isRestoring
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.chevron_right,
                                      color: theme.textSecondary,
                                    ),
                              onTap: _isRestoring ? null : _restorePurchases,
                              theme: theme,
                            ),
                          ], theme),
                          const SizedBox(height: 24),
                        ] else ...[
                          _buildSectionTitle(l10n.premium, theme),
                          _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.check_circle,
                              title: l10n.adsFree,
                              subtitle: l10n.adsFreeThankYou,
                              trailing: Icon(
                                Icons.check,
                                color: theme.success,
                              ),
                              theme: theme,
                            ),
                          ], theme),
                          const SizedBox(height: 24),
                        ],

                        // About Section
                        _buildSectionTitle(l10n.about, theme),
                        _buildSettingsCard([
                          _buildActionTile(
                            icon: Icons.star_outline,
                            title: l10n.rateUs,
                            subtitle: l10n.rateUsSubtitle,
                            onTap: () async {
                              final url = Uri.parse(
                                'https://play.google.com/store/apps/details?id=com.sudoq.app',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            icon: Icons.share,
                            title: l10n.shareApp,
                            subtitle: l10n.shareAppSubtitle,
                            onTap: () {
                              SharePlus.instance.share(
                                ShareParams(
                                  text: '${AppConstants.appName} - Zen Sudoku Puzzle\nhttps://play.google.com/store/apps/details?id=com.sudoq.app',
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            icon: Icons.privacy_tip_outlined,
                            title: l10n.privacyPolicy,
                            onTap: () async {
                              final url = Uri.parse(AppConstants.privacyPolicyUrl);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            icon: Icons.description_outlined,
                            title: l10n.termsOfService,
                            onTap: () async {
                              final url = Uri.parse(AppConstants.termsOfServiceUrl);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            theme: theme,
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            icon: Icons.mail_outline,
                            title: l10n.contactUs,
                            subtitle: 'support@sudoq.app',
                            onTap: () async {
                              final url = Uri.parse('mailto:support@sudoq.app?subject=SudoQ%20Support');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            theme: theme,
                          ),
                        ], theme),

                        // Account Section (only for signed-in non-anonymous users)
                        if (AuthService.isSignedIn && !AuthService.isAnonymous) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle(l10n.account, theme),
                          _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.logout,
                              title: l10n.signOut,
                              onTap: () => _showSignOutDialog(theme, l10n),
                              theme: theme,
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.delete_forever,
                              title: l10n.deleteAccount,
                              subtitle: l10n.deleteAccountWarning,
                              onTap: () => _showDeleteAccountDialog(theme, l10n),
                              theme: theme,
                            ),
                          ], theme),
                        ],

                        if (kDebugMode) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('🔧 Debug Mode', theme),
                          _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.animation,
                              title: 'Test Animations + All Buttons',
                              subtitle:
                                  'All animations + all app button styles',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AnimationsDebugScreen(),
                                  ),
                                );
                              },
                              theme: theme,
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              title: 'Premium / Ads-Free',
                              subtitle: isAdsFree
                                  ? '✅ Premium Active (No Ads)'
                                  : '❌ Free Version (Ads Enabled)',
                              value: isAdsFree,
                              onChanged: (value) async {
                                final messenger = ScaffoldMessenger.of(context);
                                await StorageService.setAdsFree(value);
                                ref.read(adsFreeProvider.notifier).state = value;

                                if (value) {
                                  AdsService.onAdsFreeActivated();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          '✅ Premium Activated! (Debug Mode)'),
                                      backgroundColor: theme.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  AdsService.init();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          '❌ Premium Deactivated (Debug Mode)'),
                                      backgroundColor: theme.warning,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                              theme: theme,
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.military_tech,
                              title: 'Max Level (100) + All Rewards',
                              subtitle: 'Unlock everything for testing',
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await LevelService.setMaxLevel();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        '✅ Level 100 + All Rewards Unlocked!'),
                                    backgroundColor: theme.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              theme: theme,
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.emoji_events,
                              title: 'Unlock All Achievements',
                              subtitle:
                                  'All achievements + Stats + Duel (60 total)',
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);

                                // 1. Update AchievementService data (unlocked IDs)
                                await AchievementService.unlockAll();

                                // 2. Update Statistics for normal achievements progress
                                final maxStats = Statistics(
                                  totalGamesPlayed: 500,
                                  totalGamesWon: 450,
                                  totalGamesLost: 50,
                                  currentStreak: 30,
                                  bestStreak: 30,
                                  totalPlayTime: 360000, // 100 hours
                                  difficultyStats: {
                                    'Easy': DifficultyStats(
                                        gamesPlayed: 150,
                                        gamesWon: 140,
                                        bestTime: 60,
                                        bestScore: 10000),
                                    'Medium': DifficultyStats(
                                        gamesPlayed: 150,
                                        gamesWon: 130,
                                        bestTime: 180,
                                        bestScore: 12000),
                                    'Hard': DifficultyStats(
                                        gamesPlayed: 100,
                                        gamesWon: 90,
                                        bestTime: 300,
                                        bestScore: 15000),
                                    'Expert': DifficultyStats(
                                        gamesPlayed: 100,
                                        gamesWon: 90,
                                        bestTime: 600,
                                        bestScore: 20000),
                                  },
                                  totalHintsUsed: 1000,
                                  perfectGames: 130,
                                  uniqueDaysPlayed: List.generate(
                                      365,
                                      (i) =>
                                          '2025-01-${(i % 28 + 1).toString().padLeft(2, '0')}'),
                                  totalDailyChallengesCompleted: 100,
                                );
                                await ref
                                    .read(statisticsProvider.notifier)
                                    .updateStatistics(maxStats);

                                // 3. Update Duel stats for duel achievements
                                await LocalDuelStatsService.setDebugStats(
                                  wins: 500,
                                  losses: 50,
                                  elo: 2500, // Champion level
                                  bestStreak: 15,
                                  currentStreak: 10,
                                );
                                // Sync to cloud so duel leaderboard reflects debug rank
                                await AuthService.syncDuelLeaderboard(2500);

                                // 4. Refresh achievements provider with actual data
                                ref
                                    .read(achievementsDataProvider.notifier)
                                    .refresh();

                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        '✅ All Achievements Unlocked! (Stats + Duel + Rewards)'),
                                    backgroundColor: theme.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                setState(() {});
                              },
                              theme: theme,
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.restart_alt,
                              title: 'Reset Everything',
                              subtitle: 'Reset level, achievements, stats',
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await StorageService.clearAll();
                                await LevelService.resetLevelData();
                                await AchievementService.reset();
                                await LocalDuelStatsService.resetAll();
                                ref.read(statisticsProvider.notifier).reset();
                                ref
                                    .read(achievementsDataProvider.notifier)
                                    .reset();
                                await StorageService.setAdsFree(false);
                                ref.read(adsFreeProvider.notifier).state = false;
                                AdsService.init();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        '🔄 Everything Reset! Restart app for best results.'),
                                    backgroundColor: theme.warning,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                setState(() {});
                              },
                              theme: theme,
                            ),
                          ], theme),
                          const SizedBox(height: 24),
                        ],

                        // Version
                        Center(
                          child: Text(
                            l10n.version(AppConstants.appVersion),
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12.sp,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppThemeTile(AppThemeColors theme, AppLocalizations l10n) {
    final currentTheme = AppThemeManager.currentTheme;
    final duelRank = LocalDuelStatsService.rank;
    final championUnlocked = _isChampionUnlocked(duelRank);
    final grandmasterUnlocked = _isGrandmasterUnlocked(duelRank);

    String themeName;
    IconData themeIcon;
    Color themeColor;

    switch (currentTheme) {
      case AppThemeType.light:
      case AppThemeType.system:
        themeName = l10n.lightMode;
        themeIcon = Icons.light_mode;
        themeColor = theme.accent;
        break;
      case AppThemeType.dark:
        themeName = l10n.darkMode;
        themeIcon = Icons.dark_mode;
        themeColor = theme.accent;
        break;
      case AppThemeType.champion:
        themeName = l10n.rewardName('themeChampion');
        themeIcon = Icons.emoji_events;
        themeColor = theme.buttonPrimary;
        break;
      case AppThemeType.grandmaster:
        themeName = l10n.rewardName('themeGrandmaster');
        themeIcon = Icons.workspace_premium;
        themeColor = theme.buttonPrimary;
        break;
    }

    return ListTile(
      leading: Icon(themeIcon, color: themeColor, size: 24),
      title: Text(
        l10n.appTheme,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      subtitle: Text(
        themeName,
        style: TextStyle(
          fontSize: 13.sp,
          color: themeColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.textSecondary),
      onTap: () => _showThemeSelector(
          theme, l10n, championUnlocked, grandmasterUnlocked),
    );
  }

  bool _isChampionUnlocked(String duelRank) {
    // Master or higher ranks unlock Champion theme
    return ['Master', 'Grandmaster', 'Champion'].contains(duelRank);
  }

  bool _isGrandmasterUnlocked(String duelRank) {
    // Only Champion rank unlocks Grandmaster theme
    return duelRank == 'Champion';
  }

  void _showThemeSelector(AppThemeColors theme, AppLocalizations l10n,
      bool championUnlocked, bool grandmasterUnlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.selectTheme,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              icon: Icons.light_mode,
              title: l10n.lightMode,
              subtitle: l10n.lightModeDesc,
              color: theme.accent,
              isSelected: AppThemeManager.currentTheme == AppThemeType.light,
              onTap: () => _selectTheme(AppThemeType.light),
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: l10n.darkMode,
              subtitle: l10n.darkModeDesc,
              color: theme.accent,
              isSelected: AppThemeManager.currentTheme == AppThemeType.dark,
              onTap: () => _selectTheme(AppThemeType.dark),
              theme: theme,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: theme.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '✨ ${l10n.premiumThemes}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.divider)),
              ],
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              icon: Icons.emoji_events,
              title: l10n.rewardName('themeChampion'),
              subtitle: championUnlocked
                  ? l10n.rewardDesc('themeChampionDesc')
                  : l10n.requiresMasterDivision,
              color: AppColors.accentGold,
              isSelected: AppThemeManager.currentTheme == AppThemeType.champion,
              isLocked: !championUnlocked,
              onTap: championUnlocked
                  ? () => _selectTheme(AppThemeType.champion)
                  : null,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              icon: Icons.workspace_premium,
              title: l10n.rewardName('themeGrandmaster'),
              subtitle: grandmasterUnlocked
                  ? l10n.rewardDesc('themeGrandmasterDesc')
                  : l10n.requiresChampionDivision,
              color: AppColors.accentPurple,
              isSelected:
                  AppThemeManager.currentTheme == AppThemeType.grandmaster,
              isLocked: !grandmasterUnlocked,
              onTap: grandmasterUnlocked
                  ? () => _selectTheme(AppThemeType.grandmaster)
                  : null,
              theme: theme,
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required AppThemeColors theme,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : theme.accentLight,
          borderRadius: AppTheme.buttonRadius,
          border: Border.all(
            color: isSelected ? color : theme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? theme.textSecondary
                              : theme.textPrimary,
                          letterSpacing: 0.25,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock, size: 14, color: theme.textSecondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isLocked ? theme.textMuted : theme.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  void _selectTheme(AppThemeType theme) async {
    await AppThemeManager.setTheme(theme);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
    }
  }

  Widget _buildSectionTitle(String title, AppThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, AppThemeColors theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required AppThemeColors theme,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.textSecondary,
                letterSpacing: 0.15,
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: theme.buttonPrimary,
      ),
    );
  }

  Widget _buildActionTile({
    IconData? icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required AppThemeColors theme,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: theme.iconSecondary, size: 24)
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.textSecondary,
                letterSpacing: 0.15,
              ),
            )
          : null,
      trailing:
          trailing ?? Icon(Icons.chevron_right, color: theme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLanguageTile(
      String currentLangCode, AppThemeColors theme, AppLocalizations l10n) {
    final currentLang = availableLanguages.firstWhere(
      (lang) => lang.code == currentLangCode,
      orElse: () => const LanguageInfo(
        code: '',
        name: 'System',
        nativeName: 'System',
        flag: '🌐',
      ),
    );

    return ListTile(
      leading: Text(currentLang.flag, style: TextStyle(fontSize: 24.sp)),
      title: Text(
        l10n.language,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      subtitle: Text(
        currentLangCode.isEmpty ? l10n.selectLanguage : currentLang.nativeName,
        style: TextStyle(
          fontSize: 13.sp,
          color: theme.textSecondary,
          letterSpacing: 0.15,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.textSecondary),
      onTap: () => _showLanguageSelector(theme),
    );
  }

  void _showLanguageSelector(AppThemeColors theme) {
    final settings = ref.read(settingsProvider);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.selectLanguage,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Divider(height: 1, color: theme.divider),
            Expanded(
              child: ListView(
                children: [
                  _buildLanguageOption(
                    flag: '🌐',
                    name: l10n.systemDefault,
                    nativeName: '',
                    code: '',
                    isSelected: settings.languageCode.isEmpty,
                    theme: theme,
                  ),
                  Divider(height: 1, indent: 60, color: theme.divider),
                  ...availableLanguages.map((lang) => Column(
                        children: [
                          _buildLanguageOption(
                            flag: lang.flag,
                            name: lang.name,
                            nativeName: lang.nativeName,
                            code: lang.code,
                            isSelected: settings.languageCode == lang.code,
                            theme: theme,
                          ),
                          Divider(height: 1, indent: 60, color: theme.divider),
                        ],
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String name,
    required String nativeName,
    required String code,
    required bool isSelected,
    required AppThemeColors theme,
  }) {
    return ListTile(
      leading: Text(flag, style: TextStyle(fontSize: 28.sp)),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      subtitle: nativeName.isNotEmpty
          ? Text(
              nativeName,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.textSecondary,
                letterSpacing: 0.15,
              ),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.buttonPrimary)
          : null,
      onTap: () {
        ref.read(settingsProvider.notifier).updateSettings(
              ref.read(settingsProvider).copyWith(languageCode: code),
            );
        Navigator.pop(context);
      },
    );
  }

  void _showSignOutDialog(AppThemeColors theme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.card,
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text(
          l10n.signOut,
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          l10n.signOutConfirm,
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel, style: TextStyle(color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(dialogCtx);
              await AuthService.signOut();
              if (!mounted) return;
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Text(l10n.signOut, style: TextStyle(color: theme.warning)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AppThemeColors theme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.card,
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text(
          l10n.deleteAccountConfirm,
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          l10n.deleteAccountWarning,
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel, style: TextStyle(color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showDeleteAccountFinalDialog(theme, l10n);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountFinalDialog(AppThemeColors theme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.card,
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.deleteAccountFinalConfirm,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteAccountFinalWarning,
          style: TextStyle(color: theme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel, style: TextStyle(color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              final success = await AuthService.deleteAccount();
              if (!mounted) return;
              if (success) {
                await LevelService.resetLevelData();
                await StorageService.clearAll();
                await StorageService.init();
                if (!mounted) return;
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${l10n.errorPrefix}: ${l10n.deleteAccount}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    final success = await PurchaseService.restorePurchases();

    if (!mounted) return;

    setState(() => _isRestoring = false);

    if (success) {
      ref.read(adsFreeProvider.notifier).state = StorageService.isAdsFree();
    }
  }
}
