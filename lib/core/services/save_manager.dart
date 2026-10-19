import 'package:shared_preferences/shared_preferences.dart';

class SaveManager {
  // Singleton instance
  static final SaveManager instance = SaveManager._();
  SaveManager._();

  late SharedPreferences _prefs;

  int _highScore = 0;
  int _maxUnlockedTurn = 1;
  bool _soundEnabled = true;

  int get highScore => _highScore;
  int get maxUnlockedTurn => _maxUnlockedTurn;
  bool get soundEnabled => _soundEnabled;

  /// Loads saved data from the device on app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _highScore = _prefs.getInt('highScore') ?? 0;
    _maxUnlockedTurn = _prefs.getInt('maxUnlockedTurn') ?? 1;
    _soundEnabled = _prefs.getBool('soundEnabled') ?? true;
  }

  /// Saves a new high score to permanent storage if it exceeds the current one.
  Future<void> saveHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      await _prefs.setInt('highScore', _highScore);
    }
  }

  /// Unlocks a new wave/turn in permanent storage.
  Future<void> saveMaxUnlockedTurn(int turn) async {
    if (turn > _maxUnlockedTurn) {
      _maxUnlockedTurn = turn;
      await _prefs.setInt('maxUnlockedTurn', _maxUnlockedTurn);
    }
  }

  /// Toggles the sound setting and saves it immediately.
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _prefs.setBool('soundEnabled', _soundEnabled);
  }
}