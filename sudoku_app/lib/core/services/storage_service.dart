import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/game_state.dart';
import '../models/statistics.dart';
import '../models/settings.dart';
import '../models/daily_challenge.dart';

/// Service for managing local storage
class StorageService {
  static SharedPreferences? _prefs;

  /// Initialize the storage service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== First Launch ====================

  static bool isFirstLaunch() {
    return prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunchComplete() async {
    await prefs.setBool(AppConstants.keyFirstLaunch, false);
  }

  // ==================== Experience Level ====================

  static String? getExperienceLevel() {
    return prefs.getString(AppConstants.keyExperienceLevel);
  }

  static Future<void> setExperienceLevel(String level) async {
    await prefs.setString(AppConstants.keyExperienceLevel, level);
  }

  // ==================== Current Game ====================

  static GameState? getCurrentGame() {
    final json = prefs.getString(AppConstants.keyCurrentGame);
    if (json == null) return null;
    try {
      return GameState.fromJsonString(json);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCurrentGame(GameState? game) async {
    if (game == null) {
      await prefs.remove(AppConstants.keyCurrentGame);
    } else {
      await prefs.setString(AppConstants.keyCurrentGame, game.toJsonString());
    }
  }

  static Future<void> clearCurrentGame() async {
    await prefs.remove(AppConstants.keyCurrentGame);
  }

  // ==================== Statistics ====================

  static Statistics getStatistics() {
    final json = prefs.getString(AppConstants.keyStatistics);
    if (json == null) return Statistics();
    try {
      return Statistics.fromJsonString(json);
    } catch (e) {
      return Statistics();
    }
  }

  static Future<void> saveStatistics(Statistics stats) async {
    await prefs.setString(AppConstants.keyStatistics, stats.toJsonString());
  }

  // ==================== Settings ====================

  static AppSettings getSettings() {
    final json = prefs.getString(AppConstants.keySettings);
    if (json == null) return AppSettings();
    try {
      return AppSettings.fromJsonString(json);
    } catch (e) {
      return AppSettings();
    }
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await prefs.setString(AppConstants.keySettings, settings.toJsonString());
  }

  // ==================== Ads Free ====================

  static bool isAdsFree() {
    return prefs.getBool(AppConstants.keyAdsFree) ?? false;
  }

  static Future<void> setAdsFree(bool value) async {
    await prefs.setBool(AppConstants.keyAdsFree, value);
  }

  // ==================== Sound Settings ====================

  static bool getSoundEnabled() {
    return prefs.getBool(AppConstants.keySoundEnabled) ?? true;
  }

  static Future<void> setSoundEnabled(bool value) async {
    await prefs.setBool(AppConstants.keySoundEnabled, value);
  }

  // ==================== Daily Challenge ====================

  static DailyChallengeHistory getDailyChallengeHistory() {
    final json = prefs.getString(AppConstants.keyDailyChallenge);
    if (json == null) return DailyChallengeHistory();
    try {
      return DailyChallengeHistory.fromJsonString(json);
    } catch (e) {
      return DailyChallengeHistory();
    }
  }

  static Future<void> saveDailyChallengeHistory(
      DailyChallengeHistory history) async {
    await prefs.setString(
        AppConstants.keyDailyChallenge, history.toJsonString());
  }

  // ==================== Favorites ====================

  static List<String> getFavorites() {
    return prefs.getStringList(AppConstants.keyFavorites) ?? [];
  }

  static Future<void> addFavorite(String puzzleJson) async {
    final favorites = getFavorites();
    favorites.add(puzzleJson);
    await prefs.setStringList(AppConstants.keyFavorites, favorites);
  }

  static Future<void> removeFavorite(int index) async {
    final favorites = getFavorites();
    if (index >= 0 && index < favorites.length) {
      favorites.removeAt(index);
      await prefs.setStringList(AppConstants.keyFavorites, favorites);
    }
  }

  // ==================== Achievements ====================

  static Map<String, int> getAchievementProgress() {
    final json = prefs.getString(AppConstants.keyAchievements);
    if (json == null) return {};
    try {
      final Map<String, dynamic> decoded =
          Map<String, dynamic>.from(Uri.splitQueryString(json));
      return decoded
          .map((k, v) => MapEntry(k, int.tryParse(v.toString()) ?? 0));
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveAchievementProgress(Map<String, int> progress) async {
    final encoded =
        progress.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefs.setString(AppConstants.keyAchievements, encoded);
  }

  // ==================== Utility ====================

  static Future<void> clearAll() async {
    await prefs.clear();
  }
}
