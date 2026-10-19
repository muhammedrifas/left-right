import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../services/save_manager.dart';

class SoundManager {
  static final SoundManager instance = SoundManager._();
  SoundManager._();

  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _gameOverPlayer = AudioPlayer();

  /// Preloads the audio and primes the hardware.
  Future<void> init() async {
    try {
      await _tapPlayer.setAsset('assets/audio/tap.mp3');
      await _gameOverPlayer.setAsset('assets/audio/game_over.mp3');

      // Prime Tap Player
      await _tapPlayer.setVolume(0);
      await _tapPlayer.play();
      await _tapPlayer.pause();
      await _tapPlayer.seek(Duration.zero);
      await _tapPlayer.setVolume(1.0);

      // Prime Game Over Player
      await _gameOverPlayer.setVolume(0);
      await _gameOverPlayer.play();
      await _gameOverPlayer.pause();
      await _gameOverPlayer.seek(Duration.zero);
      await _gameOverPlayer.setVolume(1.0);

    } catch (e) {
      debugPrint("Audio files not found. Ensure tap.mp3 and game_over.mp3 are in assets/audio/");
    }
  }

  void playTap() {
    // Check the persistent setting directly from SaveManager
    if (!SaveManager.instance.soundEnabled) return;
    
    _tapPlayer.seek(Duration.zero);
    _tapPlayer.play();
  }

  void playMirrorSwitch() {
    // Previously used for haptics. Left empty for now since we removed vibration.
    // If we add a "Level Up" mp3 later, it goes here!
  }

  void playGameOver() {
    if (!SaveManager.instance.soundEnabled) return;
    
    _gameOverPlayer.seek(Duration.zero);
    _gameOverPlayer.play();
  }
}