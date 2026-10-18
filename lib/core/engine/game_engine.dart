import 'dart:math';
import 'package:flutter/foundation.dart';
import '../audio/sound_manager.dart';
import '../models/game_enums.dart';
import '../models/turn_snapshot.dart';
import '../services/save_manager.dart';
import 'overdrive_director.dart';
import 'turn_generator.dart';

enum GameStatus { idle, playing, gameOver }
enum GameOverReason { none, wrongZone, timeExpired }

class GameEngine extends ChangeNotifier {
  final OverdriveDirector _director;
  final TurnGenerator _generator;

  final ValueNotifier<double> timeBank =
      ValueNotifier<double>(OverdriveDirector.initialTimeBank);
  final Stopwatch _turnStopwatch = Stopwatch();

  GameStatus _status = GameStatus.idle;
  GameOverReason _gameOverReason = GameOverReason.none;
  int _score = 0;
  int _turnCount = 0;
  int _blitzStreak = 0;

  TurnSnapshot? _currentTurn;
  WaveConfig? _currentWaveConfig;

  // Transition & Pacing State
  double _transitionTimer = 0.0;
  String _transitionMessage = '';
  bool _isWaitingForFirstTouch = true;

  GameEngine({
    OverdriveDirector? director,
    TurnGenerator? generator,
  })  : _director = director ?? OverdriveDirector(),
        _generator = generator ?? TurnGenerator();

  GameStatus get status => _status;
  GameOverReason get gameOverReason => _gameOverReason;
  int get score => _score;
  int get turnCount => _turnCount;
  int get blitzStreak => _blitzStreak;
  TurnSnapshot? get currentTurn => _currentTurn;

  bool get isTransitioning => _transitionTimer > 0.0;
  String get transitionMessage => _transitionMessage;
  bool get isWaitingForFirstTouch => _isWaitingForFirstTouch;

  // Expose permanent saves directly to the UI
  int get highScore => SaveManager.instance.highScore;
  int get maxUnlockedTurn => SaveManager.instance.maxUnlockedTurn;

  void startGame({int startTurn = 1}) {
    _director.reset();
    _score = 0;
    _turnCount = max(0, startTurn - 1);
    _blitzStreak = 0;
    _gameOverReason = GameOverReason.none;
    _status = GameStatus.playing;
    _transitionTimer = 0.0;
    _isWaitingForFirstTouch = true;
    timeBank.value = OverdriveDirector.initialTimeBank;

    _advanceToNextTurn(isFirstTurn: true);
    SoundManager.instance.playMirrorSwitch();
  }

  void onTick(double dtSeconds) {
    if (_status != GameStatus.playing) return;

    // 1. Handle Freeze-Frame Transition
    if (_transitionTimer > 0.0) {
      _transitionTimer -= dtSeconds;
      if (_transitionTimer <= 0.0) {
        _transitionTimer = 0.0;
        notifyListeners(); // Clears the banner
      }
      return; // Do not drain the Time Bank while the banner is on screen!
    }

    // 2. Pause timer drain if we are waiting for the player's first strategic touch
    if (_isWaitingForFirstTouch) return;

    // 3. Normal Time Bank drain
    final nextTime = timeBank.value - dtSeconds;
    if (nextTime <= 0.0) {
      timeBank.value = 0.0;
      _triggerGameOver(GameOverReason.timeExpired);
    } else {
      timeBank.value = nextTime;
    }
  }

  void handleZoneTouch(ZoneId touchedZone) {
    if (_status != GameStatus.playing || _currentTurn == null || isTransitioning) return;

    // Clear the wait flag and start the reaction stopwatch the moment they touch
    if (_isWaitingForFirstTouch) {
      _isWaitingForFirstTouch = false;
      _turnStopwatch..reset()..start();
    }

    if (!_currentTurn!.validTargetZones.contains(touchedZone)) {
      _triggerGameOver(GameOverReason.wrongZone);
      return;
    }

    final double reactionSeconds = _turnStopwatch.elapsedMicroseconds / 1000000.0;
    
    timeBank.value = min(
      OverdriveDirector.maxTimeBankCap,
      timeBank.value + _director.calculateTimeReward(
        config: _currentWaveConfig!,
        reactionTimeSeconds: reactionSeconds,
      ),
    );

    final bool isBlitz = reactionSeconds <= OverdriveDirector.blitzThresholdSeconds;
    if (isBlitz) {
      _blitzStreak++;
    } else {
      _blitzStreak = 0;
    }
    SoundManager.instance.playTap(isBlitz: isBlitz);

    _score += _director.calculatePoints(
      config: _currentWaveConfig!,
      reactionTimeSeconds: reactionSeconds,
    );
    
    // Check and save High Score natively
    SaveManager.instance.saveHighScore(_score);

    _advanceToNextTurn();
  }

  void _advanceToNextTurn({bool isFirstTurn = false}) {
    final WaveConfig nextConfig = _director.getConfigForTurn(_turnCount + 1);
    final bool isWaveChange = _currentWaveConfig == null || nextConfig.waveName != _currentWaveConfig!.waveName;

    _turnCount++;
    
    // Unlock new levels in permanent storage immediately when a new turn is reached!
    SaveManager.instance.saveMaxUnlockedTurn(_turnCount);

    _currentWaveConfig = nextConfig;
    _currentTurn = _generator.generateTurn(
      turnNumber: _turnCount,
      config: _currentWaveConfig!,
    );

    if (isWaveChange) {
      // Pause game for 850ms to show the banner (skip delay on absolute first turn)
      _transitionTimer = isFirstTurn ? 0.0 : 0.85; 
      _transitionMessage = _currentWaveConfig!.waveName;
      _isWaitingForFirstTouch = true; // Wait for player to process new rules
      _turnStopwatch..reset()..stop();
      if (!isFirstTurn) SoundManager.instance.playMirrorSwitch();
    } else {
      _isWaitingForFirstTouch = false;
      _turnStopwatch..reset()..start();
    }

    notifyListeners();
  }

  void _triggerGameOver(GameOverReason reason) {
    _turnStopwatch.stop();
    _status = GameStatus.gameOver;
    _gameOverReason = reason;
    SoundManager.instance.playGameOver();
    notifyListeners();
  }

  @override
  void dispose() {
    timeBank.dispose();
    super.dispose();
  }
}