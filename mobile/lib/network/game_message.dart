import 'dart:convert';

/// A single wire message: a `type` tag plus a JSON-serializable payload.
/// The same shape is used over both transports (WebSocket to the online
/// server, and Bluetooth bytes payloads to a nearby host).
class GameMessage {
  GameMessage(this.type, [this.payload = const {}]);

  final String type;
  final Map<String, dynamic> payload;

  String encode() => jsonEncode({'type': type, 'payload': payload});

  static GameMessage decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return GameMessage(
      map['type'] as String,
      (map['payload'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}

/// Message type constants. Keep these in sync with server/src/index.js —
/// the two are independent implementations of the same protocol.
class MsgType {
  static const connected = 'connected';
  static const createRoom = 'create_room';
  static const joinRoom = 'join_room';
  static const roomCreated = 'room_created';
  static const roomJoined = 'room_joined';
  static const lobbyState = 'lobby_state';
  static const setReady = 'set_ready';
  static const gameStart = 'game_start';
  static const playerState = 'player_state';
  static const shoot = 'shoot';
  static const playerHit = 'player_hit';
  static const gameOver = 'game_over';
  static const leaveRoom = 'leave_room';
  static const error = 'error';
}
