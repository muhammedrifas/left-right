import 'package:flutter/material.dart';

/// Represents the physical touch zones on the screen.
enum ZoneId {
  left('LEFT'),
  right('RIGHT'),
  center('CENTER'),
  top('TOP'),
  bottom('BOTTOM');

  final String label;
  const ZoneId(this.label);

  /// Flips Left <-> Right. Top, Bottom, and Center remain unchanged.
  ZoneId get flipHorizontalAxis {
    return switch (this) {
      ZoneId.left => ZoneId.right,
      ZoneId.right => ZoneId.left,
      _ => this,
    };
  }

  /// Flips Top <-> Bottom. Left, Right, and Center remain unchanged.
  ZoneId get flipVerticalAxis {
    return switch (this) {
      ZoneId.top => ZoneId.bottom,
      ZoneId.bottom => ZoneId.top,
      _ => this,
    };
  }
}

/// High-contrast neon palette designed for instant recognition on dark backgrounds.
enum GameColor {
  red('RED', Color(0xFFFF3366)),
  blue('BLUE', Color(0xFF00AAFF)),
  green('GREEN', Color(0xFF00E676)),
  yellow('YELLOW', Color(0xFFFFEA00)),
  purple('PURPLE', Color(0xFFB388FF));

  final String label;
  final Color color;
  const GameColor(this.label, this.color);
}

/// Defines which edges of the screen are "Mirrored".
enum MirrorMode {
  none(
    label: 'NORMAL',
    scoreMultiplier: 1,
    mirrorLeftRight: false,
    mirrorTopBottom: false,
  ),
  vertical(
    // Vertical mirror line = Left & Right edges glow (Left <-> Right)
    label: 'VERTICAL MIRROR',
    scoreMultiplier: 2,
    mirrorLeftRight: true,
    mirrorTopBottom: false,
  ),
  horizontal(
    // Horizontal mirror line = Top & Bottom edges glow (Top <-> Bottom)
    label: 'HORIZONTAL MIRROR',
    scoreMultiplier: 2,
    mirrorLeftRight: false,
    mirrorTopBottom: true,
  ),
  full(
    // All 4 edges glow (Left <-> Right AND Top <-> Bottom)
    label: 'FULL MIRROR',
    scoreMultiplier: 3,
    mirrorLeftRight: true,
    mirrorTopBottom: true,
  );

  final String label;
  final int scoreMultiplier;
  final bool mirrorLeftRight;
  final bool mirrorTopBottom;

  const MirrorMode({
    required this.label,
    required this.scoreMultiplier,
    required this.mirrorLeftRight,
    required this.mirrorTopBottom,
  });

  bool get isMirrored => this != MirrorMode.none;
}

/// Standard arena layouts.
enum ArenaLayout {
  twoWay([ZoneId.left, ZoneId.right]),
  threeWay([ZoneId.left, ZoneId.center, ZoneId.right]),
  fourWay([ZoneId.top, ZoneId.bottom, ZoneId.left, ZoneId.right]),
  fiveWay([ZoneId.top, ZoneId.bottom, ZoneId.left, ZoneId.center, ZoneId.right]);

  final List<ZoneId> zones;
  const ArenaLayout(this.zones);
}