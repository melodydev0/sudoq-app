import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_system.dart';
import '../models/cosmetic_rewards.dart';

/// Service for managing user level, XP, and rewards
class LevelService {
  static const String _levelDataKey = 'user_level_data';
  static const String _selectedThemeKey = 'selected_theme';
  static const String _selectedFrameKey = 'selected_frame';
  static const String _selectedEffectKey = 'selected_effect';

  static SharedPreferences? _prefs;
  static UserLevelData? _cachedData;

  /// Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    await _checkSeasonReset();
  }

  /// Load user level data from storage
  static Future<void> _loadData() async {
    final jsonStr = _prefs?.getString(_levelDataKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedData = UserLevelData.fromJson(json);
      } catch (e) {
        _cachedData = UserLevelData();
      }
    } else {
      _cachedData = UserLevelData();
    }
  }

  /// Save user level data to storage
  static Future<void> _saveData() async {
    if (_cachedData != null) {
      final jsonStr = jsonEncode(_cachedData!.toJson());
      await _prefs?.setString(_levelDataKey, jsonStr);
    }
  }

  /// Check if we need to reset for a new season
  static Future<void> _checkSeasonReset() async {
    final currentSeason = Season.getCurrentSeason();
    if (_cachedData != null &&
        _cachedData!.seasonNumber != currentSeason.seasonNumber) {
      _cachedData = _cachedData!.resetForNewSeason(currentSeason.seasonNumber);
      await _saveData();
    }
  }

  /// Get current user level data
  static UserLevelData get levelData => _cachedData ?? UserLevelData();

  /// Get current season
  static Season get currentSeason => Season.getCurrentSeason();

  /// Add XP after completing a game.
  /// Returns the new level data AND the daily streak bonus XP granted this game
  /// (0 if already claimed today or streak is 0).
  static Future<({UserLevelData levelData, int dailyStreakXp})> addGameXp({
    required String difficulty,
    required Duration completionTime,
    required int mistakes,
    required bool isDailyChallenge,
    required bool isRanked,
    int score = 0,
    int maxCombo = 0,
    int fastSolves = 0,
    double performanceMultiplier = 1.0,
  }) async {
    final previousData = levelData;

    // Calculate game XP based on performance
    var xp = XpMultipliers.calculateXp(
      difficulty: difficulty,
      completionTime: completionTime,
      mistakes: mistakes,
      isDailyChallenge: isDailyChallenge,
      isRanked: isRanked,
      streakDays: previousData.streakDays,
      score: score,
      maxCombo: maxCombo,
      fastSolves: fastSolves,
    );

    xp = (xp * performanceMultiplier).round();

    // Add XP and update streak
    _cachedData = previousData.addXp(xp);

    // Daily streak reward — granted only on the first game of each day
    int dailyStreakXp = 0;
    if (_cachedData!.streakDays > 0 &&
        previousData.isStreakRewardAvailableToday) {
      dailyStreakXp =
          XpMultipliers.calculateDailyStreakXp(_cachedData!.streakDays);
      _cachedData = _cachedData!.copyWith(
        totalXp: _cachedData!.totalXp + dailyStreakXp,
        seasonXp: _cachedData!.seasonXp + dailyStreakXp,
        lastStreakRewardDate: DateTime.now(),
      );
    }

    // Check for new unlocks
    final previousLevel = previousData.level;
    final newLevel = _cachedData!.level;

    if (newLevel > previousLevel) {
      final newUnlocks = <String>[];
      for (int level = previousLevel + 1; level <= newLevel; level++) {
        final rewards = CosmeticRewards.getRewardsForLevel(level);
        newUnlocks.addAll(rewards.map((r) => r.id));

        final milestones = LevelMilestones.getRewardsForLevel(level);
        newUnlocks.addAll(milestones);
      }

      if (newUnlocks.isNotEmpty) {
        _cachedData = _cachedData!.copyWith(
          unlockedRewards: [..._cachedData!.unlockedRewards, ...newUnlocks],
        );
      }
    }

    await _saveData();
    return (levelData: _cachedData!, dailyStreakXp: dailyStreakXp);
  }

  /// Calculate XP that would be earned (for preview) – same params as addGameXp for accuracy
  static int previewXp({
    required String difficulty,
    required Duration completionTime,
    required int mistakes,
    required bool isDailyChallenge,
    required bool isRanked,
    int score = 0,
    int maxCombo = 0,
    int fastSolves = 0,
  }) {
    return XpMultipliers.calculateXp(
      difficulty: difficulty,
      completionTime: completionTime,
      mistakes: mistakes,
      isDailyChallenge: isDailyChallenge,
      isRanked: isRanked,
      streakDays: levelData.streakDays,
      score: score,
      maxCombo: maxCombo,
      fastSolves: fastSolves,
    );
  }

  /// Add bonus XP (from achievements, etc.)
  static Future<UserLevelData> addBonusXp(int bonusXp) async {
    if (bonusXp <= 0) return levelData;

    final previousData = levelData;

    // Add XP without updating streak
    _cachedData = previousData.addXp(bonusXp, updateStreak: false);

    // Check for new unlocks
    final previousLevel = previousData.level;
    final newLevel = _cachedData!.level;

    if (newLevel > previousLevel) {
      // Unlock new rewards
      final newUnlocks = <String>[];
      for (int level = previousLevel + 1; level <= newLevel; level++) {
        final rewards = CosmeticRewards.getRewardsForLevel(level);
        newUnlocks.addAll(rewards.map((r) => r.id));

        // Add milestone rewards
        final milestones = LevelMilestones.getRewardsForLevel(level);
        newUnlocks.addAll(milestones);
      }

      if (newUnlocks.isNotEmpty) {
        _cachedData = _cachedData!.copyWith(
          unlockedRewards: [..._cachedData!.unlockedRewards, ...newUnlocks],
        );
      }
    }

    await _saveData();
    return _cachedData!;
  }

  /// Get unlocked themes
  static List<ThemeReward> getUnlockedThemes() {
    final level = levelData.level;
    return CosmeticRewards.themes
        .where((t) => t.isUnlocked(level, levelData.unlockedRewards))
        .toList();
  }

  /// Get unlocked frames
  static List<FrameReward> getUnlockedFrames() {
    final level = levelData.level;
    return CosmeticRewards.frames
        .where((f) => f.isUnlocked(level, levelData.unlockedRewards))
        .toList();
  }

  /// Get unlocked effects
  static List<EffectReward> getUnlockedEffects() {
    final level = levelData.level;
    return CosmeticRewards.effects
        .where((e) => e.isUnlocked(level, levelData.unlockedRewards))
        .toList();
  }

  // ========== SELECTED COSMETICS ==========

  /// Get selected theme ID
  static String get selectedThemeId {
    return _prefs?.getString(_selectedThemeKey) ?? 'theme_default';
  }

  /// Set selected theme
  static Future<void> setSelectedTheme(String themeId) async {
    await _prefs?.setString(_selectedThemeKey, themeId);
  }

  /// Get selected theme
  static ThemeReward? get selectedTheme {
    final id = selectedThemeId;
    try {
      // First check normal themes
      return CosmeticRewards.themes.firstWhere((t) => t.id == id);
    } catch (_) {
      // Then check ranked themes
      try {
        return CosmeticRewards.rankedThemes.firstWhere((t) => t.id == id);
      } catch (_) {
        return CosmeticRewards.themes.first;
      }
    }
  }

  /// Get selected frame ID
  static String get selectedFrameId {
    return _prefs?.getString(_selectedFrameKey) ?? 'frame_basic';
  }

  /// Set selected frame
  static Future<void> setSelectedFrame(String frameId) async {
    await _prefs?.setString(_selectedFrameKey, frameId);
  }

  /// Get selected frame
  static FrameReward? get selectedFrame {
    final id = selectedFrameId;
    try {
      return CosmeticRewards.frames.firstWhere((f) => f.id == id);
    } catch (e) {
      return CosmeticRewards.frames.first;
    }
  }

  /// Get selected effect ID
  static String get selectedEffectId {
    return _prefs?.getString(_selectedEffectKey) ?? 'effect_sparkle';
  }

  /// Set selected effect
  static Future<void> setSelectedEffect(String effectId) async {
    await _prefs?.setString(_selectedEffectKey, effectId);
  }

  /// Get selected effect
  static EffectReward? get selectedEffect {
    final id = selectedEffectId;
    try {
      return CosmeticRewards.effects.firstWhere((e) => e.id == id);
    } catch (e) {
      return CosmeticRewards.effects.first;
    }
  }

  // ========== UTILITY ==========

  /// Add specific reward IDs to the unlocked list (for daily/badge rewards)
  static Future<void> addUnlockedRewards(List<String> rewardIds) async {
    if (rewardIds.isEmpty) return;
    final current = _cachedData ?? UserLevelData();
    final existing = Set<String>.from(current.unlockedRewards);
    final newIds = rewardIds.where((id) => !existing.contains(id)).toList();
    if (newIds.isEmpty) return;
    _cachedData = current.copyWith(
      unlockedRewards: [...current.unlockedRewards, ...newIds],
    );
    await _saveData();
  }

  /// Check if a reward is unlocked
  static bool isRewardUnlocked(String rewardId) {    final reward = CosmeticRewards.getRewardById(rewardId);
    if (reward == null) return false;
    return reward.isUnlocked(levelData.level, levelData.unlockedRewards);
  }

  /// Get progress to next milestone
  static int? get nextMilestone =>
      LevelMilestones.getNextMilestone(levelData.level);

  /// Get next reward preview
  static CosmeticReward? get nextReward =>
      CosmeticRewards.getNextReward(levelData.level);

  /// Reset all level data (for testing)
  static Future<void> resetLevelData() async {
    _cachedData = UserLevelData();
    await _saveData();
    await _prefs?.remove(_selectedThemeKey);
    await _prefs?.remove(_selectedFrameKey);
    await _prefs?.remove(_selectedEffectKey);
  }

  /// Set to max level (for testing)
  static Future<void> setMaxLevel() async {
    // Calculate XP needed for level 100
    final xpForLevel100 = LevelConstants.totalXpForLevel(100) + 1000;

    // Unlock all rewards
    final allRewards = <String>[];
    for (int level = 1; level <= 100; level++) {
      final rewards = CosmeticRewards.getRewardsForLevel(level);
      allRewards.addAll(rewards.map((r) => r.id));
      final milestones = LevelMilestones.getRewardsForLevel(level);
      allRewards.addAll(milestones);
    }

    _cachedData = UserLevelData(
      totalXp: xpForLevel100,
      seasonXp: xpForLevel100,
      seasonNumber: Season.getCurrentSeason().seasonNumber,
      streakDays: 30,
      lastPlayedDate: DateTime.now(),
      unlockedRewards: allRewards.toSet().toList(),
    );
    await _saveData();
  }

  /// Export data as JSON (for future cloud sync)
  static String exportData() {
    return jsonEncode({
      'levelData': levelData.toJson(),
      'selectedTheme': selectedThemeId,
      'selectedFrame': selectedFrameId,
      'selectedEffect': selectedEffectId,
    });
  }

  /// Import data from JSON (for future cloud sync)
  static Future<void> importData(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data.containsKey('levelData')) {
        _cachedData =
            UserLevelData.fromJson(data['levelData'] as Map<String, dynamic>);
        await _saveData();
      }

      if (data.containsKey('selectedTheme')) {
        await setSelectedTheme(data['selectedTheme'] as String);
      }
      if (data.containsKey('selectedFrame')) {
        await setSelectedFrame(data['selectedFrame'] as String);
      }
      if (data.containsKey('selectedEffect')) {
        await setSelectedEffect(data['selectedEffect'] as String);
      }
    } catch (e) {
      // Ignore import errors
    }
  }
}
