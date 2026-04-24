import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

/// Types of cosmetic rewards
enum RewardType {
  theme, // Color themes for the app
  frame, // Profile/avatar frames
  effect, // Celebration effects
  numberStyle, // Number font styles
  title, // Special titles
}

/// Rarity levels for rewards
enum RewardRarity {
  common, // Easy to get
  uncommon, // Moderate effort
  rare, // Hard to get
  epic, // Very hard
  legendary, // Level 100 exclusive
}

/// Base class for all cosmetic rewards
class CosmeticReward {
  final String id;
  final String nameKey; // Localization key
  final String descriptionKey;
  final RewardType type;
  final RewardRarity rarity;
  final int unlockLevel;
  final String? unlockCondition; // Additional condition besides level
  final String previewAsset; // Icon or preview image
  final String? imagePath; // Optional PNG asset path (e.g. 'assets/frames/frame_gold.png')

  const CosmeticReward({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.type,
    required this.rarity,
    required this.unlockLevel,
    this.unlockCondition,
    required this.previewAsset,
    this.imagePath,
  });

  bool isUnlocked(int userLevel, List<String> unlockedRewards) {
    // If already unlocked through achievements/rewards, it's available
    if (unlockedRewards.contains(id)) return true;

    // If there's a special unlock condition (like season_top50, ranked_wins, etc.)
    // the item can ONLY be unlocked through that condition (must be in unlockedRewards)
    if (unlockCondition != null) {
      // For season-end rewards, check if the condition itself is in unlockedRewards
      return unlockedRewards.contains(unlockCondition);
    }

    // For items with no special condition, just check level
    return userLevel >= unlockLevel;
  }
}

/// Theme reward with actual color data
class ThemeReward extends CosmeticReward {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color gridColor;
  final Color cellHighlightColor;
  final Color textColor;
  final Color cellColor;
  final bool isDark;

  const ThemeReward({
    required super.id,
    required super.nameKey,
    required super.descriptionKey,
    required super.rarity,
    required super.unlockLevel,
    super.unlockCondition,
    required super.previewAsset,
    super.imagePath,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.gridColor,
    required this.cellHighlightColor,
    this.textColor = const Color(0xFF1A1A2E),
    this.cellColor = const Color(0xFFFFFFFF),
    this.isDark = false,
  }) : super(type: RewardType.theme);
}

/// Frame reward for profile
class FrameReward extends CosmeticReward {
  final List<Color> gradientColors;
  final double borderWidth;
  final bool isAnimated;
  final IconData? iconData;
  final bool hasGlow;
  final bool hasParticles;

  const FrameReward({
    required super.id,
    required super.nameKey,
    required super.descriptionKey,
    required super.rarity,
    required super.unlockLevel,
    super.unlockCondition,
    required super.previewAsset,
    super.imagePath,
    required this.gradientColors,
    this.borderWidth = 3.0,
    this.isAnimated = false,
    this.iconData,
    this.hasGlow = false,
    this.hasParticles = false,
  }) : super(type: RewardType.frame);
}

/// Celebration effect reward
class EffectReward extends CosmeticReward {
  final String effectType; // confetti, fireworks, stars, etc.
  final Duration duration;
  final IconData? iconData;
  final Color? primaryColor;
  final Color? secondaryColor;

  const EffectReward({
    required super.id,
    required super.nameKey,
    required super.descriptionKey,
    required super.rarity,
    required super.unlockLevel,
    super.unlockCondition,
    required super.previewAsset,
    super.imagePath,
    required this.effectType,
    this.duration = const Duration(seconds: 2),
    this.iconData,
    this.primaryColor,
    this.secondaryColor,
  }) : super(type: RewardType.effect);
}

/// All available rewards
class CosmeticRewards {
  // ========== GRID STYLES - Eye-friendly, no red conflict ==========
  static const List<ThemeReward> themes = [
    // 🎨 Classic - Default (Level 1)
    ThemeReward(
      id: 'theme_default',
      nameKey: 'gridStyleClassic',
      descriptionKey: 'gridStyleClassicDesc',
      rarity: RewardRarity.common,
      unlockLevel: 1,
      previewAsset: '🎨',
      imagePath: 'assets/themes/theme_default.png',
      primaryColor: Color(0xFF5C6BC0),
      secondaryColor: Color(0xFF7986CB),
      backgroundColor: Color(0xFFF8F9FF),
      gridColor: Color(0xFFE0E4F0),
      cellHighlightColor: Color(0xFFD1D9FF),
      textColor: Color(0xFF1A1A2E),
      cellColor: Color(0xFFFFFFFF),
    ),

    // 🌊 Ocean Blue - Level 10
    ThemeReward(
      id: 'theme_ocean',
      nameKey: 'gridStyleOcean',
      descriptionKey: 'gridStyleOceanDesc',
      rarity: RewardRarity.common,
      unlockLevel: 10,
      previewAsset: '🌊',
      imagePath: 'assets/themes/theme_ocean.png',
      primaryColor: Color(0xFF0077B6),
      secondaryColor: Color(0xFF00B4D8),
      backgroundColor: Color(0xFFE8F4F8),
      gridColor: Color(0xFFB8DCE8),
      cellHighlightColor: Color(0xFFA8D8EA),
      textColor: Color(0xFF003459),
      cellColor: Color(0xFFFFFFFF),
    ),

    // 🌲 Forest Green - Level 20
    ThemeReward(
      id: 'theme_forest',
      nameKey: 'gridStyleForest',
      descriptionKey: 'gridStyleForestDesc',
      rarity: RewardRarity.uncommon,
      unlockLevel: 20,
      previewAsset: '🌲',
      imagePath: 'assets/themes/theme_forest.png',
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF66BB6A),
      backgroundColor: Color(0xFFEDF7ED),
      gridColor: Color(0xFFD0E8D0),
      cellHighlightColor: Color(0xFFB8DCB8),
      textColor: Color(0xFF1B4D1B),
      cellColor: Color(0xFFFFFFFF),
    ),

    // 🔮 Mystic Purple - Level 30
    ThemeReward(
      id: 'theme_mystic',
      nameKey: 'gridStyleMystic',
      descriptionKey: 'gridStyleMysticDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 30,
      previewAsset: '🔮',
      imagePath: 'assets/themes/theme_mystic.png',
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFBA68C8),
      backgroundColor: Color(0xFFF8F0FF),
      gridColor: Color(0xFFE8D0F0),
      cellHighlightColor: Color(0xFFD8B8E8),
      textColor: Color(0xFF38006B),
      cellColor: Color(0xFFFFFFFF),
    ),

    // 🌈 Aurora - Level 40
    ThemeReward(
      id: 'theme_aurora',
      nameKey: 'gridStyleAurora',
      descriptionKey: 'gridStyleAuroraDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 40,
      previewAsset: '🌈',
      imagePath: 'assets/themes/theme_aurora.png',
      primaryColor: Color(0xFF00C853),
      secondaryColor: Color(0xFF00BFA5),
      backgroundColor: Color(0xFFF0FFF8),
      gridColor: Color(0xFFD0F0E0),
      cellHighlightColor: Color(0xFFB0E8D0),
      textColor: Color(0xFF004D40),
      cellColor: Color(0xFFFFFFFF),
    ),

    // 👑 Royal Gold - Level 50
    ThemeReward(
      id: 'theme_gold',
      nameKey: 'gridStyleGold',
      descriptionKey: 'gridStyleGoldDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 50,
      previewAsset: '👑',
      imagePath: 'assets/themes/theme_gold.png',
      primaryColor: Color(0xFFFFB300),
      secondaryColor: Color(0xFFFFD54F),
      backgroundColor: Color(0xFFFFFDF5),
      gridColor: Color(0xFFFFF0C8),
      cellHighlightColor: Color(0xFFFFE4A0),
      textColor: Color(0xFF5D4000),
      cellColor: Color(0xFFFFFFFF),
    ),

    // 💎 Diamond - Level 75 (LEGENDARY)
    ThemeReward(
      id: 'theme_diamond',
      nameKey: 'gridStyleDiamond',
      descriptionKey: 'gridStyleDiamondDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 75,
      previewAsset: '💎',
      imagePath: 'assets/themes/theme_diamond.png',
      primaryColor: Color(0xFF29B6F6),
      secondaryColor: Color(0xFF4FC3F7),
      backgroundColor: Color(0xFFF8FDFF),
      gridColor: Color(0xFFD8F0FA),
      cellHighlightColor: Color(0xFFC0E8F8),
      textColor: Color(0xFF01579B),
      cellColor: Color(0xFFFFFFFF),
    ),
  ];

  // ========== FRAMES ==========
  static List<FrameReward> frames = [
    // Basic Frame - Default
    const FrameReward(
      id: 'frame_basic',
      nameKey: 'frameBasic',
      descriptionKey: 'frameBasicDesc',
      rarity: RewardRarity.common,
      unlockLevel: 1,
      previewAsset: '⬜',
      imagePath: 'assets/frames/frame_basic.png',
      gradientColors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      iconData: Bootstrap.circle,
    ),

    // Bronze Frame - Level 10
    const FrameReward(
      id: 'frame_bronze',
      nameKey: 'frameBronze',
      descriptionKey: 'frameBronzeDesc',
      rarity: RewardRarity.common,
      unlockLevel: 10,
      previewAsset: '🥉',
      imagePath: 'assets/frames/frame_bronze.png',
      gradientColors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
      iconData: Bootstrap.award,
      hasGlow: true,
    ),

    // Silver Frame - Level 25
    const FrameReward(
      id: 'frame_silver',
      nameKey: 'frameSilver',
      descriptionKey: 'frameSilverDesc',
      rarity: RewardRarity.uncommon,
      unlockLevel: 25,
      previewAsset: '🥈',
      imagePath: 'assets/frames/frame_silver.png',
      gradientColors: [Color(0xFFC0C0C0), Color(0xFF808080)],
      iconData: FontAwesome.medal_solid,
      hasGlow: true,
      borderWidth: 3.5,
    ),

    // Gold Frame - Level 50
    const FrameReward(
      id: 'frame_gold',
      nameKey: 'frameGold',
      descriptionKey: 'frameGoldDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 50,
      previewAsset: '🥇',
      imagePath: 'assets/frames/frame_gold.png',
      gradientColors: [Color(0xFFFFD700), Color(0xFFDAA520)],
      iconData: Bootstrap.trophy_fill,
      hasGlow: true,
      isAnimated: true,
      borderWidth: 3.5,
    ),

    // Platinum Frame - Level 75
    const FrameReward(
      id: 'frame_platinum',
      nameKey: 'framePlatinum',
      descriptionKey: 'framePlatinumDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 75,
      previewAsset: '💫',
      imagePath: 'assets/frames/frame_platinum.png',
      gradientColors: [Color(0xFFE5E4E2), Color(0xFFB4B4B4), Color(0xFFE5E4E2)],
      iconData: FontAwesome.gem_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 4.0,
    ),

    // Rainbow Frame - Level 100 (LEGENDARY!)
    const FrameReward(
      id: 'frame_rainbow',
      nameKey: 'frameRainbow',
      descriptionKey: 'frameRainbowDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 100,
      previewAsset: '🌈',
      imagePath: 'assets/frames/frame_rainbow.png',
      gradientColors: [
        Color(0xFFFF0000),
        Color(0xFFFF7F00),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFF8B00FF),
      ],
      iconData: FontAwesome.crown_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 5.0,
    ),
  ];

  // ========== EFFECTS ==========
  static List<EffectReward> effects = [
    // Basic Sparkle - Default
    const EffectReward(
      id: 'effect_sparkle',
      nameKey: 'effectSparkle',
      descriptionKey: 'effectSparkleDesc',
      rarity: RewardRarity.common,
      unlockLevel: 1,
      previewAsset: '✨',
      imagePath: 'assets/effects/effect_sparkle.png',
      effectType: 'sparkle',
      iconData: Bootstrap.stars,
      primaryColor: Color(0xFFFFD700),
    ),

    // Confetti - Level 15
    const EffectReward(
      id: 'effect_confetti',
      nameKey: 'effectConfetti',
      descriptionKey: 'effectConfettiDesc',
      rarity: RewardRarity.uncommon,
      unlockLevel: 15,
      previewAsset: '🎊',
      imagePath: 'assets/effects/effect_confetti.png',
      effectType: 'confetti',
      duration: Duration(seconds: 3),
      iconData: FontAwesome.gift_solid,
      primaryColor: Color(0xFFFF4081),
      secondaryColor: Color(0xFF00BCD4),
    ),

    // Stars - Level 30
    const EffectReward(
      id: 'effect_stars',
      nameKey: 'effectStars',
      descriptionKey: 'effectStarsDesc',
      rarity: RewardRarity.uncommon,
      unlockLevel: 30,
      previewAsset: '⭐',
      imagePath: 'assets/effects/effect_stars.png',
      effectType: 'stars',
      iconData: FontAwesome.star_solid,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFFA000),
    ),

    // Fireworks - Level 45
    const EffectReward(
      id: 'effect_fireworks',
      nameKey: 'effectFireworks',
      descriptionKey: 'effectFireworksDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 45,
      previewAsset: '🎆',
      imagePath: 'assets/effects/effect_fireworks.png',
      effectType: 'fireworks',
      duration: Duration(seconds: 4),
      iconData: FontAwesome.burst_solid,
      primaryColor: Color(0xFFFF5722),
      secondaryColor: Color(0xFFFFEB3B),
    ),

    // Aurora - Level 60
    const EffectReward(
      id: 'effect_aurora',
      nameKey: 'effectAurora',
      descriptionKey: 'effectAuroraDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 60,
      previewAsset: '🌌',
      imagePath: 'assets/effects/effect_aurora.png',
      effectType: 'aurora',
      duration: Duration(seconds: 5),
      iconData: FontAwesome.wand_magic_sparkles_solid,
      primaryColor: Color(0xFF00BCD4),
      secondaryColor: Color(0xFF9C27B0),
    ),

    // Royal Celebration - Level 80
    const EffectReward(
      id: 'effect_royal',
      nameKey: 'effectRoyal',
      descriptionKey: 'effectRoyalDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 80,
      previewAsset: '👑',
      imagePath: 'assets/effects/effect_royal.png',
      effectType: 'royal',
      duration: Duration(seconds: 5),
      iconData: FontAwesome.crown_solid,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFF9C27B0),
    ),

    // Legendary Aura - Level 100 ✨🔥
    const EffectReward(
      id: 'effect_legendary',
      nameKey: 'effectLegendary',
      descriptionKey: 'effectLegendaryDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 100,
      previewAsset: '🌟',
      imagePath: 'assets/effects/effect_legendary.png',
      effectType: 'legendary',
      duration: Duration(seconds: 6),
      iconData: FontAwesome.sun_solid,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFF4500),
    ),
  ];

  // ========== RANKED FRAMES ==========
  static List<FrameReward> rankedFrames = [
    // Warrior Frame - 10 Ranked Wins
    const FrameReward(
      id: 'ranked_frame_warrior',
      nameKey: 'frameWarrior',
      descriptionKey: 'frameWarriorDesc',
      rarity: RewardRarity.uncommon,
      unlockLevel: 0,
      unlockCondition: 'ranked_10_wins',
      previewAsset: '⚔️',
      imagePath: 'assets/frames/ranked_frame_warrior.png',
      gradientColors: [Color(0xFF8B0000), Color(0xFFDC143C)],
      iconData: FontAwesome.shield_halved_solid,
      hasGlow: true,
    ),

    // Gladiator Frame - 50 Ranked Wins
    const FrameReward(
      id: 'ranked_frame_gladiator',
      nameKey: 'frameGladiator',
      descriptionKey: 'frameGladiatorDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 0,
      unlockCondition: 'ranked_50_wins',
      previewAsset: '🗡️',
      imagePath: 'assets/frames/ranked_frame_gladiator.png',
      gradientColors: [Color(0xFF4A0E0E), Color(0xFF8B0000), Color(0xFFDC143C)],
      iconData: FontAwesome.khanda_solid,
      borderWidth: 3.5,
      hasGlow: true,
      isAnimated: true,
    ),

    // Platinum Division Frame
    const FrameReward(
      id: 'ranked_frame_platinum',
      nameKey: 'framePlatinumRanked',
      descriptionKey: 'framePlatinumRankedDesc',
      rarity: RewardRarity.rare,
      unlockLevel: 0,
      unlockCondition: 'platinum_division',
      previewAsset: '💎',
      imagePath: 'assets/frames/ranked_frame_platinum.png',
      gradientColors: [Color(0xFFE5E4E2), Color(0xFF87CEEB), Color(0xFFE5E4E2)],
      iconData: FontAwesome.shield_solid,
      isAnimated: true,
      hasGlow: true,
    ),

    // Diamond Division Frame ✨
    const FrameReward(
      id: 'ranked_frame_diamond',
      nameKey: 'frameDiamondRanked',
      descriptionKey: 'frameDiamondRankedDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 0,
      unlockCondition: 'diamond_division',
      previewAsset: '💠',
      imagePath: 'assets/frames/ranked_frame_diamond.png',
      gradientColors: [Color(0xFF00BFFF), Color(0xFF1E90FF), Color(0xFF00BFFF)],
      iconData: FontAwesome.gem_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 3.5,
    ),

    // Master Division Frame 👑
    const FrameReward(
      id: 'ranked_frame_master',
      nameKey: 'frameMasterRanked',
      descriptionKey: 'frameMasterRankedDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 0,
      unlockCondition: 'master_division',
      previewAsset: '👑',
      imagePath: 'assets/frames/ranked_frame_master.png',
      gradientColors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
      iconData: FontAwesome.crown_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 4.0,
    ),

    // Grandmaster Division Frame 🔮
    const FrameReward(
      id: 'ranked_frame_grandmaster',
      nameKey: 'frameGrandmasterRanked',
      descriptionKey: 'frameGrandmasterRankedDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 0,
      unlockCondition: 'grandmaster_division',
      previewAsset: '🔮',
      imagePath: 'assets/frames/ranked_frame_grandmaster.png',
      gradientColors: [Color(0xFF9400D3), Color(0xFF8A2BE2), Color(0xFF9400D3)],
      iconData: FontAwesome.hat_wizard_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 4.5,
    ),

    // Champion Division Frame 🏆 - ULTIMATE!
    const FrameReward(
      id: 'ranked_frame_champion',
      nameKey: 'frameChampionRanked',
      descriptionKey: 'frameChampionRankedDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 0,
      unlockCondition: 'champion_division',
      previewAsset: '🏆',
      imagePath: 'assets/frames/ranked_frame_champion.png',
      gradientColors: [
        Color(0xFFFFD700),
        Color(0xFFFF4500),
        Color(0xFFFFD700),
        Color(0xFFFF4500)
      ],
      iconData: Bootstrap.trophy_fill,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 5.0,
    ),

    // Top 50 Season Frame
    const FrameReward(
      id: 'ranked_frame_top50',
      nameKey: 'frameTop50',
      descriptionKey: 'frameTop50Desc',
      rarity: RewardRarity.rare,
      unlockLevel: 0,
      unlockCondition: 'season_top50',
      previewAsset: '🏅',
      imagePath: 'assets/frames/ranked_frame_top50.png',
      gradientColors: [Color(0xFF4169E1), Color(0xFF1E90FF)],
      iconData: Bootstrap.award_fill,
      hasGlow: true,
    ),

    // Top 10 Pro Frame
    const FrameReward(
      id: 'ranked_frame_pro',
      nameKey: 'framePro',
      descriptionKey: 'frameProDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 0,
      unlockCondition: 'season_top10',
      previewAsset: '🥉',
      imagePath: 'assets/frames/ranked_frame_pro.png',
      gradientColors: [Color(0xFFCD7F32), Color(0xFFFFD700), Color(0xFFCD7F32)],
      iconData: FontAwesome.ranking_star_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
    ),

    // Top 3 Elite Frame ⚡
    const FrameReward(
      id: 'ranked_frame_elite',
      nameKey: 'frameElite',
      descriptionKey: 'frameEliteDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 0,
      unlockCondition: 'season_top3',
      previewAsset: '🥈',
      imagePath: 'assets/frames/ranked_frame_elite.png',
      gradientColors: [Color(0xFFC0C0C0), Color(0xFFFFD700), Color(0xFFC0C0C0)],
      iconData: FontAwesome.bolt_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 4.5,
    ),

    // #1 Legend Frame 👑🔥 - THE ULTIMATE!
    const FrameReward(
      id: 'ranked_frame_legend',
      nameKey: 'frameLegend',
      descriptionKey: 'frameLegendDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 0,
      unlockCondition: 'season_first',
      previewAsset: '🥇',
      imagePath: 'assets/frames/ranked_frame_legend.png',
      gradientColors: [
        Color(0xFFFFD700),
        Color(0xFFFF6347),
        Color(0xFFFFD700),
        Color(0xFF00CED1),
        Color(0xFFFFD700)
      ],
      iconData: FontAwesome.chess_king_solid,
      isAnimated: true,
      hasGlow: true,
      hasParticles: true,
      borderWidth: 6.0,
    ),
  ];

  // ========== RANKED THEMES (Exclusive Ranked-only themes) ==========
  static const List<ThemeReward> rankedThemes = [
    // 🏆 Champion's Glory - Master Division (Epic)
    // Premium cream/gold theme - luxurious, eye-friendly, warm tones
    ThemeReward(
      id: 'ranked_theme_champion',
      nameKey: 'themeChampion',
      descriptionKey: 'themeChampionDesc',
      rarity: RewardRarity.epic,
      unlockLevel: 0,
      unlockCondition: 'master_division',
      previewAsset: '🏆',
      imagePath: 'assets/themes/ranked_theme_champion.png',
      primaryColor: Color(0xFFB8860B), // Dark goldenrod - premium accent
      secondaryColor: Color(0xFFD4A84B), // Muted gold
      backgroundColor: Color(0xFFFFFDF5), // Warm cream white
      gridColor: Color(0xFFF5ECD7), // Soft cream
      cellHighlightColor: Color(0xFFEDE4C9), // Highlighted cream
      textColor: Color(0xFF5D4E37), // Warm brown - easy to read
      cellColor: Color(0xFFFFFEFA), // Pure cream white
      isDark: false,
    ),

    // 👑 Grandmaster Prestige - Champion Division (Legendary)
    // Ultra premium silver/platinum theme - elegant, sophisticated, eye-friendly
    ThemeReward(
      id: 'ranked_theme_grandmaster',
      nameKey: 'themeGrandmaster',
      descriptionKey: 'themeGrandmasterDesc',
      rarity: RewardRarity.legendary,
      unlockLevel: 0,
      unlockCondition: 'champion_division',
      previewAsset: '👑',
      imagePath: 'assets/themes/ranked_theme_grandmaster.png',
      primaryColor: Color(0xFF6B5B95), // Ultra violet - premium accent
      secondaryColor: Color(0xFF8E7CC3), // Soft lavender
      backgroundColor: Color(0xFFF8F7FC), // Very light lavender white
      gridColor: Color(0xFFEDE8F5), // Soft lavender gray
      cellHighlightColor: Color(0xFFE0D8F0), // Highlighted lavender
      textColor: Color(0xFF3D3551), // Deep purple gray - easy to read
      cellColor: Color(0xFFFDFCFF), // Pure white with hint of lavender
      isDark: false,
    ),
  ];

  /// Get all rewards (including ranked rewards)
  static List<CosmeticReward> get allRewards => [
        ...themes,
        ...frames,
        ...rankedFrames,
        ...effects,
        ...rankedThemes,
      ];

  /// Get rewards unlocked at a specific level
  static List<CosmeticReward> getRewardsForLevel(int level) {
    return allRewards.where((r) => r.unlockLevel == level).toList();
  }

  /// Get all rewards up to a level
  static List<CosmeticReward> getUnlockedRewards(int level) {
    return allRewards.where((r) => r.unlockLevel <= level).toList();
  }

  /// Get next reward to unlock
  static CosmeticReward? getNextReward(int currentLevel) {
    final upcoming = allRewards
        .where((r) => r.unlockLevel > currentLevel)
        .toList()
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Get reward by ID
  static CosmeticReward? getRewardById(String id) {
    try {
      return allRewards.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Level milestone rewards (special rewards at milestone levels)
class LevelMilestones {
  static const Map<int, List<String>> milestoneRewards = {
    10: ['theme_ocean', 'frame_bronze'],
    15: ['effect_confetti'],
    20: ['theme_forest'],
    25: ['frame_silver'],
    30: ['theme_mystic', 'effect_stars'],
    40: ['theme_aurora'],
    45: ['effect_fireworks'],
    50: ['theme_gold', 'frame_gold'],
    60: ['effect_aurora'],
    75: ['theme_diamond', 'frame_platinum'],
    80: ['effect_royal'],
    100: ['frame_rainbow', 'effect_legendary'],
  };

  static List<String> getRewardsForLevel(int level) {
    return milestoneRewards[level] ?? [];
  }

  static bool isMilestoneLevel(int level) {
    return milestoneRewards.containsKey(level);
  }

  static int? getNextMilestone(int currentLevel) {
    final milestones = milestoneRewards.keys.toList()..sort();
    for (var m in milestones) {
      if (m > currentLevel) return m;
    }
    return null;
  }
}
