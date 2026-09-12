import '../models/player_state.dart';
import '../models/team.dart';

/// A Dart port of server/src/roomManager.js's lobby bookkeeping (team
/// balancing, ready tracking). Used by [BluetoothConnection] when this
/// device is the host, so it can referee its own lobby exactly the way the
/// online server referees an online one — same rules, same message shapes.
class LocalRoom {
  final Map<String, PlayerState> players = {};
  final Map<String, bool> ready = {};

  PlayerState addPlayer(String id, String name) {
    final team = _balancedTeam();
    final player = PlayerState(id: id, name: name, team: team);
    players[id] = player;
    ready[id] = false;
    return player;
  }

  void removePlayer(String id) {
    players.remove(id);
    ready.remove(id);
  }

  Team _balancedTeam() {
    final red = players.values.where((p) => p.team == Team.red).length;
    final blue = players.values.where((p) => p.team == Team.blue).length;
    return red <= blue ? Team.red : Team.blue;
  }

  void setReady(String id, bool value) {
    ready[id] = value;
  }

  bool get allReady => players.length >= 2 && ready.values.every((r) => r);

  List<Map<String, dynamic>> toLobbyPlayers() => players.values
      .map((p) => {
            'id': p.id,
            'name': p.name,
            'team': p.team.value,
            'ready': ready[p.id] ?? false,
          })
      .toList();
}
