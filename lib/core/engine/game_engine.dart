import 'dart:math';
import 'package:flutter/foundation.dart';
import '../audio/sound_manager.dart';
import '../models/game_enums.dart';
import '../models/prompt.dart';
import '../models/turn_snapshot.dart';
import '../services/save_manager.dart';
import 'overdrive_director.dart';
import 'turn_generator.dart';

enum GameStatus { idle, playing, gameOver }
enum GameOverReason { none, wrongZone, timeExpired }
enum GameMode { standard, zen }

class GameEngine extends ChangeNotifier {
  final OverdriveDirector _director;
  final TurnGenerator _generator;

  final ValueNotifier<double> timeBank =
      ValueNotifier<double>(OverdriveDirector.initialTimeBank);
  final Stopwatch _turnStopwatch = Stopwatch();

  GameStatus _status = GameStatus.idle;
  GameMode _currentMode = GameMode.standard;
  GameOverReason _gameOverReason = GameOverReason.none;
  
  int _score = 0;
  int _turnCount = 0;
  int _blitzStreak = 0;
  int _zenBaseTurn = 1;

  TurnSnapshot? _currentTurn;
  WaveConfig? _currentWaveConfig;

  double _transitionTimer = 0.0;
  String _transitionMessage = '';
  bool _isWaitingForFirstTouch = true;
  String _gameOverFeedback = '';

  GameEngine({
    OverdriveDirector? director,
    TurnGenerator? generator,
  })  : _director = director ?? OverdriveDirector(),
        _generator = generator ?? TurnGenerator();

  GameStatus get status => _status;
  GameMode get currentMode => _currentMode;
  GameOverReason get gameOverReason => _gameOverReason;
  int get score => _score;
  int get turnCount => _turnCount;
  int get blitzStreak => _blitzStreak;
  TurnSnapshot? get currentTurn => _currentTurn;

  bool get isTransitioning => _transitionTimer > 0.0;
  String get transitionMessage => _transitionMessage;
  bool get isWaitingForFirstTouch => _isWaitingForFirstTouch;
  String get gameOverFeedback => _gameOverFeedback;

  int get highScore => SaveManager.instance.highScore;
  int get maxUnlockedTurn => SaveManager.instance.maxUnlockedTurn;

  void startGame({int startTurn = 1, GameMode mode = GameMode.standard}) {
    _director.reset();
    _score = 0;
    _turnCount = max(0, startTurn - 1);
    _zenBaseTurn = startTurn;
    _blitzStreak = 0;
    _gameOverReason = GameOverReason.none;
    _status = GameStatus.playing;
    _currentMode = mode;
    _transitionTimer = 0.0; // Ensure no banners on standard fresh start
    _isWaitingForFirstTouch = true;
    _gameOverFeedback = '';
    
    timeBank.value = mode == GameMode.zen 
        ? OverdriveDirector.maxTimeBankCap 
        : OverdriveDirector.initialTimeBank;

    _advanceToNextTurn(isFirstTurn: true);
    SoundManager.instance.playMirrorSwitch();
  }

  void resetToIdle() {
    _status = GameStatus.idle;
    _turnStopwatch.stop();
    _gameOverFeedback = '';
    notifyListeners();
  }

  void onTick(double dtSeconds) {
    if (_status != GameStatus.playing) return;

    if (_transitionTimer > 0.0) {
      _transitionTimer -= dtSeconds;
      if (_transitionTimer <= 0.0) {
        _transitionTimer = 0.0;
        notifyListeners();
      }
      return;
    }

    if (_isWaitingForFirstTouch) return;
    if (_currentMode == GameMode.zen) return;

    final nextTime = timeBank.value - dtSeconds;
    if (nextTime <= 0.0) {
      timeBank.value = 0.0;
      _triggerGameOver(GameOverReason.timeExpired, null);
    } else {
      timeBank.value = nextTime;
    }
  }

  void handleZoneTouch(ZoneId touchedZone) {
    if (_status != GameStatus.playing || _currentTurn == null || isTransitioning) return;

    if (_isWaitingForFirstTouch) {
      _isWaitingForFirstTouch = false;
      _turnStopwatch..reset()..start();
    }

    if (!_currentTurn!.validTargetZones.contains(touchedZone)) {
      _triggerGameOver(GameOverReason.wrongZone, touchedZone);
      return;
    }

    final double reactionSeconds = _turnStopwatch.elapsedMicroseconds / 1000000.0;
    
    if (_currentMode == GameMode.standard) {
      timeBank.value = min(
        OverdriveDirector.maxTimeBankCap,
        timeBank.value + _director.calculateTimeReward(
          config: _currentWaveConfig!,
          reactionTimeSeconds: reactionSeconds,
        ),
      );
    }

    final bool isBlitz = reactionSeconds <= OverdriveDirector.blitzThresholdSeconds;
    if (isBlitz) {
      _blitzStreak++;
    } else {
      _blitzStreak = 0;
    }
    
    SoundManager.instance.playTap();

    _score += _director.calculatePoints(
      config: _currentWaveConfig!,
      reactionTimeSeconds: reactionSeconds,
    );
    
    if (_currentMode == GameMode.standard) {
      SaveManager.instance.saveHighScore(_score);
    }
    
    _advanceToNextTurn();
  }

  void _advanceToNextTurn({bool isFirstTurn = false}) {
    if (_currentMode == GameMode.zen) {
      _currentWaveConfig = _director.getConfigForTurn(_zenBaseTurn);
      _currentTurn = _generator.generateTurn(
        turnNumber: _turnCount,
        config: _currentWaveConfig!,
      );
      
      if (isFirstTurn) {
        _transitionTimer = 0.0; // FIX: Suppress banner completely in Zen Mode
        _transitionMessage = '';
        _isWaitingForFirstTouch = true;
        _turnStopwatch..reset()..stop();
      } else {
        _isWaitingForFirstTouch = false;
        _turnStopwatch..reset()..start();
      }
      notifyListeners();
      return;
    }

    final WaveConfig nextConfig = _director.getConfigForTurn(_turnCount + 1);
    final bool isWaveChange = _currentWaveConfig == null || nextConfig.waveName != _currentWaveConfig!.waveName;

    _turnCount++;
    SaveManager.instance.saveMaxUnlockedTurn(_turnCount);

    _currentWaveConfig = nextConfig;
    _currentTurn = _generator.generateTurn(
      turnNumber: _turnCount,
      config: _currentWaveConfig!,
    );

    if (isWaveChange) {
      // Banners only show mid-game (isFirstTurn = false), never at the start
      _transitionTimer = isFirstTurn ? 0.0 : 0.85; 
      _transitionMessage = _currentWaveConfig!.waveName;
      _isWaitingForFirstTouch = true;
      _turnStopwatch..reset()..stop();
      if (!isFirstTurn) SoundManager.instance.playMirrorSwitch();
    } else {
      _isWaitingForFirstTouch = false;
      _turnStopwatch..reset()..start();
    }

    notifyListeners();
  }

  void _triggerGameOver(GameOverReason reason, ZoneId? tappedZone) {
    _turnStopwatch.stop();
    _status = GameStatus.gameOver;
    _gameOverReason = reason;
    _generateFeedback(reason, tappedZone);
    SoundManager.instance.playGameOver();
    notifyListeners();
  }

  void _generateFeedback(GameOverReason reason, ZoneId? tappedZone) {
    if (_currentTurn == null) return;
    
    final turn = _currentTurn!;
    final String target = turn.validTargetZones.first.label;
    
    if (reason == GameOverReason.timeExpired) {
      _gameOverFeedback = "OUT OF TIME!\nYou hesitated. You needed to tap $target.";
      return;
    }

    final String promptStr = turn.prompt.text;
    final bool isColor = turn.prompt.type == PromptType.color;
    final bool isMirrored = turn.mirrorMode.isMirrored;
    final String tappedStr = tappedZone?.label ?? 'unknown';

    if (isMirrored && isColor) {
      _gameOverFeedback = "TRICKED!\nColors are immune to mirrors! You still needed to tap the actual $promptStr button.";
    } else if (isMirrored && !isColor) {
      String modeName = turn.mirrorMode == MirrorMode.vertical ? "Vertical Mirror" :
                        turn.mirrorMode == MirrorMode.horizontal ? "Horizontal Mirror" : "Full Mirror";
      _gameOverFeedback = "MIRROR TRAP!\n$modeName was active. When the text says $promptStr, you must tap $target.";
    } else if (isColor) {
      _gameOverFeedback = "WRONG COLOR!\nThe text asked for $promptStr, but you tapped a different colored button.";
    } else {
      _gameOverFeedback = "WRONG ZONE!\nThe prompt said $promptStr, but you tapped $tappedStr.";
    }
  }

  @override
  void dispose() {
    timeBank.dispose();
    super.dispose();
  }
}