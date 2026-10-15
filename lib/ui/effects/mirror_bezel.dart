import 'package:flutter/material.dart';
import '../../core/models/game_enums.dart';

class MirrorBezelWrapper extends StatelessWidget {
  final MirrorMode mirrorMode;
  final Widget child;

  const MirrorBezelWrapper({
    super.key,
    required this.mirrorMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool glowLR = mirrorMode.mirrorLeftRight;
    final bool glowTB = mirrorMode.mirrorTopBottom;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: child,
        ),

        // TOP & BOTTOM MIRROR RAILS (Horizontal Mirror / Full Mirror)
        if (glowTB) ...[
          const Positioned(
            top: 0,
            left: 32,
            right: 32,
            child: _MirrorEdgeBar(
              isHorizontalBar: true,
              color: Color(0xFFFF00AA),
              label: '▼ MIRROR AXIS ▼',
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 32,
            right: 32,
            child: _MirrorEdgeBar(
              isHorizontalBar: true,
              color: Color(0xFFFF00AA),
              label: '▲ MIRROR AXIS ▲',
            ),
          ),
        ],

        // LEFT & RIGHT MIRROR RAILS (Vertical Mirror / Full Mirror)
        if (glowLR) ...[
          const Positioned(
            left: 0,
            top: 48,
            bottom: 48,
            child: _MirrorEdgeBar(
              isHorizontalBar: false,
              color: Color(0xFF00FFFF),
              label: '▶',
            ),
          ),
          const Positioned(
            right: 0,
            top: 48,
            bottom: 48,
            child: _MirrorEdgeBar(
              isHorizontalBar: false,
              color: Color(0xFF00FFFF),
              label: '◀',
            ),
          ),
        ],
      ],
    );
  }
}

class _MirrorEdgeBar extends StatelessWidget {
  final bool isHorizontalBar;
  final Color color;
  final String label;

  const _MirrorEdgeBar({
    required this.isHorizontalBar,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: isHorizontalBar ? null : 10,
        height: isHorizontalBar ? 12 : null,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.85),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isHorizontalBar
            ? Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              )
            : null,
      ),
    );
  }
}