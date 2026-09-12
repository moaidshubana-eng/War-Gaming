import 'dart:ui';

import 'package:flame/components.dart';

/// Background and a light grid for the arena. Purely decorative — the
/// arena's logical bounds live in [WarGame.arenaSize].
class ArenaComponent extends PositionComponent {
  ArenaComponent(Vector2 arenaSize) : super(size: arenaSize, position: Vector2.zero());

  static const double _gridStep = 50;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF2E7D32),
    );
    final gridPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (double x = 0; x < size.x; x += _gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += _gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }
}
