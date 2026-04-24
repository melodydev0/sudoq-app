import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Service for managing game sound effects
/// Uses player pool to prevent race conditions with rapid sound calls
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isInitialized = false;
  bool _soundEnabled = true;

  // Pool of players to handle concurrent sounds
  static const int _poolSize = 4;
  final List<AudioPlayer> _playerPool = [];
  int _currentPlayerIndex = 0;

  /// Initialize sound service
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('[SoundService] Already initialized');
      return;
    }

    try {
      _soundEnabled = StorageService.getSoundEnabled();
      debugPrint('[SoundService] Sound enabled: $_soundEnabled');

      // Configure audio context to allow mixing with other apps (YouTube, music)
      final ctx = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {},
        ),
      );
      AudioPlayer.global.setAudioContext(ctx);
      
      // Create pool of players
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setVolume(1.0);
        _playerPool.add(player);
      }

      _isInitialized = true;
      debugPrint('[SoundService] Initialized with $_poolSize players (mixing enabled)');
    } catch (e) {
      debugPrint('[SoundService] Init error: $e');
      _isInitialized = true;
    }
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

  /// Play sound when game is lost (3 mistakes, opponent wins, etc.)
  void playGameLost() => _playSound('sounds/game_lost.mp3');

  /// Play victory sound on result/win screen
  void playVictory() => _playSound('sounds/victory.mp3');

  /// Play rank-up / league promotion sound
  void playRankUp() => _playSound('sounds/rank_up.mp3');

  /// Play sound when hint or fast pencil button is tapped
  void playHintFastPencil() => _playSound('sounds/hint_fastpencil.ogg');

  /// Core play method - uses round-robin player pool
  /// Runs completely in background, never blocks UI
  void _playSound(String assetPath) {
    if (!_soundEnabled) {
      debugPrint('[SoundService] Sound disabled, skipping: $assetPath');
      return;
    }
    if (_playerPool.isEmpty) {
      debugPrint('[SoundService] Player pool empty, skipping: $assetPath');
      return;
    }

    // Get next player in round-robin fashion
    final player = _playerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;

    // Fire and forget - stop current sound on this player and play new one
    player.stop().then((_) {
      player.play(AssetSource(assetPath)).then((_) {
        debugPrint('[SoundService] Playing on player $_currentPlayerIndex: $assetPath');
      }).catchError((e) {
        debugPrint('[SoundService] Error playing $assetPath: $e');
      });
    }).catchError((e) {
      debugPrint('[SoundService] Error stopping before play: $e');
    });
  }

  /// Dispose service
  void dispose() {
    for (final player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    _currentPlayerIndex = 0;
    _isInitialized = false;
  }
}
