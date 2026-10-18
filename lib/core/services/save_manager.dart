import 'package:shared_preferences/shared_preferences.dart';

class SaveManager {
  // Singleton instance
  static final SaveManager instance = SaveManager._();
  SaveManager._();

  late SharedPreferences _prefs;

  int _highScore = 0;
  int _maxUnlockedTurn = 1;

  int get highScore => _highScore;
  int get maxUnlockedTurn => _maxUnlockedTurn;

  /// Loads saved data from the device on app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _highScore = _prefs.getInt('highScore') ?? 0;
    _maxUnlockedTurn = _prefs.getInt('maxUnlockedTurn') ?? 1;
  }

  /// Saves a new high score to permanent storage if it exceeds the current one.
  Future<void> saveHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      await _prefs.setInt('highScore', _highScore);
    }
  }

  /// Unlocks a new wave/turn in permanent storage if the player reaches further.
  Future<void> saveMaxUnlockedTurn(int turn) async {
    if (turn > _maxUnlockedTurn) {
      _maxUnlockedTurn = turn;
      await _prefs.setInt('maxUnlockedTurn', _maxUnlockedTurn);
    }
  }
}