import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/game_enums.dart';
import '../models/turn_snapshot.dart';
import 'overdrive_director.dart';
import 'turn_generator.dart';

enum GameStatus { idle, playing, gameOver }
enum GameOverReason { none, wrongZone, timeExpired }

class GameEngine extends ChangeNotifier {
  final OverdriveDirector _director;
  final TurnGenerator _generator;

  /// Dedicated notifier for the 60/120fps timer bar so only the HUD repaints every frame.
  final ValueNotifier<double> timeBank =
      ValueNotifier<double>(OverdriveDirector.initialTimeBank);

  final Stopwatch _turnStopwatch = Stopwatch();

  GameStatus _status = GameStatus.idle;
  GameOverReason _gameOverReason = GameOverReason.none;
  int _score = 0;
  int _highScore = 0;
  int _turnCount = 0;
  int _blitzStreak = 0;
  bool _didJustSwitchMirrorMode = false;

  TurnSnapshot? _currentTurn;
  WaveConfig? _currentWaveConfig;

  GameEngine({
    OverdriveDirector? director,
    TurnGenerator? generator,
  })  : _director = director ?? OverdriveDirector(),
        _generator = generator ?? TurnGenerator();

  // Public Getters
  GameStatus get status => _status;
  GameOverReason get gameOverReason => _gameOverReason;
  int get score => _score;
  int get highScore => _highScore;
  int get turnCount => _turnCount;
  int get blitzStreak => _blitzStreak;
  bool get didJustSwitchMirrorMode => _didJustSwitchMirrorMode;
  TurnSnapshot? get currentTurn => _currentTurn;

  /// Starts or restarts Endless Overdrive at [startTurn] (defaults to Turn 1).
  void startGame({int startTurn = 1}) {
    _director.reset();
    _score = 0;
    _turnCount = max(0, startTurn - 1);
    _blitzStreak = 0;
    _gameOverReason = GameOverReason.none;
    _status = GameStatus.playing;
    timeBank.value = OverdriveDirector.initialTimeBank;

    _advanceToNextTurn(isFirstTurn: true);
    HapticFeedback.mediumImpact();
  }

  /// Called on every hardware VSync frame by the UI's Ticker (passes delta seconds).
  void onTick(double dtSeconds) {
    if (_status != GameStatus.playing) return;

    final nextTime = timeBank.value - dtSeconds;
    if (nextTime <= 0.0) {
      timeBank.value = 0.0;
      _triggerGameOver(GameOverReason.timeExpired);
    } else {
      timeBank.value = nextTime;
    }
  }

  /// Triggered immediately on `Listener.onPointerDown` for zero-latency touch response.
  void handleZoneTouch(ZoneId touchedZone) {
    if (_status != GameStatus.playing || _currentTurn == null) return;

    final isCorrect = _currentTurn!.validTargetZones.contains(touchedZone);

    if (!isCorrect) {
      _triggerGameOver(GameOverReason.wrongZone);
      return;
    }

    // 1. Measure exact reaction time in seconds
    final double reactionSeconds =
        _turnStopwatch.elapsedMicroseconds / 1000000.0;

    // 2. Calculate Time Bank reward and cap at maxTimeBankCap
    final double timeAdded = _director.calculateTimeReward(
      config: _currentWaveConfig!,
      reactionTimeSeconds: reactionSeconds,
    );
    timeBank.value = min(
      OverdriveDirector.maxTimeBankCap,
      timeBank.value + timeAdded,
    );

    // 3. Calculate Score & Blitz streak
    if (reactionSeconds <= OverdriveDirector.blitzThresholdSeconds) {
      _blitzStreak++;
      HapticFeedback.lightImpact();
    } else {
      _blitzStreak = 0;
      HapticFeedback.selectionClick();
    }

    _score += _director.calculatePoints(
      config: _currentWaveConfig!,
      reactionTimeSeconds: reactionSeconds,
    );
    if (_score > _highScore) {
      _highScore = _score;
    }

    // 4. Spawn next turn immediately
    _advanceToNextTurn();
  }

  void _advanceToNextTurn({bool isFirstTurn = false}) {
    final previousMirror = _currentTurn?.mirrorMode ?? MirrorMode.none;

    _turnCount++;
    _currentWaveConfig = _director.getConfigForTurn(_turnCount);
    _currentTurn = _generator.generateTurn(
      turnNumber: _turnCount,
      config: _currentWaveConfig!,
    );

    _didJustSwitchMirrorMode =
        !isFirstTurn && (previousMirror != _currentTurn!.mirrorMode);

    if (_didJustSwitchMirrorMode) {
      HapticFeedback.heavyImpact();
    }

    _turnStopwatch
      ..reset()
      ..start();

    notifyListeners();
  }

  void _triggerGameOver(GameOverReason reason) {
    _turnStopwatch.stop();
    _status = GameStatus.gameOver;
    _gameOverReason = reason;
    HapticFeedback.vibrate();
    notifyListeners();
  }

  @override
  void dispose() {
    timeBank.dispose();
    super.dispose();
  }
}