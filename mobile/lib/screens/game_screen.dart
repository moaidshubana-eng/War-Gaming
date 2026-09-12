import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/hud/hud_overlay.dart';
import '../game/hud/joystick.dart';
import '../game/war_game.dart';
import '../models/player_state.dart';
import '../models/team.dart';
import '../network/game_connection.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.connection,
    required this.localPlayerId,
    required this.initialPlayers,
  });

  final GameConnection connection;
  final String localPlayerId;
  final Map<String, PlayerState> initialPlayers;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WarGame _game;
  Timer? _hudTimer;

  @override
  void initState() {
    super.initState();
    _game = WarGame(
      localPlayerId: widget.localPlayerId,
      connection: widget.connection,
      initialPlayers: widget.initialPlayers,
      onGameOver: _onGameOver,
    );
    // The HUD (health/alive counts) reads mutable PlayerState fields that
    // the game engine updates every frame; a light periodic rebuild is
    // simpler here than wiring a ChangeNotifier through FlameGame.
    _hudTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    super.dispose();
  }

  void _onGameOver(Team winner) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(winner: winner, didWin: _game.localPlayer.team == winner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localPlayer = widget.initialPlayers[widget.localPlayerId]!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HudOverlay(
              player: localPlayer,
              teamCounts: {
                Team.red: widget.initialPlayers.values.where((p) => p.team == Team.red && p.alive).length,
                Team.blue: widget.initialPlayers.values.where((p) => p.team == Team.blue && p.alive).length,
              },
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: VirtualJoystick(
              onChanged: (direction) => _game.setMoveDirection(Vector2(direction.dx, direction.dy)),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: GestureDetector(
              onTap: _game.shoot,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withAlpha(200)),
                child: const Icon(Icons.gps_fixed, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
