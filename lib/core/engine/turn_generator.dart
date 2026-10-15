import 'dart:math';
import '../models/game_enums.dart';
import '../models/prompt.dart';
import '../models/turn_snapshot.dart';
import '../rules/game_modifier.dart';
import '../rules/mirror_modifier.dart';
import 'overdrive_director.dart';

class TurnGenerator {
  final Random _rng;
  final GameRuleResolver ruleResolver;

  TurnGenerator({
    Random? rng,
    this.ruleResolver = const OverdriveRuleResolver(),
  }) : _rng = rng ?? Random();

  TurnSnapshot generateTurn({
    required int turnNumber,
    required WaveConfig config,
  }) {
    // 1. Sanitize active zones (guarantees no 'center' in Mirror Mode)
    final activeZones = ruleResolver.sanitizeZones(
      config.layout.zones,
      config.mirrorMode,
    );

    // 2. Shuffle and assign a unique GameColor to each active zone
    final shuffledColors = List<GameColor>.from(GameColor.values)..shuffle(_rng);
    final Map<ZoneId, GameColor> zoneColors = {
      for (int i = 0; i < activeZones.length; i++)
        activeZones[i]: shuffledColors[i % shuffledColors.length],
    };

    // 3. Decide between Direction Prompt vs. Color Prompt
    final bool useColorPrompt =
        _rng.nextDouble() < config.colorPromptProbability;

    final Prompt prompt = useColorPrompt
        ? _createStroopColorPrompt(activeZones, zoneColors)
        : _createStroopDirectionPrompt(activeZones);

    // 4. Pre-compute the valid target zone(s) using the active rule resolver
    final validTargets = ruleResolver.resolveValidTargets(
      prompt: prompt,
      zoneColors: zoneColors,
      mirrorMode: config.mirrorMode,
    );

    return TurnSnapshot(
      turnNumber: turnNumber,
      activeZones: activeZones,
      zoneColors: zoneColors,
      prompt: prompt,
      mirrorMode: config.mirrorMode,
      validTargetZones: validTargets,
    );
  }

  /// Picks a valid direction and biases placing the text inside a DIFFERENT zone (75% of the time).
  Prompt _createStroopDirectionPrompt(List<ZoneId> activeZones) {
    final targetDirection = activeZones[_rng.nextInt(activeZones.length)];

    ZoneId displayZone = targetDirection;
    if (activeZones.length > 1 && _rng.nextDouble() < 0.75) {
      final otherZones =
          activeZones.where((z) => z != targetDirection).toList();
      displayZone = otherZones[_rng.nextInt(otherZones.length)];
    }

    return Prompt.direction(
      direction: targetDirection,
      displayZone: displayZone,
    );
  }

  /// Picks a color that is GUARANTEED to exist on one of the active buttons,
  /// and biases placing the text inside a differently colored button (80% of the time).
  Prompt _createStroopColorPrompt(
    List<ZoneId> activeZones,
    Map<ZoneId, GameColor> zoneColors,
  ) {
    final targetZoneWithColor = activeZones[_rng.nextInt(activeZones.length)];
    final targetColor = zoneColors[targetZoneWithColor]!;

    ZoneId displayZone = targetZoneWithColor;
    if (activeZones.length > 1 && _rng.nextDouble() < 0.80) {
      final mismatchZones =
          activeZones.where((z) => z != targetZoneWithColor).toList();
      displayZone = mismatchZones[_rng.nextInt(mismatchZones.length)];
    }

    return Prompt.color(
      color: targetColor,
      displayZone: displayZone,
    );
  }
}