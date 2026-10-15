import 'game_enums.dart';

enum PromptType { direction, color }

class Prompt {
  final PromptType type;
  final ZoneId? targetDirection; // Populated if type == PromptType.direction
  final GameColor? targetColor;  // Populated if type == PromptType.color
  final ZoneId displayZone;      // Which button physically renders this text

  const Prompt.direction({
    required ZoneId direction,
    required this.displayZone,
  })  : type = PromptType.direction,
        targetDirection = direction,
        targetColor = null;

  const Prompt.color({
    required GameColor color,
    required this.displayZone,
  })  : type = PromptType.color,
        targetColor = color,
        targetDirection = null;

  /// The actual string shown to the player (e.g., "LEFT" or "RED")
  String get text => type == PromptType.direction
      ? targetDirection!.label
      : targetColor!.label;
}