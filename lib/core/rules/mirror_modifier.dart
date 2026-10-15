import '../models/game_enums.dart';
import '../models/prompt.dart';
import 'game_modifier.dart';

class OverdriveRuleResolver implements GameRuleResolver {
  const OverdriveRuleResolver();

  @override
  List<ZoneId> sanitizeZones(List<ZoneId> rawZones, MirrorMode mirrorMode) {
    if (!mirrorMode.isMirrored) return rawZones;

    // Rule guardrail: Never allow CENTER button when Mirror Mode is active
    return rawZones.where((z) => z != ZoneId.center).toList();
  }

  @override
  Set<ZoneId> resolveValidTargets({
    required Prompt prompt,
    required Map<ZoneId, GameColor> zoneColors,
    required MirrorMode mirrorMode,
  }) {
    // 1. COLOR PROMPTS: Immune to mirror inversion!
    // Player must tap the button currently painted with that color.
    if (prompt.type == PromptType.color) {
      final targetColor = prompt.targetColor!;
      return zoneColors.entries
          .where((entry) => entry.value == targetColor)
          .map((entry) => entry.key)
          .toSet();
    }

    // 2. DIRECTION PROMPTS: Apply active Mirror Axis transformations.
    ZoneId target = prompt.targetDirection!;

    if (mirrorMode.mirrorLeftRight) {
      target = target.flipHorizontalAxis;
    }
    if (mirrorMode.mirrorTopBottom) {
      target = target.flipVerticalAxis;
    }

    return {target};
  }
}