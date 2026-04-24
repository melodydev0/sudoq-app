import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Countdown overlay for battle game (3-2-1-GO).
class BattleCountdownOverlay extends StatelessWidget {
  final int countdown;

  const BattleCountdownOverlay({super.key, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              countdown > 0 ? '$countdown' : AppLocalizations.of(context).battleGo,
              style: TextStyle(
                fontSize: 80.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.w),
            Text(
              AppLocalizations.of(context).getReady,
              style: TextStyle(
                fontSize: 24.sp,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
