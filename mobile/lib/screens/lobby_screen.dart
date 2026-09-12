import 'dart:async';

import 'package:flutter/material.dart';

import '../models/player_state.dart';
import '../models/team.dart';
import '../network/bluetooth_connection.dart';
import '../network/game_connection.dart';
import '../network/game_message.dart';
import '../network/online_connection.dart';
import 'game_screen.dart';
import 'home_screen.dart';

/// Point this at your deployed server for real online play, e.g.
/// 'wss://your-server.example.com'. Defaults to a local server for testing.
const String kDefaultServerUrl = 'ws://localhost:8080';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.mode});

  final ConnectionMode mode;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  GameConnection? _connection;
  StreamSubscription<GameMessage>? _sub;
  String? _myId;
  String? _roomCode;
  Team? _myTeam;
  List<Map<String, dynamic>> _lobbyPlayers = [];
  bool _ready = false;
  String? _error;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(text: 'لاعب');

  bool get _isOnline => widget.mode == ConnectionMode.online;

  @override
  void dispose() {
    _sub?.cancel();
    _connection?.disconnect();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createOrHost() async {
    final connection = _isOnline
        ? OnlineConnection(kDefaultServerUrl)
        : BluetoothConnection(userName: _nameController.text, isHost: true);
    await _attach(connection);
    if (_isOnline) {
      connection.send(GameMessage(MsgType.createRoom, {'name': _nameController.text}));
    }
    // In Bluetooth mode there is no explicit create step: BluetoothConnection
    // emits room_created itself as soon as it starts advertising.
  }

  Future<void> _join() async {
    final connection = _isOnline
        ? OnlineConnection(kDefaultServerUrl)
        : BluetoothConnection(userName: _nameController.text, isHost: false);
    await _attach(connection);
    if (_isOnline) {
      connection.send(GameMessage(MsgType.joinRoom, {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text,
      }));
    }
    // In Bluetooth mode, joining happens automatically once nearby_connections
    // finds and connects to a host; the host then emits room_joined for us.
  }

  Future<void> _attach(GameConnection connection) async {
    setState(() {
      _connection = connection;
      _error = null;
    });
    _sub = connection.messages.listen(_handleMessage);
    await connection.connect();
  }

  void _handleMessage(GameMessage message) {
    switch (message.type) {
      case MsgType.roomCreated:
      case MsgType.roomJoined:
        setState(() {
          _myId = message.payload['youId'] as String;
          _roomCode = message.payload['code'] as String?;
          _myTeam = TeamX.fromString(message.payload['team'] as String);
        });
        break;
      case MsgType.lobbyState:
        setState(() {
          _lobbyPlayers = List<Map<String, dynamic>>.from(message.payload['players'] as List);
        });
        break;
      case MsgType.gameStart:
        _goToGame(message.payload);
        break;
      case MsgType.error:
        setState(() => _error = message.payload['reason'] as String?);
        break;
    }
  }

  void _goToGame(Map<String, dynamic> payload) {
    final playersRaw = payload['players'] as List;
    final players = <String, PlayerState>{
      for (final raw in playersRaw)
        (raw['id'] as String): PlayerState(
          id: raw['id'] as String,
          name: raw['name'] as String,
          team: TeamX.fromString(raw['team'] as String),
          x: (raw['x'] as num?)?.toDouble() ?? 100,
          y: (raw['y'] as num?)?.toDouble() ?? 100,
        ),
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          connection: _connection!,
          localPlayerId: _myId!,
          initialPlayers: players,
        ),
      ),
    );
  }

  void _toggleReady() {
    setState(() => _ready = !_ready);
    _connection?.send(GameMessage(MsgType.setReady, {'ready': _ready}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102027),
      appBar: AppBar(
        title: Text(_isOnline ? 'غرفة أونلاين' : 'غرفة بلوتوث'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _connection == null ? _buildSetup() : _buildLobby(),
      ),
    );
  }

  Widget _buildSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'اسمك', labelStyle: TextStyle(color: Colors.white70)),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _createOrHost,
          child: Text(_isOnline ? 'إنشاء غرفة جديدة' : 'استضافة لعبة قريبة'),
        ),
        const SizedBox(height: 12),
        if (_isOnline) ...[
          TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'كود الغرفة', labelStyle: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton(
          onPressed: _join,
          child: Text(_isOnline ? 'الانضمام بالكود' : 'البحث عن لعبة قريبة'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ],
    );
  }

  Widget _buildLobby() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_roomCode != null)
          Text('كود الغرفة: $_roomCode', style: const TextStyle(color: Colors.white, fontSize: 20)),
        if (_myTeam != null)
          Text(
            'فريقك: ${_myTeam == Team.red ? "الأحمر" : "الأزرق"}',
            style: TextStyle(color: _myTeam == Team.red ? Colors.redAccent : Colors.blueAccent, fontSize: 18),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _lobbyPlayers.length,
            itemBuilder: (context, index) {
              final p = _lobbyPlayers[index];
              return ListTile(
                leading: Icon(Icons.circle, color: p['team'] == 'red' ? Colors.redAccent : Colors.blueAccent),
                title: Text(p['name'] as String, style: const TextStyle(color: Colors.white)),
                trailing: Icon(
                  p['ready'] == true ? Icons.check_circle : Icons.hourglass_empty,
                  color: p['ready'] == true ? Colors.greenAccent : Colors.white38,
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: _toggleReady,
          child: Text(_ready ? 'إلغاء الجاهزية' : 'أنا جاهز'),
        ),
      ],
    );
  }
}
