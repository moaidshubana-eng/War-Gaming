import 'team.dart';

/// Mutable, shared player record. The same instance is referenced by the
/// lobby list, the [WarGame] engine, and the HUD, so updating one field
/// (e.g. from an incoming network message) is immediately visible
/// everywhere without extra plumbing.
class PlayerState {
  PlayerState({
    required this.id,
    required this.name,
    required this.team,
    this.x = 0,
    this.y = 0,
    this.angle = 0,
    this.health = 100,
    this.alive = true,
    this.ready = false,
    this.score = 0,
  });

  final String id;
  String name;
  Team team;
  double x;
  double y;
  double angle;
  double health;
  bool alive;
  bool ready;
  int score;
}
