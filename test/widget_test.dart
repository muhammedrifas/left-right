import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:left_right/core/models/game_enums.dart';
import 'package:left_right/core/models/prompt.dart';
import 'package:left_right/core/rules/mirror_modifier.dart';
import 'package:left_right/core/engine/overdrive_director.dart';
import 'package:left_right/core/engine/turn_generator.dart';
import 'package:left_right/core/engine/game_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OverdriveRuleResolver Tests', () {
    const resolver = OverdriveRuleResolver();
    final mockColors = {
      ZoneId.left: GameColor.red,
      ZoneId.right: GameColor.blue,
      ZoneId.top: GameColor.green,
      ZoneId.bottom: GameColor.yellow,
    };

    test('Center zone is stripped whenever MirrorMode is active', () {
      final raw = ArenaLayout.fiveWay.zones;
      expect(resolver.sanitizeZones(raw, MirrorMode.none), contains(ZoneId.center));
      expect(resolver.sanitizeZones(raw, MirrorMode.vertical), isNot(contains(ZoneId.center)));
      expect(resolver.sanitizeZones(raw, MirrorMode.horizontal), isNot(contains(ZoneId.center)));
      expect(resolver.sanitizeZones(raw, MirrorMode.full), isNot(contains(ZoneId.center)));
    });

    test('Vertical Mirror inverts Left <-> Right, keeps Top/Bottom normal', () {
      const leftPrompt = Prompt.direction(direction: ZoneId.left, displayZone: ZoneId.right);
      const topPrompt = Prompt.direction(direction: ZoneId.top, displayZone: ZoneId.bottom);

      expect(
        resolver.resolveValidTargets(
          prompt: leftPrompt,
          zoneColors: mockColors,
          mirrorMode: MirrorMode.vertical,
        ),
        equals({ZoneId.right}),
      );
      expect(
        resolver.resolveValidTargets(
          prompt: topPrompt,
          zoneColors: mockColors,
          mirrorMode: MirrorMode.vertical,
        ),
        equals({ZoneId.top}),
      );
    });

    test('Horizontal Mirror inverts Top <-> Bottom, keeps Left/Right normal', () {
      const leftPrompt = Prompt.direction(direction: ZoneId.left, displayZone: ZoneId.right);
      const topPrompt = Prompt.direction(direction: ZoneId.top, displayZone: ZoneId.bottom);

      expect(
        resolver.resolveValidTargets(
          prompt: leftPrompt,
          zoneColors: mockColors,
          mirrorMode: MirrorMode.horizontal,
        ),
        equals({ZoneId.left}),
      );
      expect(
        resolver.resolveValidTargets(
          prompt: topPrompt,
          zoneColors: mockColors,
          mirrorMode: MirrorMode.horizontal,
        ),
        equals({ZoneId.bottom}),
      );
    });

    test('Color prompts are immune to Mirror Mode inversion', () {
      const colorPrompt = Prompt.color(color: GameColor.red, displayZone: ZoneId.right);

      final valid = resolver.resolveValidTargets(
        prompt: colorPrompt,
        zoneColors: mockColors,
        mirrorMode: MirrorMode.full,
      );

      expect(valid, equals({ZoneId.left}));
    });
  });

  group('GameEngine Loop & Time Bank Tests', () {
    test('Simulates 50 consecutive perfect turns across waves', () {
      final engine = GameEngine(
        director: OverdriveDirector(rng: Random(42)),
        generator: TurnGenerator(rng: Random(42)),
      );

      engine.startGame();
      expect(engine.status, GameStatus.playing);

      for (int i = 1; i <= 50; i++) {
        final turn = engine.currentTurn!;
        engine.onTick(0.30);

        final correctZone = turn.validTargetZones.first;
        engine.handleZoneTouch(correctZone);

        expect(engine.status, GameStatus.playing);
      }

      expect(engine.turnCount, 51);
      expect(engine.score, greaterThan(500));
    });

    test('Touching wrong zone triggers immediate Game Over', () {
      final engine = GameEngine();
      engine.startGame();

      final turn = engine.currentTurn!;
      final wrongZone = turn.activeZones.firstWhere(
        (z) => !turn.validTargetZones.contains(z),
      );

      engine.handleZoneTouch(wrongZone);
      expect(engine.status, GameStatus.gameOver);
      expect(engine.gameOverReason, GameOverReason.wrongZone);
    });
  });
}