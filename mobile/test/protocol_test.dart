// Run with `flutter test` once the Flutter SDK and `flutter pub get` have
// been run (not available in the environment this scaffold was written in).

import 'package:flutter_test/flutter_test.dart';
import 'package:war_gaming/network/game_message.dart';
import 'package:war_gaming/network/host_authority.dart';
import 'package:war_gaming/models/player_state.dart';
import 'package:war_gaming/models/team.dart';

void main() {
  test('GameMessage round-trips through encode/decode', () {
    final message = GameMessage(MsgType.playerState, {'x': 10.0, 'y': 20.0, 'angle': 1.5});
    final decoded = GameMessage.decode(message.encode());
    expect(decoded.type, MsgType.playerState);
    expect(decoded.payload['x'], 10.0);
    expect(decoded.payload['angle'], 1.5);
  });

  group('HostAuthority.resolveShot', () {
    Map<String, PlayerState> players() => {
          'shooter': PlayerState(id: 'shooter', name: 'A', team: Team.red),
          'enemy': PlayerState(id: 'enemy', name: 'B', team: Team.blue, x: 100, y: 0),
          'ally': PlayerState(id: 'ally', name: 'C', team: Team.red, x: 100, y: 0),
        };

    test('hits an enemy directly ahead', () {
      final p = players();
      final hitId = HostAuthority.resolveShot(
        players: p,
        shooterId: 'shooter',
        x: 0,
        y: 0,
        angle: 0,
      );
      expect(hitId, 'enemy');
      expect(p['enemy']!.health, 80);
    });

    test('never hits a teammate standing on the same line', () {
      final p = players();
      p['enemy']!.x = 9999;
      final hitId = HostAuthority.resolveShot(
        players: p,
        shooterId: 'shooter',
        x: 0,
        y: 0,
        angle: 0,
      );
      expect(hitId, isNull);
    });

    test('misses outside the angular cone', () {
      final p = players();
      p['enemy']!.x = 0;
      p['enemy']!.y = 100;
      final hitId = HostAuthority.resolveShot(
        players: p,
        shooterId: 'shooter',
        x: 0,
        y: 0,
        angle: 0,
      );
      expect(hitId, isNull);
    });
  });

  test('HostAuthority.winningTeam declares the surviving team', () {
    final players = {
      'a': PlayerState(id: 'a', name: 'A', team: Team.red, alive: false),
      'b': PlayerState(id: 'b', name: 'B', team: Team.blue),
    };
    expect(HostAuthority.winningTeam(players), Team.blue);
  });
}
