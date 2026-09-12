import 'package:flutter/material.dart';

import '../../models/player_state.dart';
import '../../models/team.dart';

/// Top status bar: alive-count badges for each team and the local player's
/// health bar in the middle.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.player, required this.teamCounts});

  final PlayerState player;
  final Map<Team, int> teamCounts;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TeamBadge(team: Team.red, alive: teamCounts[Team.red] ?? 0),
            _HealthBar(health: player.health),
            _TeamBadge(team: Team.blue, alive: teamCounts[Team.blue] ?? 0),
          ],
        ),
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.health});

  final double health;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text('صحتك', style: TextStyle(color: Colors.white, fontSize: 12)),
          LinearProgressIndicator(
            value: (health / 100).clamp(0, 1),
            color: Colors.greenAccent,
            backgroundColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.team, required this.alive});

  final Team team;
  final int alive;

  @override
  Widget build(BuildContext context) {
    final color = team == Team.red ? Colors.redAccent : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text('$alive', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
