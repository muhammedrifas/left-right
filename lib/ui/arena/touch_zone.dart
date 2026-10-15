import 'package:flutter/material.dart';
import '../../core/models/game_enums.dart';
import '../../core/models/prompt.dart';

class TouchZone extends StatefulWidget {
  final ZoneId zoneId;
  final GameColor gameColor;
  final Prompt? activePrompt; // Non-null only if the prompt is displayed inside THIS button
  final MirrorMode mirrorMode;
  final VoidCallback onTouchDown;

  const TouchZone({
    super.key,
    required this.zoneId,
    required this.gameColor,
    required this.activePrompt,
    required this.mirrorMode,
    required this.onTouchDown,
  });

  @override
  State<TouchZone> createState() => _TouchZoneState();
}

class _TouchZoneState extends State<TouchZone> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isMirrored = widget.mirrorMode.isMirrored;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        widget.onTouchDown();
      },
      onPointerUp: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 50),
        child: Container(
          decoration: BoxDecoration(
            color: widget.gameColor.color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isMirrored
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.15),
              width: isMirrored ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gameColor.color.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle watermark label in corner so player knows zone geometry
              Positioned(
                top: 12,
                left: 16,
                child: Text(
                  widget.zoneId.label,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.22),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // Active Stroop Prompt Pill (if spawned in this zone)
              if (widget.activePrompt != null)
                Center(
                  child: _PromptBadge(
                    prompt: widget.activePrompt!,
                    mirrorMode: widget.mirrorMode,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptBadge extends StatelessWidget {
  final Prompt prompt;
  final MirrorMode mirrorMode;

  const _PromptBadge({
    required this.prompt,
    required this.mirrorMode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMirrored = mirrorMode.isMirrored;
    final double dx = mirrorMode.mirrorLeftRight ? 3.5 : 0.0;
    final double dy = mirrorMode.mirrorTopBottom ? 3.5 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMirrored ? Colors.cyanAccent : Colors.white24,
          width: isMirrored ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Chromatic Aberration (Red/Cyan Split) when Mirror Mode is active
          if (isMirrored) ...[
            Transform.translate(
              offset: Offset(-dx, -dy),
              child: Text(
                prompt.text,
                style: TextStyle(
                  color: const Color(0xFFFF0055).withValues(alpha: 0.75),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(dx, dy),
              child: Text(
                prompt.text,
                style: TextStyle(
                  color: const Color(0xFF00FFFF).withValues(alpha: 0.75),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
          // Core Crisp Prompt Text
          Text(
            prompt.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}