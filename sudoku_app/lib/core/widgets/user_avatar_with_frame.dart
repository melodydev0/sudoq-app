import 'package:flutter/material.dart';
import '../models/cosmetic_rewards.dart';
import '../services/auth_service.dart';
import '../services/level_service.dart';
import '../utils/responsive_utils.dart';
import 'animated_frame.dart';

/// Reusable user avatar widget with frame and country flag
/// Use this widget across all screens for consistent avatar display
class UserAvatarWithFrame extends StatelessWidget {
  final double size;
  final String? photoUrl;
  final String displayName;
  final String? frameId;
  final String? countryCode;
  final String? avatarAsset;
  final bool showOnlineBadge;
  final bool showCountryFlag;
  final bool showAnimation;
  final Color? borderColor;

  const UserAvatarWithFrame({
    super.key,
    this.size = 64,
    this.photoUrl,
    required this.displayName,
    this.frameId,
    this.countryCode,
    this.avatarAsset,
    this.showOnlineBadge = false,
    this.showCountryFlag = true,
    this.showAnimation = true,
    this.borderColor,
  });

  /// Factory constructor for current user
  factory UserAvatarWithFrame.currentUser({
    double size = 64,
    bool showOnlineBadge = false,
    bool showCountryFlag = true,
    bool showAnimation = true,
  }) {
    final frameId = LevelService.selectedFrameId;
    return UserAvatarWithFrame(
      size: size,
      photoUrl: AuthService.photoUrl,
      displayName: AuthService.displayName,
      frameId: frameId,
      countryCode: AuthService.getCountryCode(),
      showOnlineBadge: showOnlineBadge,
      showCountryFlag: showCountryFlag,
      showAnimation: showAnimation,
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    
    final effectiveFrameId = frameId ?? '';
    FrameReward? frame;
    
    if (effectiveFrameId.isNotEmpty && effectiveFrameId != 'frame_basic') {
      // Check normal frames
      try {
        frame = CosmeticRewards.frames.firstWhere((f) => f.id == effectiveFrameId);
      } catch (_) {}
      
      // Check ranked frames if not found
      if (frame == null) {
        try {
          frame = CosmeticRewards.rankedFrames.firstWhere((f) => f.id == effectiveFrameId);
        } catch (_) {}
      }
    }

    // Avatar size should match the frame size (like _buildFramedAvatar does)
    final avatarSize = size;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar with frame - show frame icon when frame is selected
        AnimatedAvatarFrame(
          frame: frame,
          size: size,
          showAnimation: showAnimation,
          child: _buildAvatarContent(avatarSize, frame),
        ),
        
        // Online badge
        if (showOnlineBadge)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'ONLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Country flag
        if (showCountryFlag && countryCode != null && countryCode!.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _getFlag(countryCode!),
                style: TextStyle(fontSize: (size * 0.2).sp),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent(double avatarSize, FrameReward? frame) {
    if (avatarAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(avatarSize * 0.25),
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Transform.scale(
            scale: 1.35,
            child: Image.asset(
              avatarAsset!,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultAvatar(avatarSize),
            ),
          ),
        ),
      );
    }

    if (frame != null) {
      if (frame.imagePath != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(avatarSize * 0.25),
          child: Image.asset(
            frame.imagePath!,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFrameIconFallback(avatarSize, frame);
            },
          ),
        );
      }
      return _buildFrameIconFallback(avatarSize, frame);
    }
    
    return _buildDefaultAvatar(avatarSize);
  }

  Widget _buildDefaultAvatar(double avatarSize) {
    final rankInfo = LevelService.levelData.rank;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(avatarSize * 0.25),
        border: borderColor != null 
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: rankInfo.imagePath != null
            ? Image.asset(
                rankInfo.imagePath!,
                width: avatarSize * 0.55,
                height: avatarSize * 0.55,
                errorBuilder: (_, __, ___) => Text(
                  rankInfo.icon,
                  style: TextStyle(fontSize: avatarSize * 0.5),
                ),
              )
            : Text(
                rankInfo.icon,
                style: TextStyle(fontSize: avatarSize * 0.5),
              ),
      ),
    );
  }

  Widget _buildFrameIconFallback(double avatarSize, FrameReward frame) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: frame.gradientColors,
        ),
        borderRadius: BorderRadius.circular(avatarSize * 0.25),
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
          size: avatarSize * 0.5,
        ),
      ),
    );
  }

  String _getFlag(String code) {
    if (code.length != 2) return '🌍';
    final upperCode = code.toUpperCase();
    final firstLetter = upperCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = upperCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([firstLetter, secondLetter]);
  }
}
