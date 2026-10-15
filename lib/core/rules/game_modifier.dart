import '../models/game_enums.dart';
import '../models/prompt.dart';

/// Base contract for any rule or brain-twist in the game.
/// Future rules (e.g., Clockwise, Memory, Double-Tap) simply implement this!
abstract class GameRuleResolver {
  /// Ensures illegal zones (like 'center' during Mirror Mode) are stripped out.
  List<ZoneId> sanitizeZones(List<ZoneId> rawZones, MirrorMode mirrorMode);

  /// Computes which zone(s) count as a valid hit for the current prompt.
  Set<ZoneId> resolveValidTargets({
    required Prompt prompt,
    required Map<ZoneId, GameColor> zoneColors,
    required MirrorMode mirrorMode,
  });
}