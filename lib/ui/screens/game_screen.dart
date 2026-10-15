import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/engine/game_engine.dart';
import '../../core/models/game_enums.dart';
import '../arena/arena_grid.dart';
import '../effects/mirror_bezel.dart';
import '../hud/center_halo_hud.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameEngine _engine;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Selected starting turn for quick testing (defaults to Turn 1)
  int _selectedStartTurn = 1;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _ticker = createTicker((elapsed) {
      final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      if (dt > 0 && dt < 0.25) {
        _engine.onTick(dt);
      }

      if (_engine.status == GameStatus.gameOver && _ticker.isActive) {
        _ticker.stop();
      }
    });
  }

  void _startGame({int? overrideStartTurn}) {
    if (overrideStartTurn != null) {
      _selectedStartTurn = overrideStartTurn;
    }
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastElapsed = Duration.zero;
    _engine.startGame(startTurn: _selectedStartTurn);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _engine,
          builder: (context, _) {
            final turn = _engine.currentTurn;
            final mirrorMode = turn?.mirrorMode ?? MirrorMode.none;

            return Stack(
              children: [
                // 1. Dedicated Top HUD Bar + Unobstructed Gameplay Arena Below
                if (turn != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CenterHaloHud(
                        timeBankListenable: _engine.timeBank,
                        score: _engine.score,
                        blitzStreak: _engine.blitzStreak,
                        mirrorMode: mirrorMode,
                      ),
                      Expanded(
                        child: MirrorBezelWrapper(
                          mirrorMode: mirrorMode,
                          child: ArenaGrid(
                            turn: turn,
                            onZoneTouched: _engine.handleZoneTouch,
                          ),
                        ),
                      ),
                    ],
                  ),

                // 2. Start / Game Over Overlay with Wave Jump Selector
                if (_engine.status != GameStatus.playing)
                  _MenuOverlay(
                    status: _engine.status,
                    reason: _engine.gameOverReason,
                    score: _engine.score,
                    highScore: _engine.highScore,
                    selectedStartTurn: _selectedStartTurn,
                    onSelectStartTurn: (turnNum) {
                      setState(() => _selectedStartTurn = turnNum);
                    },
                    onPlayPressed: () => _startGame(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WavePreset {
  final String label;
  final int startTurn;
  const _WavePreset(this.label, this.startTurn);
}

class _MenuOverlay extends StatelessWidget {
  final GameStatus status;
  final GameOverReason reason;
  final int score;
  final int highScore;
  final int selectedStartTurn;
  final ValueChanged<int> onSelectStartTurn;
  final VoidCallback onPlayPressed;

  static const List<_WavePreset> _presets = [
    _WavePreset('W1: 2-Way (T1)', 1),
    _WavePreset('W2: 3-Way (T11)', 11),
    _WavePreset('W3: 5-Way + Color (T21)', 21),
    _WavePreset('W4: 2-Way Vert Mirror (T33)', 33),
    _WavePreset('W5A: 4-Way Vert Mirror (T46)', 46),
    _WavePreset('W5B: 4-Way Horiz Mirror (T54)', 54),
    _WavePreset('W6: Overdrive Chaos (T61)', 61),
  ];

  const _MenuOverlay({
    required this.status,
    required this.reason,
    required this.score,
    required this.highScore,
    required this.selectedStartTurn,
    required this.onSelectStartTurn,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGameOver = status == GameStatus.gameOver;
    final String subtitle = switch (reason) {
      GameOverReason.wrongZone => 'WRONG ZONE TAPPED!',
      GameOverReason.timeExpired => 'TIME BANK DEPLETED!',
      GameOverReason.none => 'SPATIAL & COLOR STROOP OVERDRIVE',
    };

    return Container(
      color: const Color(0xFF0D0F14).withValues(alpha: 0.94),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGameOver ? 'BRAIN SHORT-CIRCUITED' : 'LEFT — RIGHT',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isGameOver ? const Color(0xFFFF3366) : Colors.cyanAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (isGameOver) ...[
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'BEST: $highScore',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Quick Wave Jump Selector for Testing
            const Text(
              'JUMP TO WAVE (DEBUG):',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presets.map((preset) {
                final bool isSelected = selectedStartTurn == preset.startTurn;
                return GestureDetector(
                  onTap: () => onSelectStartTurn(preset.startTurn),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.cyanAccent.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent : Colors.white24,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Text(
                      preset.label,
                      style: TextStyle(
                        color: isSelected ? Colors.cyanAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Start / Retry Button
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => onPlayPressed(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  isGameOver ? 'TAP TO RETRY' : 'START OVERDRIVE',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}