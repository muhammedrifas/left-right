import 'game_enums.dart';
import 'prompt.dart';

/// Immutable snapshot of a single turn's board state.
class TurnSnapshot {
  final int turnNumber;
  final List<ZoneId> activeZones;
  final Map<ZoneId, GameColor> zoneColors;
  final Prompt prompt;
  final MirrorMode mirrorMode;
  final Set<ZoneId> validTargetZones; // Pre-computed valid answer(s) for O(1) hit check

  const TurnSnapshot({
    required this.turnNumber,
    required this.activeZones,
    required this.zoneColors,
    required this.prompt,
    required this.mirrorMode,
    required this.validTargetZones,
  });
}