import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/services/purchase_service.dart';
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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupPurchaseListener();
    _loadProducts();
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
          _showSuccessDialog(message ?? 'Premium activated!');
          break;
        case PurchaseResult.restored:
          ref.read(adsFreeProvider.notifier).state = true;
          _showSuccessDialog(message ?? 'Purchase restored!');
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
          _showErrorSnackbar(message ?? 'An error occurred');
          break;
        case PurchaseResult.pending:
          // Still processing
          break;
      }
    };
  }

  Future<void> _loadProducts() async {
    // Reload products if not loaded
    if (!PurchaseService.hasProducts) {
      await PurchaseService.reloadProducts();
      if (mounted) setState(() {});
    }
  }

  void _showSuccessDialog(String message) {
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
              'Welcome to Premium!',
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
              child: const Text(
                'Start Playing!',
                style: TextStyle(
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Retry',
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
    for (int i = 0; i < 4; i++) {
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
    if (_isLoading || _isRestoring) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();
    await PurchaseService.buySubscription(_selectedPlan);
  }

  void _onRestore() async {
    if (_isLoading || _isRestoring) return;

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    final restored = await PurchaseService.restorePurchases();

    if (!mounted) return;

    setState(() => _isRestoring = false);

    if (!restored && mounted) {
      final theme = AppThemeManager.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No previous purchases found'),
          backgroundColor: theme.textSecondary,
        ),
      );
    }
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
          SubscriptionPlan.weekly,
          l10n.weekly,
          PurchaseService.getPrice(SubscriptionPlan.weekly),
          '',
          theme,
          size,
        ),
        SizedBox(width: size.width * 0.02),
        _buildPlanCard(
          SubscriptionPlan.yearly,
          l10n.yearly,
          PurchaseService.getPrice(SubscriptionPlan.yearly),
          l10n.save70,
          theme,
          size,
          isPopular: true,
        ),
        SizedBox(width: size.width * 0.02),
        _buildPlanCard(
          SubscriptionPlan.monthly,
          l10n.monthly,
          PurchaseService.getPrice(SubscriptionPlan.monthly),
          l10n.save35,
          theme,
          size,
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, String title, String price,
      String savings, AppThemeColors theme, Size size,
      {bool isPopular = false}) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _selectedPlan == plan;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
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
              Text(
                price,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? theme.accent : theme.textPrimary,
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
      AppLocalizations l10n, AppThemeColors theme, Size size) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isLoading ? null : _onPurchase,
          child: Container(
            width: double.infinity,
            height: size.height * 0.06,
            decoration: BoxDecoration(
              color: _isLoading
                  ? theme.textSecondary.withValues(alpha: 0.5)
                  : theme.buttonPrimary,
              borderRadius: AppTheme.cardRadius,
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                        'Processing...',
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
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final Color color;

  _FeatureItem(this.icon, this.title, this.color);
}
