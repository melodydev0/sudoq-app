import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

/// Service for managing game sound effects
/// Uses single player - new sound stops previous one
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isInitialized = false;
  bool _soundEnabled = true;

  // Single player - new sound cancels previous
  AudioPlayer? _player;

  /// Initialize sound service
  Future<void> init() async {
    if (_isInitialized) return;

    _soundEnabled = StorageService.getSoundEnabled();
    _player = AudioPlayer();
    await _player!.setPlayerMode(PlayerMode.mediaPlayer);
    await _player!.setVolume(1.0);

    _isInitialized = true;
  }

  /// Check if sound is enabled
  bool get isSoundEnabled => _soundEnabled;

  /// Enable or disable sounds
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await StorageService.setSoundEnabled(enabled);
  }

  /// Play sound when a new game starts
  void playGameStart() => _playSound('sounds/game_start.mp3');

  /// Play sound when user enters a correct number
  void playCorrectInput() => _playSound('sounds/correct_input.wav');

  /// Play sound when user enters a wrong number
  void playWrongInput() => _playSound('sounds/wrong_input.wav');

  /// Play sound when a row is completed
  void playRowComplete() => _playSound('sounds/row_complete.wav');

  /// Play sound when a column is completed
  void playColumnComplete() => _playSound('sounds/column_complete.wav');

  /// Play sound when a 3x3 box is completed
  void playBoxComplete() => _playSound('sounds/box_complete.mp3');

  /// Play sound when the entire game (9x9) is completed
  void playGameComplete() => _playSound('sounds/game_complete.mp3');

  /// Play victory sound on result/win screen
  void playVictory() => _playSound('sounds/victory.mp3');

  /// Play sound when hint or fast pencil button is tapped
  void playHintFastPencil() => _playSound('sounds/hint_fastpencil.ogg');

  /// Core play method - stops previous sound, plays new one
  /// Runs completely in background, never blocks UI
  void _playSound(String assetPath) {
    if (!_soundEnabled || _player == null) return;

    // Fire and forget - no await, no UI blocking
    _player!.stop().then((_) {
      _player!.play(AssetSource(assetPath)).catchError((_) {});
    }).catchError((_) {});
  }

  /// Dispose service
  void dispose() {
    _player?.dispose();
    _player = null;
    _isInitialized = false;
  }
}
