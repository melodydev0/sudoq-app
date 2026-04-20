import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../home/presentation/screens/home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  bool _notifGranted = false;
  bool _locationGranted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);
    HapticService.mediumImpact();

    // 1 – Bildirim izni (OneSignal)
    try {
      await NotificationService.init().timeout(
        const Duration(seconds: 8),
        onTimeout: () => debugPrint('NotificationService.init timed out'),
      );
      final granted = OneSignal.Notifications.permission;
      if (mounted) setState(() => _notifGranted = granted);
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    // 2 – Konum izni (timeout ile)
    try {
      final perm = await LocationService.requestPermission().timeout(
        const Duration(seconds: 10),
      );
      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (mounted) setState(() => _locationGranted = granted);
      if (granted) {
        LocationService.fetchAndSync().ignore();
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }

    if (mounted) setState(() => _loading = false);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _goHome();
  }

  void _skipAll() {
    // Just mark as asked locally, don't open the location dialog on skip
    StorageService.prefs.setBool('location_permission_asked', true);
    _goHome();
  }

  void _goHome() {
    if (!mounted) return;
    StorageService.setFirstLaunchComplete();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFF), Color(0xFFF5F0FF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 44),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    l10n.quickSetup,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    l10n.quickSetupSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Permission cards
                  _PermissionCard(
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    title: l10n.pushNotifications,
                    subtitle: l10n.pushNotificationsSubtitle,
                    granted: _notifGranted,
                  ),

                  const SizedBox(height: 14),

                  _PermissionCard(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: l10n.locationPermission,
                    subtitle: l10n.locationPermissionSubtitle,
                    granted: _locationGranted,
                  ),

                  const Spacer(flex: 3),

                  // Allow button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA)
                                  .withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  l10n.allowContinue,
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: _loading ? null : _skipAll,
                    child: Text(
                      l10n.skipForNow,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool granted;

  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: granted
              ? iconColor.withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
          width: granted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: granted
                ? Icon(Icons.check_circle_rounded,
                    key: const ValueKey('granted'),
                    color: iconColor,
                    size: 26)
                : const Icon(Icons.radio_button_unchecked_rounded,
                    key: ValueKey('pending'),
                    color: Color(0xFFD1D5DB),
                    size: 26),
          ),
        ],
      ),
    );
  }
}
