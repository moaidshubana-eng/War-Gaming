import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/team.dart';

/// A short-lived visual tracer for a shot. It is purely cosmetic — whether
/// the shot actually hit someone is decided by the authoritative side (the
/// server, or the Bluetooth host via [HostAuthority]) and applied through a
/// separate `player_hit` message, so every device draws the same tracer
/// regardless of who fired it.
class BulletComponent extends PositionComponent {
  BulletComponent({required Vector2 start, required this.angle, required this.team})
      : super(position: start.clone(), size: Vector2.all(6), anchor: Anchor.center);

  @override
  final double angle;
  final Team team;

  static const double speed = 500; // px/sec, cosmetic only
  static const double maxRange = 260; // must match HostAuthority.hitRange

  double _travelled = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final step = speed * dt;
    position += Vector2(math.cos(angle), math.sin(angle)) * step;
    _travelled += step;
    if (_travelled >= maxRange) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final color = team == Team.red ? const Color(0xFFFFCDD2) : const Color(0xFFBBDEFB);
    canvas.drawCircle(const Offset(3, 3), 3, Paint()..color = color);
  }
}
