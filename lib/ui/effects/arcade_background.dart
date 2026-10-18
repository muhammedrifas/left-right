import 'package:flutter/material.dart';
import '../../core/models/game_enums.dart';

class ArcadeBackground extends StatefulWidget {
  final MirrorMode mirrorMode;

  const ArcadeBackground({super.key, required this.mirrorMode});

  @override
  State<ArcadeBackground> createState() => _ArcadeBackgroundState();
}

class _ArcadeBackgroundState extends State<ArcadeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of the grid scrolling
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SynthwavePerspectivePainter(
            scrollProgress: _controller.value,
            mirrorMode: widget.mirrorMode,
          ),
        );
      },
    );
  }
}

class _SynthwavePerspectivePainter extends CustomPainter {
  final double scrollProgress;
  final MirrorMode mirrorMode;

  _SynthwavePerspectivePainter({
    required this.scrollProgress,
    required this.mirrorMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic color shifting based on the current mode
    final Color gridColor = mirrorMode.isMirrored
        ? (mirrorMode == MirrorMode.horizontal
            ? const Color(0xFFFF00AA) // Magenta for Horizontal
            : const Color(0xFF00E5FF)) // Cyan for Vertical/Full
        : Colors.white.withValues(alpha: 0.15); // Gray for Normal

    final Paint linePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double horizonY = size.height * 0.25; // Horizon line is 25% down the screen
    final double cx = size.width / 2;

    // 1. Draw Vertical Perspective Lines vanishing into the horizon
    int numVerticalLines = 14;
    for (int i = 0; i <= numVerticalLines; i++) {
      double t = i / numVerticalLines;
      double startX = size.width * t;
      canvas.drawLine(Offset(cx, horizonY), Offset(startX, size.height), linePaint);
    }

    // 2. Draw Horizontal Scrolling Lines
    // We use an exponential curve to make lines move faster as they get closer to the bottom
    int numHorizontalLines = 10;
    for (int i = 0; i < numHorizontalLines; i++) {
      // Offset by scrollProgress so they animate forward continuously
      double t = (i + scrollProgress) / numHorizontalLines;
      
      // Exponential math creates the 3D depth illusion
      double yPos = horizonY + (size.height - horizonY) * (t * t);
      
      if (yPos >= horizonY && yPos <= size.height) {
        // Fade the lines out as they reach the horizon
        final double opacity = ((yPos - horizonY) / (size.height - horizonY)).clamp(0.0, 1.0);
        linePaint.color = gridColor.withValues(alpha: opacity * 0.6);
        canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SynthwavePerspectivePainter oldDelegate) {
    return oldDelegate.scrollProgress != scrollProgress ||
        oldDelegate.mirrorMode != mirrorMode;
  }
}