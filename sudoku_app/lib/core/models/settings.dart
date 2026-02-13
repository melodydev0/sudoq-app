import 'dart:convert';

/// App settings model
class AppSettings {
  final bool isDarkMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoRemoveNotes;
  final bool highlightSameNumbers;
  final bool highlightRowColumn;
  final bool showMistakes;
  final bool showTimer;
  final bool showRemainingNumbers;
  final String defaultDifficulty;
  final String
      languageCode; // Language code (en, zh, hi, es, fr, ar, bn, pt, ru, ja, tr)

  AppSettings({
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoRemoveNotes = true,
    this.highlightSameNumbers = true,
    this.highlightRowColumn = true,
    this.showMistakes = true,
    this.showTimer = true,
    this.showRemainingNumbers = true,
    this.defaultDifficulty = 'Easy',
    this.languageCode = '', // Empty means use system language
  });

  AppSettings copyWith({
    bool? isDarkMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoRemoveNotes,
    bool? highlightSameNumbers,
    bool? highlightRowColumn,
    bool? showMistakes,
    bool? showTimer,
    bool? showRemainingNumbers,
    String? defaultDifficulty,
    String? languageCode,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      highlightSameNumbers: highlightSameNumbers ?? this.highlightSameNumbers,
      highlightRowColumn: highlightRowColumn ?? this.highlightRowColumn,
      showMistakes: showMistakes ?? this.showMistakes,
      showTimer: showTimer ?? this.showTimer,
      showRemainingNumbers: showRemainingNumbers ?? this.showRemainingNumbers,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoRemoveNotes': autoRemoveNotes,
      'highlightSameNumbers': highlightSameNumbers,
      'highlightRowColumn': highlightRowColumn,
      'showMistakes': showMistakes,
      'showTimer': showTimer,
      'showRemainingNumbers': showRemainingNumbers,
      'defaultDifficulty': defaultDifficulty,
      'languageCode': languageCode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      autoRemoveNotes: json['autoRemoveNotes'] as bool? ?? true,
      highlightSameNumbers: json['highlightSameNumbers'] as bool? ?? true,
      highlightRowColumn: json['highlightRowColumn'] as bool? ?? true,
      showMistakes: json['showMistakes'] as bool? ?? true,
      showTimer: json['showTimer'] as bool? ?? true,
      showRemainingNumbers: json['showRemainingNumbers'] as bool? ?? true,
      defaultDifficulty: json['defaultDifficulty'] as String? ?? 'Easy',
      languageCode: json['languageCode'] as String? ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppSettings.fromJsonString(String jsonString) =>
      AppSettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
