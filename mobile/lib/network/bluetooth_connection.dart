import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import 'game_connection.dart';
import 'game_message.dart';
import 'local_room.dart';

/// Local multiplayer over Bluetooth / Wi-Fi Direct via `nearby_connections`,
/// for playing without internet.
///
/// There is no server on this transport, so when [isHost] is true this
/// class also referees the lobby itself (via [LocalRoom]), emitting the
/// same `room_created` / `room_joined` / `lobby_state` / `game_start`
/// messages the online server would send — [LobbyScreen] and [WarGame]
/// don't need to know which transport they're talking to.
///
/// NOTE: the exact `nearby_connections` call signatures below reflect the
/// package's documented usage but have not been compiled against it in
/// this environment (no Flutter/Dart SDK available here) — double check
/// them against the installed package version once you run `flutter pub get`.
class BluetoothConnection implements GameConnection {
  BluetoothConnection({required this.userName, required this.isHost});

  final String userName;
  final bool isHost;

  /// Bluetooth has no "room code" step — nearby devices discover and join
  /// directly — so lobby messages just carry this placeholder instead.
  static const _bluetoothRoomLabel = 'BLUETOOTH';
  static const _hostId = 'host';

  final _controller = StreamController<GameMessage>.broadcast();
  final Map<String, String> _endpointNames = {}; // endpointId -> display name
  final LocalRoom _room = LocalRoom();
  bool _connected = false;

  @override
  Stream<GameMessage> get messages => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (isHost) {
      _room.addPlayer(_hostId, userName);
      _controller.add(GameMessage(MsgType.roomCreated, {
        'code': _bluetoothRoomLabel,
        'youId': _hostId,
        'team': _room.players[_hostId]!.team.value,
      }));
      await Nearby().startAdvertising(
        userName,
        Strategy.P2P_STAR,
        onConnectionInitiated: (id, info) {
          _endpointNames[id] = info.endpointName;
          Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload);
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connected = true;
            final name = _endpointNames[id] ?? id;
            _room.addPlayer(id, name);
            _emitTo(id, MsgType.roomJoined, {
              'code': _bluetoothRoomLabel,
              'youId': id,
              'team': _room.players[id]!.team.value,
            });
            _broadcastLobby();
          }
        },
        onDisconnected: (id) {
          _room.removePlayer(id);
          _endpointNames.remove(id);
          _broadcastLobby();
        },
      );
    } else {
      await Nearby().startDiscovery(
        userName,
        Strategy.P2P_STAR,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (endId, info) {
              _endpointNames[endId] = info.endpointName;
              Nearby().acceptConnection(endId, onPayLoadRecieved: _onPayload);
            },
            onConnectionResult: (endId, status) {
              if (status == Status.CONNECTED) _connected = true;
            },
            onDisconnected: (_) => _connected = false,
          );
        },
        onEndpointLost: (_) {},
      );
    }
  }

  void _onPayload(String fromId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    final message = GameMessage.decode(utf8.decode(payload.bytes!));
    if (isHost) {
      _handleAsHost(fromId, message);
    } else {
      _controller.add(message);
    }
  }

  /// Referees lobby/ready/game-start the same way server/src/index.js does,
  /// then relays every other (gameplay) message on to every other peer.
  void _handleAsHost(String fromId, GameMessage message) {
    switch (message.type) {
      case MsgType.setReady:
        _room.setReady(fromId, message.payload['ready'] as bool? ?? false);
        _broadcastLobby();
        if (_room.allReady) _startGame();
        break;
      default:
        // The host already applied its own local actions directly (see
        // WarGame), so only re-emit messages that came from a real peer.
        if (fromId != _hostId) {
          _controller.add(message);
        }
        _relay(message, exceptEndpoint: fromId == _hostId ? null : fromId);
        break;
    }
  }

  void _broadcastLobby() {
    final state = {
      'code': _bluetoothRoomLabel,
      'status': 'lobby',
      'players': _room.toLobbyPlayers(),
    };
    _controller.add(GameMessage(MsgType.lobbyState, state));
    _relay(GameMessage(MsgType.lobbyState, state));
  }

  void _startGame() {
    final payload = {
      'players': _room.players.values
          .map((p) => {'id': p.id, 'name': p.name, 'team': p.team.value, 'x': p.x, 'y': p.y})
          .toList(),
    };
    _controller.add(GameMessage(MsgType.gameStart, payload));
    _relay(GameMessage(MsgType.gameStart, payload));
  }

  void _emitTo(String endpointId, String type, Map<String, dynamic> payload) {
    _sendBytes(endpointId, GameMessage(type, payload));
  }

  void _relay(GameMessage message, {String? exceptEndpoint}) {
    for (final id in _endpointNames.keys) {
      if (id != exceptEndpoint) _sendBytes(id, message);
    }
  }

  void _sendBytes(String endpointId, GameMessage message) {
    Nearby().sendBytesPayload(endpointId, Uint8List.fromList(utf8.encode(message.encode())));
  }

  @override
  void send(GameMessage message) {
    if (isHost) {
      // The host is a player too: referee its own messages locally exactly
      // like an incoming peer message, then relay to everyone else.
      _handleAsHost(_hostId, message);
    } else {
      for (final id in _endpointNames.keys) {
        _sendBytes(id, message);
      }
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    if (isHost) {
      await Nearby().stopAdvertising();
    } else {
      await Nearby().stopDiscovery();
    }
    await Nearby().stopAllEndpoints();
  }
}
