import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/engine/overdrive_director.dart';
import '../../core/models/game_enums.dart';

class CenterHaloHud extends StatelessWidget {
  final ValueListenable<double> timeBankListenable;
  final int score;
  final int blitzStreak;
  final MirrorMode mirrorMode;

  const CenterHaloHud({
    super.key,
    required this.timeBankListenable,
    required this.score,
    required this.blitzStreak,
    required this.mirrorMode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMirrored = mirrorMode.isMirrored;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141821),
        border: Border(
          bottom: BorderSide(
            color: isMirrored
                ? Colors.cyanAccent.withValues(alpha: 0.5)
                : Colors.white12,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Score (Left) | Mode Badge (Center) | Timer Value (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Score & Blitz Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PTS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (blitzStreak >= 2) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEA00).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚡ ${blitzStreak}x',
                        style: const TextStyle(
                          color: Color(0xFFFFEA00),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // 2. Active Mode / Multiplier Pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isMirrored
                      ? Colors.cyanAccent.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isMirrored
                      ? '${mirrorMode.label} (${mirrorMode.scoreMultiplier}x)'
                      : 'NORMAL MODE',
                  style: TextStyle(
                    color: isMirrored ? Colors.black : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 3. Live Digital Timer Readout
              ValueListenableBuilder<double>(
                valueListenable: timeBankListenable,
                builder: (context, timeLeft, _) {
                  final Color timerColor = timeLeft > 2.0
                      ? const Color(0xFF00E5FF)
                      : (timeLeft > 1.0
                          ? const Color(0xFFFFEA00)
                          : const Color(0xFFFF1744));

                  return Text(
                    '${timeLeft.toStringAsFixed(2)}s',
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Smooth 120fps Draining Fuse Bar
          ValueListenableBuilder<double>(
            valueListenable: timeBankListenable,
            builder: (context, timeLeft, _) {
              final double progress =
                  (timeLeft / OverdriveDirector.maxTimeBankCap).clamp(0.0, 1.0);

              final Color barColor = timeLeft > 2.0
                  ? const Color(0xFF00E5FF)
                  : (timeLeft > 1.0
                      ? const Color(0xFFFFEA00)
                      : const Color(0xFFFF1744));

              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              );
            },
          ),
        ],
      ),
    );
              
  }
}