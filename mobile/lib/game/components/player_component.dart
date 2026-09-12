import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/player_state.dart';
import '../../models/team.dart';

/// Renders one player as a colored circle with a facing dot and a health
/// bar. Reads straight from the shared [state] object, so any network or
/// local-movement update to it shows up on the next frame automatically.
class PlayerComponent extends PositionComponent {
  PlayerComponent({required this.state, required this.isLocal})
      : super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  static const double radius = 18;

  final PlayerState state;
  final bool isLocal;

  @override
  void update(double dt) {
    super.update(dt);
    position = Vector2(state.x, state.y);
  }

  @override
  void render(Canvas canvas) {
    final teamColor = state.team == Team.red ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    final bodyPaint = Paint()..color = state.alive ? teamColor : teamColor.withAlpha(60);
    canvas.drawCircle(const Offset(radius, radius), radius, bodyPaint);

    if (isLocal) {
      canvas.drawCircle(
        const Offset(radius, radius),
        radius,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    _renderFacingDot(canvas);
    _renderHealthBar(canvas);
  }

  void _renderFacingDot(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(state.angle);
    canvas.drawCircle(const Offset(radius * 0.9, 0), 3, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  void _renderHealthBar(Canvas canvas) {
    const barWidth = radius * 2;
    final healthRatio = (state.health / 100).clamp(0.0, 1.0);
    canvas.drawRect(
      const Rect.fromLTWH(0, -10, barWidth, 4),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, -10, barWidth * healthRatio, 4),
      Paint()..color = const Color(0xFF43A047),
    );
  }
}
