import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/engine/game_engine.dart';
import '../../core/models/game_enums.dart';
import '../arena/arena_grid.dart';
import '../effects/arcade_background.dart';
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
    });
    _ticker.start();
  }

  void _startGame({int? overrideStartTurn}) {
    if (overrideStartTurn != null) {
      _selectedStartTurn = overrideStartTurn;
    }
    _lastElapsed = Duration.zero;
    _engine.startGame(startTurn: _selectedStartTurn);
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
      body: ListenableBuilder(
        listenable: _engine,
        builder: (context, _) {
          final turn = _engine.currentTurn;
          final mirrorMode = turn?.mirrorMode ?? MirrorMode.none;

          return Stack(
            children: [
              ArcadeBackground(mirrorMode: mirrorMode),
              SafeArea(
                child: Stack(
                  children: [
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
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ArenaGrid(
                                turn: turn,
                                onZoneTouched: _engine.handleZoneTouch,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (_engine.isTransitioning)
                      _WaveTransitionBanner(message: _engine.transitionMessage),

                    if (_engine.status == GameStatus.playing && _engine.isWaitingForFirstTouch && !_engine.isTransitioning)
                      const Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Text(
                              'TAP TO BEGIN WAVE',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (_engine.status != GameStatus.playing)
                      _MenuOverlay(
                        status: _engine.status,
                        reason: _engine.gameOverReason,
                        score: _engine.score,
                        highScore: _engine.highScore,
                        selectedStartTurn: _selectedStartTurn,
                        maxUnlockedTurn: _engine.maxUnlockedTurn, // Added dynamic unlock variable!
                        onSelectStartTurn: (turnNum) {
                          setState(() => _selectedStartTurn = turnNum);
                        },
                        onPlayPressed: () => _startGame(),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaveTransitionBanner extends StatelessWidget {
  final String message;

  const _WaveTransitionBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0055).withValues(alpha: 0.85),
                border: const Border(
                  top: BorderSide(color: Colors.white, width: 2),
                  bottom: BorderSide(color: Colors.white, width: 2),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFFF0055), blurRadius: 20),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          );
        },
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
  final int maxUnlockedTurn; // Now passed in directly from the Engine
  final ValueChanged<int> onSelectStartTurn;
  final VoidCallback onPlayPressed;

  static const List<_WavePreset> _presets = [
    _WavePreset('W1: 2-Way (T1)', 1),
    _WavePreset('W2: 3-Way (T11)', 11),
    _WavePreset('W3: 5-Way Dir (T21)', 21),
    _WavePreset('W4: 5-Way+Col (T33)', 33),
    _WavePreset('W5: Mirror Vert (T46)', 46),
    _WavePreset('W6: 4-Way Mirr (T58)', 58),
    _WavePreset('W7: Mirr Horiz (T68)', 68),
    _WavePreset('W8: Mirr Full (T78)', 78),
  ];

  const _MenuOverlay({
    required this.status,
    required this.reason,
    required this.score,
    required this.highScore,
    required this.selectedStartTurn,
    required this.maxUnlockedTurn,
    required this.onSelectStartTurn,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGameOver = status == GameStatus.gameOver;
    return Container(
      color: const Color(0xFF0D0F14).withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGameOver ? 'GAME OVER' : 'LEFT — RIGHT',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
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
              const SizedBox(height: 24),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presets.map((preset) {
                final bool isSelected = selectedStartTurn == preset.startTurn;
                final bool isLocked = preset.startTurn > maxUnlockedTurn;

                return GestureDetector(
                  onTap: isLocked ? null : () => onSelectStartTurn(preset.startTurn),
                  child: Opacity(
                    opacity: isLocked ? 0.4 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.22) : Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLocked) const Icon(Icons.lock, size: 12, color: Colors.white),
                          if (isLocked) const SizedBox(width: 4),
                          Text(
                            preset.label,
                            style: TextStyle(
                              color: isSelected ? Colors.cyanAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onPlayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              ),
              child: Text(
                isGameOver ? 'RETRY' : 'START',
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}