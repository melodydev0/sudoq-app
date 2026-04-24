import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/widgets/animated_frame.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../level/presentation/screens/rewards_screen.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../../battle/presentation/screens/duel_rewards_screen.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../widgets/profile_stats_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _memberSince;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize frame provider with current value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedFrameProvider.notifier).state =
          LevelService.selectedFrameId;
      _loadMemberSince();
    });
  }

  Future<void> _loadMemberSince() async {
    final createdAt = await AuthService.getCreatedAt();
    if (mounted && createdAt != null) {
      setState(() => _memberSince = createdAt);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final statistics = ref.watch(statisticsProvider);

    // Use AppThemeManager for premium themes
    final theme = AppThemeManager.colors;

    return Container(
      color: theme.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding()),
              child: Row(
                children: [
                  Text(
                    l10n.personal,
                    style: AppTextStyles.headline2(context,
                        color: theme.textPrimary),
                  ),
                  const Spacer(),
                  // Leaderboard button
                  IconButton(
                    onPressed: () => _openLeaderboard(),
                    icon: Icon(Bootstrap.trophy, size: 22.w),
                    color: theme.iconSecondary,
                  ),
                  IconButton(
                    onPressed: () => _openSettings(),
                    icon: Icon(Bootstrap.gear, size: 22.w),
                    color: theme.iconSecondary,
                  ),
                ],
              ),
            ),

            // Level & XP Card (includes user info)
            _buildLevelCard(theme, l10n),

            SizedBox(height: 16.w),

            // Stats summary
            ProfileStatsCard(statistics: statistics),

            SizedBox(height: 24.w),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: theme.accent,
              unselectedLabelColor: theme.textSecondary,
              indicatorColor: theme.accent,
              labelStyle:
                  TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 12.sp),
              tabs: [
                Tab(text: l10n.duel),
                Tab(text: l10n.achievements),
                Tab(text: l10n.event),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBattleTab(theme, l10n),
                  _buildAchievementTab(theme, l10n),
                  _buildEventTab(theme, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }

  void _showNicknameEditDialog(AppThemeColors theme, AppLocalizations l10n) {
    final controller = TextEditingController(text: AuthService.displayName);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.editNickname,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 20,
              autofocus: true,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.enterNickname,
                hintStyle: TextStyle(color: theme.textSecondary),
                filled: true,
                fillColor: theme.accentLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(color: theme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newNickname = controller.text.trim();
                      if (newNickname.isNotEmpty && newNickname.length >= 3) {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);
                        
                        await AuthService.setNickname(newNickname);
                        
                        if (mounted) {
                          navigator.pop();
                          setState(() {});
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.nicknameSaved),
                              backgroundColor: theme.success,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.nicknameMinLength),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.ok),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      },
    );
  }

  void _showCountryPicker(AppThemeColors theme, AppLocalizations l10n) {
    final countries = _getCountryList();
    final currentCode = AuthService.getCountryCode();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filteredCountries = searchQuery.isEmpty
                ? countries
                : countries.where((c) => 
                    c['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    c['code']!.toLowerCase().contains(searchQuery.toLowerCase())
                  ).toList();
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        l10n.selectCountry,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(
                        onChanged: (value) => setStateModal(() => searchQuery = value),
                        style: TextStyle(color: theme.textPrimary),
                        decoration: InputDecoration(
                          hintText: l10n.search,
                          hintStyle: TextStyle(color: theme.textSecondary),
                          prefixIcon: Icon(Bootstrap.search, color: theme.iconSecondary, size: 18),
                          filled: true,
                          fillColor: theme.accentLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    // Country list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final code = country['code']!;
                          final name = country['name']!;
                          final flag = _getFlag(code);
                          final isSelected = code == currentCode;
                          
                          return ListTile(
                            leading: Text(flag, style: const TextStyle(fontSize: 24)),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected 
                                ? Icon(Bootstrap.check_circle_fill, color: theme.accent, size: 20)
                                : null,
                            onTap: () async {
                              final navigator = Navigator.of(ctx);
                              await AuthService.setCountryCode(code);
                              if (mounted) {
                                navigator.pop();
                                setState(() {});
                              }
                            },
                          );
                        },
                      ),
                    ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _getFlag(String code) {
    if (code.length != 2) return '🌍';
    final upperCode = code.toUpperCase();
    final firstLetter = upperCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = upperCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([firstLetter, secondLetter]);
  }

  List<Map<String, String>> _getCountryList() {
    return [
      {'code': 'TR', 'name': 'Türkiye'},
      {'code': 'US', 'name': 'United States'},
      {'code': 'GB', 'name': 'United Kingdom'},
      {'code': 'DE', 'name': 'Germany'},
      {'code': 'FR', 'name': 'France'},
      {'code': 'IT', 'name': 'Italy'},
      {'code': 'ES', 'name': 'Spain'},
      {'code': 'PT', 'name': 'Portugal'},
      {'code': 'NL', 'name': 'Netherlands'},
      {'code': 'BE', 'name': 'Belgium'},
      {'code': 'CH', 'name': 'Switzerland'},
      {'code': 'AT', 'name': 'Austria'},
      {'code': 'SE', 'name': 'Sweden'},
      {'code': 'NO', 'name': 'Norway'},
      {'code': 'DK', 'name': 'Denmark'},
      {'code': 'FI', 'name': 'Finland'},
      {'code': 'PL', 'name': 'Poland'},
      {'code': 'CZ', 'name': 'Czech Republic'},
      {'code': 'SK', 'name': 'Slovakia'},
      {'code': 'HU', 'name': 'Hungary'},
      {'code': 'RO', 'name': 'Romania'},
      {'code': 'BG', 'name': 'Bulgaria'},
      {'code': 'GR', 'name': 'Greece'},
      {'code': 'HR', 'name': 'Croatia'},
      {'code': 'SI', 'name': 'Slovenia'},
      {'code': 'RS', 'name': 'Serbia'},
      {'code': 'UA', 'name': 'Ukraine'},
      {'code': 'RU', 'name': 'Russia'},
      {'code': 'BY', 'name': 'Belarus'},
      {'code': 'LT', 'name': 'Lithuania'},
      {'code': 'LV', 'name': 'Latvia'},
      {'code': 'EE', 'name': 'Estonia'},
      {'code': 'IE', 'name': 'Ireland'},
      {'code': 'IS', 'name': 'Iceland'},
      {'code': 'LU', 'name': 'Luxembourg'},
      {'code': 'MT', 'name': 'Malta'},
      {'code': 'CY', 'name': 'Cyprus'},
      {'code': 'AL', 'name': 'Albania'},
      {'code': 'MK', 'name': 'North Macedonia'},
      {'code': 'BA', 'name': 'Bosnia and Herzegovina'},
      {'code': 'ME', 'name': 'Montenegro'},
      {'code': 'XK', 'name': 'Kosovo'},
      {'code': 'MD', 'name': 'Moldova'},
      {'code': 'GE', 'name': 'Georgia'},
      {'code': 'AM', 'name': 'Armenia'},
      {'code': 'AZ', 'name': 'Azerbaijan'},
      {'code': 'KZ', 'name': 'Kazakhstan'},
      {'code': 'UZ', 'name': 'Uzbekistan'},
      {'code': 'TM', 'name': 'Turkmenistan'},
      {'code': 'KG', 'name': 'Kyrgyzstan'},
      {'code': 'TJ', 'name': 'Tajikistan'},
      {'code': 'CN', 'name': 'China'},
      {'code': 'JP', 'name': 'Japan'},
      {'code': 'KR', 'name': 'South Korea'},
      {'code': 'KP', 'name': 'North Korea'},
      {'code': 'TW', 'name': 'Taiwan'},
      {'code': 'HK', 'name': 'Hong Kong'},
      {'code': 'MO', 'name': 'Macau'},
      {'code': 'MN', 'name': 'Mongolia'},
      {'code': 'IN', 'name': 'India'},
      {'code': 'PK', 'name': 'Pakistan'},
      {'code': 'BD', 'name': 'Bangladesh'},
      {'code': 'LK', 'name': 'Sri Lanka'},
      {'code': 'NP', 'name': 'Nepal'},
      {'code': 'BT', 'name': 'Bhutan'},
      {'code': 'MV', 'name': 'Maldives'},
      {'code': 'AF', 'name': 'Afghanistan'},
      {'code': 'IR', 'name': 'Iran'},
      {'code': 'IQ', 'name': 'Iraq'},
      {'code': 'SA', 'name': 'Saudi Arabia'},
      {'code': 'AE', 'name': 'United Arab Emirates'},
      {'code': 'QA', 'name': 'Qatar'},
      {'code': 'KW', 'name': 'Kuwait'},
      {'code': 'BH', 'name': 'Bahrain'},
      {'code': 'OM', 'name': 'Oman'},
      {'code': 'YE', 'name': 'Yemen'},
      {'code': 'JO', 'name': 'Jordan'},
      {'code': 'LB', 'name': 'Lebanon'},
      {'code': 'SY', 'name': 'Syria'},
      {'code': 'IL', 'name': 'Israel'},
      {'code': 'PS', 'name': 'Palestine'},
      {'code': 'EG', 'name': 'Egypt'},
      {'code': 'LY', 'name': 'Libya'},
      {'code': 'TN', 'name': 'Tunisia'},
      {'code': 'DZ', 'name': 'Algeria'},
      {'code': 'MA', 'name': 'Morocco'},
      {'code': 'SD', 'name': 'Sudan'},
      {'code': 'SS', 'name': 'South Sudan'},
      {'code': 'ET', 'name': 'Ethiopia'},
      {'code': 'KE', 'name': 'Kenya'},
      {'code': 'TZ', 'name': 'Tanzania'},
      {'code': 'UG', 'name': 'Uganda'},
      {'code': 'RW', 'name': 'Rwanda'},
      {'code': 'BI', 'name': 'Burundi'},
      {'code': 'CD', 'name': 'DR Congo'},
      {'code': 'CG', 'name': 'Congo'},
      {'code': 'GA', 'name': 'Gabon'},
      {'code': 'CM', 'name': 'Cameroon'},
      {'code': 'NG', 'name': 'Nigeria'},
      {'code': 'GH', 'name': 'Ghana'},
      {'code': 'CI', 'name': 'Ivory Coast'},
      {'code': 'SN', 'name': 'Senegal'},
      {'code': 'ML', 'name': 'Mali'},
      {'code': 'NE', 'name': 'Niger'},
      {'code': 'BF', 'name': 'Burkina Faso'},
      {'code': 'TG', 'name': 'Togo'},
      {'code': 'BJ', 'name': 'Benin'},
      {'code': 'MR', 'name': 'Mauritania'},
      {'code': 'GM', 'name': 'Gambia'},
      {'code': 'GW', 'name': 'Guinea-Bissau'},
      {'code': 'GN', 'name': 'Guinea'},
      {'code': 'SL', 'name': 'Sierra Leone'},
      {'code': 'LR', 'name': 'Liberia'},
      {'code': 'CV', 'name': 'Cape Verde'},
      {'code': 'ZA', 'name': 'South Africa'},
      {'code': 'NA', 'name': 'Namibia'},
      {'code': 'BW', 'name': 'Botswana'},
      {'code': 'ZW', 'name': 'Zimbabwe'},
      {'code': 'ZM', 'name': 'Zambia'},
      {'code': 'MW', 'name': 'Malawi'},
      {'code': 'MZ', 'name': 'Mozambique'},
      {'code': 'MG', 'name': 'Madagascar'},
      {'code': 'MU', 'name': 'Mauritius'},
      {'code': 'SC', 'name': 'Seychelles'},
      {'code': 'KM', 'name': 'Comoros'},
      {'code': 'AO', 'name': 'Angola'},
      {'code': 'SZ', 'name': 'Eswatini'},
      {'code': 'LS', 'name': 'Lesotho'},
      {'code': 'ER', 'name': 'Eritrea'},
      {'code': 'DJ', 'name': 'Djibouti'},
      {'code': 'SO', 'name': 'Somalia'},
      {'code': 'CF', 'name': 'Central African Republic'},
      {'code': 'TD', 'name': 'Chad'},
      {'code': 'GQ', 'name': 'Equatorial Guinea'},
      {'code': 'ST', 'name': 'São Tomé and Príncipe'},
      {'code': 'CA', 'name': 'Canada'},
      {'code': 'MX', 'name': 'Mexico'},
      {'code': 'GT', 'name': 'Guatemala'},
      {'code': 'BZ', 'name': 'Belize'},
      {'code': 'HN', 'name': 'Honduras'},
      {'code': 'SV', 'name': 'El Salvador'},
      {'code': 'NI', 'name': 'Nicaragua'},
      {'code': 'CR', 'name': 'Costa Rica'},
      {'code': 'PA', 'name': 'Panama'},
      {'code': 'CU', 'name': 'Cuba'},
      {'code': 'HT', 'name': 'Haiti'},
      {'code': 'DO', 'name': 'Dominican Republic'},
      {'code': 'JM', 'name': 'Jamaica'},
      {'code': 'TT', 'name': 'Trinidad and Tobago'},
      {'code': 'BB', 'name': 'Barbados'},
      {'code': 'BS', 'name': 'Bahamas'},
      {'code': 'PR', 'name': 'Puerto Rico'},
      {'code': 'BR', 'name': 'Brazil'},
      {'code': 'AR', 'name': 'Argentina'},
      {'code': 'CL', 'name': 'Chile'},
      {'code': 'CO', 'name': 'Colombia'},
      {'code': 'VE', 'name': 'Venezuela'},
      {'code': 'PE', 'name': 'Peru'},
      {'code': 'EC', 'name': 'Ecuador'},
      {'code': 'BO', 'name': 'Bolivia'},
      {'code': 'PY', 'name': 'Paraguay'},
      {'code': 'UY', 'name': 'Uruguay'},
      {'code': 'GY', 'name': 'Guyana'},
      {'code': 'SR', 'name': 'Suriname'},
      {'code': 'AU', 'name': 'Australia'},
      {'code': 'NZ', 'name': 'New Zealand'},
      {'code': 'FJ', 'name': 'Fiji'},
      {'code': 'PG', 'name': 'Papua New Guinea'},
      {'code': 'SB', 'name': 'Solomon Islands'},
      {'code': 'VU', 'name': 'Vanuatu'},
      {'code': 'NC', 'name': 'New Caledonia'},
      {'code': 'WS', 'name': 'Samoa'},
      {'code': 'TO', 'name': 'Tonga'},
      {'code': 'TH', 'name': 'Thailand'},
      {'code': 'VN', 'name': 'Vietnam'},
      {'code': 'MY', 'name': 'Malaysia'},
      {'code': 'SG', 'name': 'Singapore'},
      {'code': 'ID', 'name': 'Indonesia'},
      {'code': 'PH', 'name': 'Philippines'},
      {'code': 'MM', 'name': 'Myanmar'},
      {'code': 'KH', 'name': 'Cambodia'},
      {'code': 'LA', 'name': 'Laos'},
      {'code': 'BN', 'name': 'Brunei'},
      {'code': 'TL', 'name': 'Timor-Leste'},
    ];
  }

  Widget _buildLevelCard(AppThemeColors theme, AppLocalizations l10n) {
    final levelData = LevelService.levelData;
    final rank = levelData.rank;
    final season = LevelService.currentSeason;
    final countryFlag = AuthService.getCountryFlag();

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding()),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: theme.buttonPrimary,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(color: theme.buttonPrimary, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // User info row (avatar, name)
            Row(
              children: [
                // Avatar with frame - tap to open rewards
                GestureDetector(
                  onTap: () {
                    HapticService.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RewardsScreen()),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildFramedAvatar(rank, theme),
                      // Country flag badge
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: () => _showCountryPicker(theme, l10n),
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: theme.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.buttonPrimary, width: 2),
                            ),
                            child: Text(
                              countryFlag,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                // Username and member info - full width
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username with edit - now on its own line
                      GestureDetector(
                        onTap: () => _showNicknameEditDialog(theme, l10n),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AuthService.displayName,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.buttonText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Bootstrap.pencil,
                              size: 16.w,
                              color: theme.buttonText.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.w),
                      // Member since
                      if (_memberSince != null)
                        Text(
                          '${l10n.memberSince}: ${_formatDate(_memberSince!)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.buttonText.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.w),
            // Level progress section - tap to open rewards
            GestureDetector(
              onTap: () {
                HapticService.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RewardsScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: theme.buttonText.withValues(alpha: 0.15),
                  borderRadius: AppTheme.buttonRadius,
                ),
                child: Column(
                  children: [
                    // Rank name and level badge row
                    Row(
                      children: [
                        Text(
                          _getLocalizedRank(l10n, rank.rank),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.buttonText,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                          decoration: BoxDecoration(
                            color: theme.buttonText.withValues(alpha: 0.25),
                            borderRadius: AppTheme.buttonRadius,
                          ),
                          child: Text(
                            '${l10n.level} ${levelData.level}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonText,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.chevron_right,
                          color: theme.buttonText.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.w),
                    // XP Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.w),
                      child: LinearProgressIndicator(
                        value: levelData.levelProgress,
                        backgroundColor: theme.buttonText.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(theme.buttonText),
                        minHeight: 6.w,
                      ),
                    ),
                    SizedBox(height: 6.w),
                    // XP text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${levelData.totalXp} XP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.buttonText.withValues(alpha: 0.9),
                          ),
                        ),
                        if (levelData.level < LevelConstants.maxLevel)
                          Text(
                            '${levelData.xpToNextLevel} XP ${l10n.toNextLevel}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.buttonText.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.w),
            // Season info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: theme.buttonText.withValues(alpha: 0.2),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: theme.warning, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        '${l10n.season} ${season.seasonNumber}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.buttonText,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${season.daysRemaining} ${l10n.daysRemaining}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.buttonText.withValues(alpha: 0.9),
                    ),
                  ),
                  if (levelData.streakDays > 0)
                    Row(
                      children: [
                        Icon(Icons.local_fire_department,
                            color: theme.warning, size: 14.w),
                        SizedBox(width: 2.w),
                        Text(
                          '${levelData.streakDays} ${l10n.streak}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedRank(AppLocalizations l10n, UserRank rank) {
    switch (rank) {
      case UserRank.novice:
        return l10n.novice;
      case UserRank.amateur:
        return l10n.amateur;
      case UserRank.talented:
        return l10n.talented;
      case UserRank.expert:
        return l10n.expert;
      case UserRank.master:
        return l10n.master;
      case UserRank.legend:
        return l10n.legend;
      case UserRank.sudokuKing:
        return l10n.sudokuKing;
    }
  }

  Widget _buildFramedAvatar(RankInfo rank, AppThemeColors theme) {
    // Watch the provider for real-time updates
    final selectedFrameId = ref.watch(selectedFrameProvider);

    // Get selected frame - check both normal and ranked frames
    FrameReward? selectedFrame;
    if (selectedFrameId.isNotEmpty && selectedFrameId != 'frame_basic') {
      // First check normal frames
      try {
        selectedFrame =
            CosmeticRewards.frames.firstWhere((f) => f.id == selectedFrameId);
      } catch (_) {}

      // Then check ranked frames if not found
      if (selectedFrame == null) {
        try {
          selectedFrame = CosmeticRewards.rankedFrames
              .firstWhere((f) => f.id == selectedFrameId);
        } catch (_) {}
      }
    }

    final avatarSize = 56.w;
    final hasFrame = selectedFrame != null;

    // Frame + Avatar combined design
    if (hasFrame) {
      return AnimatedAvatarFrame(
        frame: selectedFrame,
        size: avatarSize,
        showAnimation: true,
        child: _buildFrameContent(selectedFrame, avatarSize),
      );
    }

    // Default avatar (no frame selected)
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: rank.imagePath != null
            ? ClipRRect(
                borderRadius: AppTheme.cardRadius,
                child: Image.asset(
                  rank.imagePath!,
                  width: avatarSize * 0.6,
                  height: avatarSize * 0.6,
                  errorBuilder: (_, __, ___) =>
                      Text(rank.icon, style: TextStyle(fontSize: 26.sp)),
                ),
              )
            : Text(rank.icon, style: TextStyle(fontSize: 26.sp)),
      ),
    );
  }

  Widget _buildFrameContent(FrameReward frame, double avatarSize) {
    if (frame.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14.w),
        child: Image.asset(
          frame.imagePath!,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildFrameIconFallback(frame, avatarSize),
        ),
      );
    }
    return _buildFrameIconFallback(frame, avatarSize);
  }

  Widget _buildFrameIconFallback(FrameReward frame, double avatarSize) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: frame.gradientColors,
        ),
        borderRadius: BorderRadius.circular(14.w),
        boxShadow: [
          BoxShadow(
            color: frame.gradientColors.first.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          frame.iconData ?? Icons.star,
          color: Colors.white,
          size: 28.w,
        ),
      ),
    );
  }


  Widget _buildEventTab(AppThemeColors theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_outlined,
            size: 50.w,
            color: theme.textMuted,
          ),
          SizedBox(height: 16.w),
          Text(
            l10n.eventHistory,
            style: AppTextStyles.title(context, color: theme.textSecondary),
          ),
          SizedBox(height: 8.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              l10n.participateInEvents,
              style: AppTextStyles.body(context, color: theme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleTab(AppThemeColors theme, AppLocalizations l10n) {
    final duelStats = LocalDuelStatsService.getAllStats();
    final rank = duelStats['rank'] as String? ?? 'Bronze';
    final elo = duelStats['elo'] as int? ?? 1000;
    final wins = duelStats['wins'] as int? ?? 0;
    final winRate = duelStats['winRate'] as double? ?? 0.0;
    final bestStreak = duelStats['bestStreak'] as int? ?? 0;

    final divColor = _getDuelDivisionColor(rank);
    final progress = LocalDuelStatsService.getDivisionProgress(elo);
    final eloToNext = LocalDuelStatsService.getEloToNextDivision(elo);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Column(
        children: [
          // Duel Division Card
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [divColor, divColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDivisionDisplay(rank),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rank,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$elo ELO',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    _buildMiniStat('$wins', l10n.wins),
                    SizedBox(width: 10.w),
                    _buildMiniStat(
                        '${winRate.toStringAsFixed(0)}%', l10n.winRate),
                    SizedBox(width: 10.w),
                    _buildMiniStat('$bestStreak', l10n.bestStreak),
                  ],
                ),
                SizedBox(height: 8.w),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.w),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      eloToNext > 0 ? '$eloToNext ELO' : 'MAX',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          // Duel Rewards Button
          _buildDuelRewardsButton(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildDuelRewardsButton(AppThemeColors theme, AppLocalizations l10n) {
    final duelWins = LocalDuelStatsService.wins;
    final duelElo = LocalDuelStatsService.elo;

    // Count unlocked rewards using same logic as DuelRewardsScreen
    int unlockedFrames = 0;
    int unlockedThemes = 0;

    // Check each frame's unlock condition
    for (final frame in CosmeticRewards.rankedFrames) {
      if (_isRewardUnlocked(frame, duelWins, duelElo)) {
        unlockedFrames++;
      }
    }

    // Check each theme's unlock condition
    for (final themeReward in CosmeticRewards.rankedThemes) {
      if (_isRewardUnlocked(themeReward, duelWins, duelElo)) {
        unlockedThemes++;
      }
    }

    final totalFrames = CosmeticRewards.rankedFrames.length;
    final totalThemes = CosmeticRewards.rankedThemes.length;

    return GestureDetector(
      onTap: () async {
        HapticService.selectionClick();
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const DuelRewardsScreen()),
        );
        if (changed == true && mounted) {
          // Update the frame provider so avatar updates immediately
          ref.read(selectedFrameProvider.notifier).state =
              LevelService.selectedFrameId;
          setState(() {});
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
        decoration: BoxDecoration(
          color: theme.buttonPrimary,
          borderRadius: AppTheme.buttonRadius,
          border: Border.all(color: theme.buttonPrimary),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.military_tech, color: theme.accent, size: 20.w),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                l10n.duelRewards,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.buttonText),
              ),
            ),
            Text(
              '🖼️ $unlockedFrames/$totalFrames  🎨 $unlockedThemes/$totalThemes',
              style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.buttonText.withValues(alpha: 0.9)),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, color: theme.buttonText, size: 18.w),
          ],
        ),
      ),
    );
  }

  bool _isRewardUnlocked(CosmeticReward reward, int duelWins, int duelElo) {
    final condition = reward.unlockCondition;
    if (condition == null) return true;

    switch (condition) {
      // Win-based rewards
      case 'ranked_10_wins':
        return duelWins >= 10;
      case 'ranked_50_wins':
        return duelWins >= 50;
      case 'ranked_100_wins':
        return duelWins >= 100;
      case 'ranked_250_wins':
        return duelWins >= 250;

      // Division-based rewards (ELO)
      case 'platinum_division':
        return duelElo >= 1100;
      case 'diamond_division':
        return duelElo >= 1400;
      case 'master_division':
        return duelElo >= 1700;
      case 'grandmaster_division':
        return duelElo >= 2000;
      case 'champion_division':
        return duelElo >= 2300;

      // Season rewards - check manual unlocks
      case 'season_top50':
      case 'season_top10':
      case 'season_top3':
      case 'season_first':
        final unlockedRewards = LevelService.levelData.unlockedRewards;
        return unlockedRewards.contains(condition) ||
            unlockedRewards.contains(reward.id);

      default:
        return false;
    }
  }

  Color _getDuelDivisionColor(String rank) {
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
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildDivisionDisplay(String rank) {
    final imgPath = LocalDuelStatsService.getRankImagePath(rank);
    if (imgPath != null) {
      return Image.asset(
        imgPath,
        width: 28.w,
        height: 28.w,
        errorBuilder: (_, __, ___) => Text(
          LocalDuelStatsService.getRankEmoji(rank),
          style: TextStyle(fontSize: 24.sp),
        ),
      );
    }
    return Text(
      LocalDuelStatsService.getRankEmoji(rank),
      style: TextStyle(fontSize: 24.sp),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 9.sp)),
      ],
    );
  }

  Widget _buildAchievementTab(AppThemeColors theme, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Achievement progress overview
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: theme.buttonPrimary,
              borderRadius: AppTheme.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 40.w,
                      color: theme.buttonText,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.achievements,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: theme.buttonText,
                            ),
                          ),
                          SizedBox(height: 4.w),
                          Text(
                            l10n.checkYourProgress,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: theme.buttonText.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openAchievements(),
                      child: Text(
                        l10n.viewAll,
                        style: TextStyle(
                            color: theme.buttonText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600),
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

  void _openLeaderboard() {
    HapticService.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }
}
