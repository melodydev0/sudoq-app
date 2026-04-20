import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/paywall_analytics.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with TickerProviderStateMixin {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  bool _isLoading = false;
  bool _isRestoring = false;
  String? _errorMessage;

  late AnimationController _mainController;
  late AnimationController _crownController;
  late AnimationController _buttonController;

  late Animation<double> _crownScale;
  late Animation<double> _crownRotation;

  final List<Animation<Offset>> _featureSlides = [];
  final List<Animation<double>> _featureFades = [];

  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupPurchaseListener();
    _loadProducts();
    // Log paywall impression for A/B experiment tracking
    PaywallAnalytics.logPaywallView();
  }

  void _setupPurchaseListener() {
    PurchaseService.onPurchaseResult = (result, message) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRestoring = false;
      });

      switch (result) {
        case PurchaseResult.success:
          // Update provider
          ref.read(adsFreeProvider.notifier).state = true;
          _showSuccessDialog(message ?? AppLocalizations.of(context).premiumActivated);
          break;
        case PurchaseResult.restored:
          ref.read(adsFreeProvider.notifier).state = true;
          _showSuccessDialog(message ?? AppLocalizations.of(context).purchaseRestored);
          break;
        case PurchaseResult.alreadyOwned:
          ref.read(adsFreeProvider.notifier).state = true;
          Navigator.pop(context, true);
          break;
        case PurchaseResult.cancelled:
          // User cancelled, do nothing
          break;
        case PurchaseResult.error:
          setState(() => _errorMessage = message);
          _showErrorSnackbar(message ?? AppLocalizations.of(context).errorPrefix);
          break;
        case PurchaseResult.pending:
          // Still processing
          break;
      }
    };
  }

  Future<void> _loadProducts() async {
    if (!PurchaseService.hasProducts) {
      setState(() => _isLoadingProducts = true);
      await PurchaseService.reloadProducts();
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _showSuccessDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeToPremium,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              child: Text(
                l10n.startPlaying,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: l10n.tryAgain,
          textColor: Colors.white,
          onPressed: _onPurchase,
        ),
      ),
    );
  }

  void _initAnimations() {
    // Main stagger controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Crown bounce animation
    _crownController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _crownScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _crownController, curve: Curves.easeInOut),
    );

    _crownRotation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _crownController, curve: Curves.easeInOut),
    );

    // Button pulse
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Staggered feature animations
    for (int i = 0; i < 5; i++) {
      final startInterval = 0.1 + (i * 0.15);
      final endInterval = (startInterval + 0.3).clamp(0.0, 1.0);

      _featureSlides.add(
        Tween<Offset>(
          begin: const Offset(-0.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve:
              Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
        )),
      );

      _featureFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _mainController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
        )),
      );
    }

    _mainController.forward();
  }

  @override
  void dispose() {
    PurchaseService.onPurchaseResult = null;
    _mainController.dispose();
    _crownController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onPurchase() async {
    if (_isLoading || _isRestoring || _isLoadingProducts) return;
    if (!PurchaseService.hasProducts) return;

    final hasPermanentAccount = AuthService.isSignedIn && !AuthService.isAnonymous;
    if (!hasPermanentAccount) {
      final signedIn = await _showAccountRequiredDialog();
      if (!signedIn) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticService.mediumImpact();
    PaywallAnalytics.logCtaTapped(_selectedPlan.name);
    await PurchaseService.buySubscription(_selectedPlan);
  }

  void _onRestore() async {
    if (_isLoading || _isRestoring) return;

    final hasPermanentAccount = AuthService.isSignedIn && !AuthService.isAnonymous;
    if (!hasPermanentAccount) {
      final signedIn = await _showAccountRequiredDialog();
      if (!signedIn) return;
    }

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    HapticService.lightImpact();

    final restored = await PurchaseService.restorePurchases();

    if (!mounted) return;

    setState(() => _isRestoring = false);

    if (!restored && mounted) {
      final theme = AppThemeManager.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noPreviousPurchases),
          backgroundColor: theme.textSecondary,
        ),
      );
    }
  }

  Future<bool> _showAccountRequiredDialog() async {
    final theme = AppThemeManager.colors;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool isSigningIn = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> signInWithGoogle() async {
              if (isSigningIn) return;
              final navigator = Navigator.of(context);
              setStateDialog(() => isSigningIn = true);
              final cred = await AuthService.signInWithGoogle();
              if (!navigator.mounted) return;
              navigator.pop(cred?.user != null);
            }

            Future<void> signInWithApple() async {
              if (isSigningIn) return;
              final navigator = Navigator.of(context);
              setStateDialog(() => isSigningIn = true);
              final cred = await AuthService.signInWithApple();
              if (!navigator.mounted) return;
              navigator.pop(cred?.user != null);
            }

            return AlertDialog(
              shape:
                  const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
              title: Text(AppLocalizations.of(context).signInRequired),
              content: Text(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? 'To protect your subscription across devices and avoid purchase loss, '
                      'please sign in with Google or Apple before purchasing premium.'
                    : 'To protect your subscription across devices and avoid purchase loss, '
                      'please sign in with Google before purchasing premium.',
              ),
              actions: [
                TextButton(
                  onPressed: isSigningIn
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context).noThanks),
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS)
                  TextButton.icon(
                    onPressed: isSigningIn ? null : signInWithApple,
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple'),
                  ),
                FilledButton.icon(
                  onPressed: isSigningIn ? null : signInWithGoogle,
                  icon: isSigningIn
                      ? SizedBox(
                          width: 14.sp,
                          height: 14.sp,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.buttonPrimary,
                    foregroundColor: theme.buttonText,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).signInSuccessful),
          ),
        );
      }
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).signInBeforePurchase),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.backgroundGradientStart,
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.015,
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(l10n, theme),

                SizedBox(height: size.height * 0.02),

                // Animated Crown
                _buildAnimatedCrown(size),

                SizedBox(height: size.height * 0.025),

                // Features - Compact Row Style
                _buildFeatures(l10n, theme, size),

                const Spacer(),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),

                // Plans
                _buildPlans(l10n, theme, size),

                SizedBox(height: size.height * 0.02),

                // Subscribe Button with animation
                _buildAnimatedButton(l10n, theme, size),

                SizedBox(height: size.height * 0.01),

                // Restore
                TextButton(
                  onPressed: _isRestoring ? null : _onRestore,
                  child: _isRestoring
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.textSecondary,
                          ),
                        )
                      : Text(
                          l10n.restorePurchase,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.textSecondary,
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

  Widget _buildHeader(AppLocalizations l10n, AppThemeColors theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: AppTheme.buttonRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.close, color: theme.textSecondary, size: 18),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Bootstrap.gem, color: AppColors.accentGold, size: 20),
            const SizedBox(width: 6),
            Text(
              l10n.goPremium,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 34),
      ],
    );
  }

  Widget _buildAnimatedCrown(Size size) {
    return AnimatedBuilder(
      animation: _crownController,
      builder: (context, child) {
        return Transform.scale(
          scale: _crownScale.value,
          child: Transform.rotate(
            angle: _crownRotation.value,
            child: Container(
              width: size.width * 0.2,
              height: size.width * 0.2,
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: AppTheme.cardRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                FontAwesome.crown_solid,
                size: size.width * 0.09,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatures(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    final features = [
      _FeatureItem(
          Bootstrap.slash_circle_fill, l10n.adsFree, AppColors.accentCoral),
      _FeatureItem(
          Bootstrap.lightbulb_fill, l10n.unlimitedHints, AppColors.info),
      _FeatureItem(
          Bootstrap.arrow_repeat, l10n.secondChances, AppColors.accentTeal),
      _FeatureItem(Bootstrap.lightning_charge_fill, l10n.smartPencil,
          AppColors.accentPurple),
      _FeatureItem(Bootstrap.star_fill, l10n.xpBoost, AppColors.accentGold),
    ];

    return Column(
      children: List.generate(features.length, (index) {
        return AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return SlideTransition(
              position: _featureSlides[index],
              child: FadeTransition(
                opacity: _featureFades[index],
                child: _buildFeatureRow(features[index], theme, size),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFeatureRow(
      _FeatureItem feature, AppThemeColors theme, Size size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.01),
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: theme.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : theme.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: AppTheme.buttonRadius,
            ),
            child: Center(
              child: Icon(feature.icon, color: feature.color, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Bootstrap.check_lg,
                color: AppColors.success, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(AppLocalizations l10n, AppThemeColors theme, Size size) {
    return Row(
      children: [
        _buildPlanCard(
          plan: SubscriptionPlan.weekly,
          title: l10n.weekly,
          savings: '',
          theme: theme,
          size: size,
        ),
        SizedBox(width: size.width * 0.03),
        _buildPlanCard(
          plan: SubscriptionPlan.yearly,
          title: l10n.yearly,
          savings: () {
            // Remote Config can force a specific % (e.g. for marketing copy testing)
            final rcPct = RemoteConfigService.yearlyBadgePct;
            if (rcPct > 0) return l10n.savePercent(rcPct);
            final pct = PurchaseService.getYearlySavingsPercent();
            return pct != null ? l10n.savePercent(pct) : l10n.save70;
          }(),
          theme: theme,
          size: size,
          isPopular: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String title,
    required String savings,
    required AppThemeColors theme,
    required Size size,
    bool isPopular = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _selectedPlan == plan;
    final pricing = PurchaseService.getPlanPricing(plan);
    final displayPrice = PurchaseService.getPrice(plan);
    final hasIntro = pricing?.hasIntroOffer ?? false;
    final regularPrice = pricing?.regularPrice;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          setState(() => _selectedPlan = plan);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: size.height * 0.015,
            horizontal: size.width * 0.01,
          ),
          decoration: BoxDecoration(
            color:
                isSelected ? theme.accent.withValues(alpha: 0.12) : theme.card,
            borderRadius: AppTheme.buttonRadius,
            border: Border.all(
              color: isSelected ? theme.accent : theme.divider,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.textPrimary.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPopular)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: AppTheme.buttonRadius,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.best,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),

              // Strikethrough regular price (shown only when intro offer exists)
              if (hasIntro && regularPrice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      regularPrice,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary.withValues(alpha: 0.7),
                        decoration: TextDecoration.lineThrough,
                        decorationColor:
                            theme.textSecondary.withValues(alpha: 0.7),
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ),

              // Current price or loading placeholder
              if (displayPrice != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    displayPrice,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? theme.accent : theme.textPrimary,
                    ),
                  ),
                )
              else
                _buildPriceShimmer(theme),

              // Savings badge (cross-plan comparison)
              if (savings.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppTheme.buttonRadius,
                  ),
                  child: Text(
                    savings,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: AppColors.success,
                    ),
                  ),
                ),

              // Weekly equivalent price (only on yearly card)
              if (plan == SubscriptionPlan.yearly)
                Builder(builder: (context) {
                  final weeklyEq = PurchaseService.getYearlyWeeklyEquivalent();
                  if (weeklyEq == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '≈ $weeklyEq/${AppLocalizations.of(context).weekly.toLowerCase()}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: theme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    final bool canPurchase =
        !_isLoading && !_isLoadingProducts && PurchaseService.hasProducts;

    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return GestureDetector(
          onTap: canPurchase ? _onPurchase : null,
          child: Container(
            width: double.infinity,
            height: size.height * 0.06,
            decoration: BoxDecoration(
              color: canPurchase
                  ? theme.buttonPrimary
                  : theme.textSecondary.withValues(alpha: 0.5),
              borderRadius: AppTheme.cardRadius,
              boxShadow: canPurchase
                  ? [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isLoading
                  ? [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.processing,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
                    ]
                  : [
                      Icon(Bootstrap.unlock_fill,
                          color: theme.buttonText, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.unlockPremium,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: theme.buttonText,
                        ),
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceShimmer(AppThemeColors theme) {
    return Container(
      width: 48,
      height: 18,
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final Color color;

  _FeatureItem(this.icon, this.title, this.color);
}
