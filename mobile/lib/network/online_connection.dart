import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'game_connection.dart';
import 'game_message.dart';

/// Transport for internet play: a plain WebSocket to the authoritative
/// Node.js server in server/src/index.js.
class OnlineConnection implements GameConnection {
  OnlineConnection(this.serverUrl);

  final String serverUrl;

  WebSocketChannel? _channel;
  final _controller = StreamController<GameMessage>.broadcast();
  bool _connected = false;

  @override
  Stream<GameMessage> get messages => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _connected = true;
    _channel!.stream.listen(
      (raw) => _controller.add(GameMessage.decode(raw as String)),
      onDone: () => _connected = false,
      onError: (Object _, StackTrace __) => _connected = false,
      cancelOnError: false,
    );
  }

  @override
  void send(GameMessage message) {
    if (_connected) {
      _channel?.sink.add(message.encode());
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await _channel?.sink.close();
  }
}
