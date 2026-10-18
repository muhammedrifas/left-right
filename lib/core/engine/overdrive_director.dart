import 'dart:math';
import '../models/game_enums.dart';

class WaveConfig {
  final String waveName;               // Added for the Transition Banner!
  final ArenaLayout layout;
  final MirrorMode mirrorMode;
  final double colorPromptProbability;
  final double baseTimeRefill;
  final double parReactionTime;

  const WaveConfig({
    required this.waveName,
    required this.layout,
    required this.mirrorMode,
    required this.colorPromptProbability,
    required this.baseTimeRefill,
    required this.parReactionTime,
  });
}

class OverdriveDirector {
  static const double initialTimeBank = 10.00;
  static const double maxTimeBankCap = 25.00;
  static const double blitzThresholdSeconds = 0.5;

  final Random _rng;
  MirrorMode _currentEndlessMirror = MirrorMode.none;
  ArenaLayout _currentEndlessLayout = ArenaLayout.fourWay;
  int _lastWaveSwitchTurn = 0;

  OverdriveDirector({Random? rng}) : _rng = rng ?? Random();

  void reset() {
    _currentEndlessMirror = MirrorMode.none;
    _currentEndlessLayout = ArenaLayout.fourWay;
    _lastWaveSwitchTurn = 0;
  }

  WaveConfig getConfigForTurn(int turn) {
    if (turn <= 10) {
      return const WaveConfig(
        waveName: 'WAVE 1: WARMUP',
        layout: ArenaLayout.twoWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.0,
        baseTimeRefill: 0.85,
        parReactionTime: 0.80,
      );
    }
    if (turn <= 20) {
      return const WaveConfig(
        waveName: 'WAVE 2: EXPANSION',
        layout: ArenaLayout.threeWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.0,
        baseTimeRefill: 0.80,
        parReactionTime: 0.75,
      );
    }
    if (turn <= 32) {
      return const WaveConfig(
        waveName: 'WAVE 3: FULL CROSS',
        layout: ArenaLayout.fiveWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.0,
        baseTimeRefill: 0.78,
        parReactionTime: 0.75,
      );
    }
    if (turn <= 45) {
      return const WaveConfig(
        waveName: 'WAVE 4: COLOR INJECTION',
        layout: ArenaLayout.fiveWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.45,
        baseTimeRefill: 0.75,
        parReactionTime: 0.72,
      );
    }
    if (turn <= 57) {
      return const WaveConfig(
        waveName: 'WAVE 5: MIRROR INVERT',
        layout: ArenaLayout.twoWay,
        mirrorMode: MirrorMode.vertical,
        colorPromptProbability: 0.25,
        baseTimeRefill: 0.75,
        parReactionTime: 0.70,
      );
    }
    if (turn <= 67) {
      return const WaveConfig(
        waveName: 'WAVE 6: 4-WAY MIRROR',
        layout: ArenaLayout.fourWay,
        mirrorMode: MirrorMode.vertical,
        colorPromptProbability: 0.35,
        baseTimeRefill: 0.70,
        parReactionTime: 0.68,
      );
    }
    if (turn <= 77) {
      return const WaveConfig(
        waveName: 'WAVE 7: UPSIDE DOWN',
        layout: ArenaLayout.fourWay,
        mirrorMode: MirrorMode.horizontal,
        colorPromptProbability: 0.35,
        baseTimeRefill: 0.70,
        parReactionTime: 0.68,
      );
    }
    if (turn <= 88) {
      return const WaveConfig(
        waveName: 'WAVE 8: FULL INVERSION',
        layout: ArenaLayout.fourWay,
        mirrorMode: MirrorMode.full,
        colorPromptProbability: 0.35,
        baseTimeRefill: 0.70,
        parReactionTime: 0.68,
      );
    }

    if (turn - _lastWaveSwitchTurn >= 12) {
      _lastWaveSwitchTurn = turn;
      _mutateEndlessState();
    }
    final double progressiveRefill = max(0.48, 0.65 - ((turn - 88) * 0.0015));

    return WaveConfig(
      waveName: 'OVERDRIVE CHAOS',
      layout: _currentEndlessLayout,
      mirrorMode: _currentEndlessMirror,
      colorPromptProbability: 0.40,
      baseTimeRefill: progressiveRefill,
      parReactionTime: 0.60,
    );
  }

  void _mutateEndlessState() {
    const modes = [
      MirrorMode.none,
      MirrorMode.vertical,
      MirrorMode.horizontal,
      MirrorMode.full,
    ];
    final candidates = modes.where((m) => m != _currentEndlessMirror).toList();
    _currentEndlessMirror = candidates[_rng.nextInt(candidates.length)];

    if (_currentEndlessMirror == MirrorMode.none) {
      _currentEndlessLayout = ArenaLayout.fiveWay;
    } else if (_currentEndlessMirror == MirrorMode.vertical && _rng.nextBool()) {
      _currentEndlessLayout = ArenaLayout.twoWay;
    } else {
      _currentEndlessLayout = ArenaLayout.fourWay;
    }
  }

  double calculateTimeReward({
    required WaveConfig config,
    required double reactionTimeSeconds,
  }) {
    final double speedBonus = max(0.0, config.parReactionTime - reactionTimeSeconds) * 0.50;
    return config.baseTimeRefill + speedBonus + (reactionTimeSeconds <= blitzThresholdSeconds ? 0.12 : 0.0);
  }

  int calculatePoints({
    required WaveConfig config,
    required double reactionTimeSeconds,
  }) {
    final int basePoints = switch (config.layout) {
      ArenaLayout.twoWay || ArenaLayout.threeWay => 10,
      ArenaLayout.fourWay || ArenaLayout.fiveWay => 15,
    };
    final int speedBonus = (reactionTimeSeconds <= 0.50) ? 5 : 0;
    return (basePoints + speedBonus) * config.mirrorMode.scoreMultiplier;
  }
}