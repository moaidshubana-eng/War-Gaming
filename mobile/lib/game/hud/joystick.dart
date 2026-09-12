import 'package:flutter/material.dart';

/// A simple drag-based virtual joystick, built from plain Flutter widgets
/// (no Flame joystick component) so it doesn't depend on the game engine's
/// touch/coordinate system. Reports a direction whose components are each
/// in [-1, 1] via [onChanged]; (0, 0) means centered/released.
class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({super.key, required this.onChanged});

  final ValueChanged<Offset> onChanged;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  static const double _radius = 60;

  Offset _knob = Offset.zero;

  void _update(Offset localPosition) {
    const center = Offset(_radius, _radius);
    var delta = localPosition - center;
    if (delta.distance > _radius) {
      delta = Offset.fromDirection(delta.direction, _radius);
    }
    setState(() => _knob = delta);
    widget.onChanged(Offset(delta.dx / _radius, delta.dy / _radius));
  }

  void _reset() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _update(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: _radius * 2,
        height: _radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(60),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Align(
          alignment: Alignment(_knob.dx / _radius, _knob.dy / _radius),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(200),
            ),
          ),
        ),
      ),
    );
  }
}
