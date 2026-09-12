import 'dart:math' as math;

import '../models/player_state.dart';
import '../models/team.dart';

/// Replicates the server's shot-validation logic (see resolveShot in
/// server/src/index.js) for the device acting as Bluetooth host, where
/// there is no server to referee hits. Keep the constants and the
/// distance/angle check in sync with that file.
class HostAuthority {
  static const hitRange = 260.0;
  static const hitConeRadians = 0.18;
  static const bulletDamage = 20.0;

  /// Applies damage in place and returns the id of the player that was hit,
  /// or null if the shot found no target.
  static String? resolveShot({
    required Map<String, PlayerState> players,
    required String shooterId,
    required double x,
    required double y,
    required double angle,
  }) {
    final shooter = players[shooterId];
    if (shooter == null || !shooter.alive) return null;

    for (final target in players.values) {
      if (target.id == shooterId || target.team == shooter.team || !target.alive) {
        continue;
      }
      final dx = target.x - x;
      final dy = target.y - y;
      final dist = math.sqrt(dx * dx + dy * dy);
      final angleToTarget = math.atan2(dy, dx);
      final angleDiff = _normalize(angleToTarget - angle).abs();
      if (dist < hitRange && angleDiff < hitConeRadians) {
        target.health = math.max(0, target.health - bulletDamage);
        target.alive = target.health > 0;
        return target.id;
      }
    }
    return null;
  }

  static double _normalize(double a) {
    var result = a;
    while (result > math.pi) result -= 2 * math.pi;
    while (result < -math.pi) result += 2 * math.pi;
    return result;
  }

  /// Returns the winning team, or null if both teams still have a survivor.
  static Team? winningTeam(Map<String, PlayerState> players) {
    final aliveRed = players.values.where((p) => p.team == Team.red && p.alive).length;
    final aliveBlue = players.values.where((p) => p.team == Team.blue && p.alive).length;
    if (aliveRed == 0 && aliveBlue > 0) return Team.blue;
    if (aliveBlue == 0 && aliveRed > 0) return Team.red;
    return null;
  }
}
