import 'dart:math' as math;

import 'package:flame/game.dart';

import '../models/player_state.dart';
import '../models/team.dart';
import '../network/game_connection.dart';
import '../network/game_message.dart';
import 'components/arena_component.dart';
import 'components/bullet_component.dart';
import 'components/player_component.dart';

typedef GameOverCallback = void Function(Team winner);

/// The core arena game. It renders every known player and relays local
/// input through [connection] — whether that connection is the online
/// server or a Bluetooth host is invisible here, since both speak the same
/// [GameMessage] protocol.
///
/// Movement speed here (200 px/sec) must match PLAYER_SPEED in
/// server/src/gameConstants.js.
class WarGame extends FlameGame {
  WarGame({
    required this.localPlayerId,
    required this.connection,
    required Map<String, PlayerState> initialPlayers,
    required this.onGameOver,
  }) : players = initialPlayers;

  static final Vector2 arenaSize = Vector2(800, 600);
  static const double _moveSpeed = 200;

  final String localPlayerId;
  final GameConnection connection;
  final Map<String, PlayerState> players;
  final GameOverCallback onGameOver;

  Vector2 moveDirection = Vector2.zero();
  bool _gameEnded = false;

  PlayerState get localPlayer => players[localPlayerId]!;

  @override
  Future<void> onLoad() async {
    await add(ArenaComponent(arenaSize));
    for (final player in players.values) {
      await add(PlayerComponent(state: player, isLocal: player.id == localPlayerId));
    }
    connection.messages.listen(_handleMessage);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_gameEnded) {
      _applyLocalMovement(dt);
    }
  }

  void _applyLocalMovement(double dt) {
    final player = localPlayer;
    if (!player.alive) return;
    if (moveDirection.length2 > 0) {
      final delta = moveDirection.normalized() * _moveSpeed * dt;
      player.x = (player.x + delta.x).clamp(0, arenaSize.x);
      player.y = (player.y + delta.y).clamp(0, arenaSize.y);
    }
    connection.send(GameMessage(MsgType.playerState, {
      'x': player.x,
      'y': player.y,
      'angle': player.angle,
    }));
  }

  /// Called from the on-screen joystick. [direction] components are each in
  /// [-1, 1]; (0, 0) means the stick is centered/released.
  void setMoveDirection(Vector2 direction) {
    moveDirection = direction;
    if (direction.length2 > 0) {
      localPlayer.angle = math.atan2(direction.y, direction.x);
    }
  }

  void shoot() {
    final player = localPlayer;
    if (!player.alive) return;
    add(BulletComponent(start: Vector2(player.x, player.y), angle: player.angle, team: player.team));
    connection.send(GameMessage(MsgType.shoot, {
      'x': player.x,
      'y': player.y,
      'angle': player.angle,
    }));
  }

  void _handleMessage(GameMessage message) {
    switch (message.type) {
      case MsgType.playerState:
        _onRemotePlayerState(message.payload);
        break;
      case MsgType.shoot:
        _onRemoteShoot(message.payload);
        break;
      case MsgType.playerHit:
        _onPlayerHit(message.payload);
        break;
      case MsgType.gameOver:
        _onGameOver(message.payload);
        break;
    }
  }

  void _onRemotePlayerState(Map<String, dynamic> payload) {
    final player = players[payload['id'] as String];
    if (player == null) return;
    player.x = (payload['x'] as num).toDouble();
    player.y = (payload['y'] as num).toDouble();
    player.angle = (payload['angle'] as num).toDouble();
  }

  void _onRemoteShoot(Map<String, dynamic> payload) {
    final shooter = players[payload['id'] as String];
    if (shooter == null) return;
    add(BulletComponent(
      start: Vector2((payload['x'] as num).toDouble(), (payload['y'] as num).toDouble()),
      angle: (payload['angle'] as num).toDouble(),
      team: shooter.team,
    ));
  }

  void _onPlayerHit(Map<String, dynamic> payload) {
    final player = players[payload['id'] as String];
    if (player == null) return;
    player.health = (payload['health'] as num).toDouble();
    player.alive = payload['alive'] as bool;
  }

  void _onGameOver(Map<String, dynamic> payload) {
    if (_gameEnded) return;
    _gameEnded = true;
    onGameOver(payload['winner'] == 'red' ? Team.red : Team.blue);
  }
}
