import 'dart:math';
import '../models/game_enums.dart';

class WaveConfig {
  final ArenaLayout layout;
  final MirrorMode mirrorMode;
  final double colorPromptProbability; // 0.0 = Directions only, 0.45 = 45% Color prompts
  final double baseTimeRefill;         // Base seconds added per correct tap
  final double parReactionTime;        // Reaction threshold for bonus time

  const WaveConfig({
    required this.layout,
    required this.mirrorMode,
    required this.colorPromptProbability,
    required this.baseTimeRefill,
    required this.parReactionTime,
  });
}

class OverdriveDirector {
  // Increased to 5.0s start / 7.0s cap for comfortable testing
  static const double initialTimeBank = 120.00;
  static const double maxTimeBankCap = 240.00;
  static const double blitzThresholdSeconds = 0.35; // <350ms triggers Blitz bonus

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

  /// Determines the active layout, mirror mode, and timer parameters for the turn.
  WaveConfig getConfigForTurn(int turn) {
    // Wave 1 (Turns 1-10): Classic 2-Button Warmup (Colors still swap to distract!)
    if (turn <= 10) {
      return const WaveConfig(
        layout: ArenaLayout.twoWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.0,
        baseTimeRefill: 0.85,
        parReactionTime: 0.80,
      );
    }

    // Wave 2 (Turns 11-20): 3-Button Expansion (Left, Center, Right)
    if (turn <= 20) {
      return const WaveConfig(
        layout: ArenaLayout.threeWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.0,
        baseTimeRefill: 0.80,
        parReactionTime: 0.75,
      );
    }

    // Wave 3 (Turns 21-32): 5-Button Full Cross + Color Prompts Introduced
    if (turn <= 32) {
      return const WaveConfig(
        layout: ArenaLayout.fiveWay,
        mirrorMode: MirrorMode.none,
        colorPromptProbability: 0.35,
        baseTimeRefill: 0.75,
        parReactionTime: 0.70,
      );
    }

    // Wave 4 (Turns 33-45): First Mirror Wave (2-Button Vertical Mirror + Colors)
    if (turn <= 45) {
      return const WaveConfig(
        layout: ArenaLayout.twoWay,
        mirrorMode: MirrorMode.vertical,
        colorPromptProbability: 0.25,
        baseTimeRefill: 0.75,
        parReactionTime: 0.70,
      );
    }

    // Wave 5 (Turns 46-60): 4-Button Partial Mirrors (Vertical or Horizontal)
    if (turn <= 60) {
      final mode = (turn <= 53) ? MirrorMode.vertical : MirrorMode.horizontal;
      return WaveConfig(
        layout: ArenaLayout.fourWay,
        mirrorMode: mode,
        colorPromptProbability: 0.35,
        baseTimeRefill: 0.68,
        parReactionTime: 0.65,
      );
    }

    // Wave 6 (Turns 61+): Endless Overdrive Loop
    // Mutates every 12 turns between Full Mirror, Partial Mirrors, and 5-Way High Speed Normal
    if (turn - _lastWaveSwitchTurn >= 12) {
      _lastWaveSwitchTurn = turn;
      _mutateEndlessState();
    }

    final double progressiveRefill = max(0.48, 0.65 - ((turn - 60) * 0.0015));

    return WaveConfig(
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

  /// Calculates how much time to add to the Time Bank based on player speed.
  double calculateTimeReward({
    required WaveConfig config,
    required double reactionTimeSeconds,
  }) {
    final double speedBonus =
        max(0.0, config.parReactionTime - reactionTimeSeconds) * 0.50;
    final double blitzBurst =
        (reactionTimeSeconds <= blitzThresholdSeconds) ? 0.12 : 0.0;

    return config.baseTimeRefill + speedBonus + blitzBurst;
  }

  /// Calculates points earned for a correct tap.
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