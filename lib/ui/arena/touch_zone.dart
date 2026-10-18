import 'package:flutter/material.dart';
import '../../core/models/game_enums.dart';
import '../../core/models/prompt.dart';

class TouchZone extends StatefulWidget {
  final ZoneId zoneId;
  final GameColor gameColor;
  final Prompt? activePrompt;
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
    final Color baseColor = widget.gameColor.color;

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
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 45),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(baseColor, Colors.white, 0.15)!,
                baseColor,
                Color.lerp(baseColor, Colors.black, 0.25)!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The Transformed Prompt Badge (Watermarks removed!)
              if (widget.activePrompt != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.75, end: 1.0),
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: _PromptBadge(
                        prompt: widget.activePrompt!,
                        mirrorMode: widget.mirrorMode,
                      ),
                    ),
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
    final bool isColorPrompt = prompt.type == PromptType.color;

    // The genius text-flipping logic
    final double flipX = mirrorMode.mirrorLeftRight ? -1.0 : 1.0;
    final double flipY = mirrorMode.mirrorTopBottom ? -1.0 : 1.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isColorPrompt ? Colors.amberAccent : Colors.white30,
            width: isColorPrompt ? 2.0 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Transform.scale(
          scaleX: flipX,
          scaleY: flipY,
          alignment: Alignment.center,
          child: Text(
            prompt.text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: isColorPrompt ? Colors.amberAccent : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}