import 'game_message.dart';

/// Abstraction over how this device reaches the other players — either the
/// online WebSocket server ([OnlineConnection]) or a nearby Bluetooth/Wi-Fi
/// Direct host ([BluetoothConnection]). [WarGame] and the screens only ever
/// talk to this interface, so game and UI code never branch on transport.
abstract class GameConnection {
  Stream<GameMessage> get messages;
  bool get isConnected;

  Future<void> connect();
  void send(GameMessage message);
  Future<void> disconnect();
}
