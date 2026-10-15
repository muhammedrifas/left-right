import 'package:flutter/material.dart';
import '../../core/models/game_enums.dart';
import '../../core/models/turn_snapshot.dart';
import 'touch_zone.dart';

class ArenaGrid extends StatelessWidget {
  final TurnSnapshot turn;
  final ValueChanged<ZoneId> onZoneTouched;

  const ArenaGrid({
    super.key,
    required this.turn,
    required this.onZoneTouched,
  });

  Widget _buildZone(ZoneId zone) {
    final gameColor = turn.zoneColors[zone] ?? GameColor.blue;
    final hasPrompt = turn.prompt.displayZone == zone;

    return TouchZone(
      key: ValueKey('${zone.name}_${turn.turnNumber}'),
      zoneId: zone,
      gameColor: gameColor,
      activePrompt: hasPrompt ? turn.prompt : null,
      mirrorMode: turn.mirrorMode,
      onTouchDown: () => onZoneTouched(zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zones = turn.activeZones;
    final bool hasTop = zones.contains(ZoneId.top);
    final bool hasBottom = zones.contains(ZoneId.bottom);
    final bool hasCenter = zones.contains(ZoneId.center);

    // Case 1: Only Left & Right (2-Way) or Left, Center, Right (3-Way)
    if (!hasTop && !hasBottom) {
      if (hasCenter) {
        // 3-Way Horizontal Split (Stacked vertically on portrait for large thumb targets,
        // or 3 columns—let's use 3 side-by-side columns as in your original design)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildZone(ZoneId.left)),
            const SizedBox(width: 10),
            Expanded(child: _buildZone(ZoneId.center)),
            const SizedBox(width: 10),
            Expanded(child: _buildZone(ZoneId.right)),
          ],
        );
      }

      // Classic 2-Way Split (Left & Right halves)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildZone(ZoneId.left)),
          const SizedBox(width: 10),
          Expanded(child: _buildZone(ZoneId.right)),
        ],
      );
    }

    // Case 2: 4-Way (Top, Bottom, Left, Right) or 5-Way (+ Center)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTop) ...[
          Expanded(flex: 3, child: _buildZone(ZoneId.top)),
          const SizedBox(height: 10),
        ],
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildZone(ZoneId.left)),
              if (hasCenter) ...[
                const SizedBox(width: 10),
                Expanded(child: _buildZone(ZoneId.center)),
              ],
              const SizedBox(width: 10),
              Expanded(child: _buildZone(ZoneId.right)),
            ],
          ),
        ),
        if (hasBottom) ...[
          const SizedBox(height: 10),
          Expanded(flex: 3, child: _buildZone(ZoneId.bottom)),
        ],
      ],
    );
  }
}