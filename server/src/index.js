const http = require('http');
const WebSocket = require('ws');
const { RoomManager } = require('./roomManager');
const { BULLET_DAMAGE, HIT_RANGE, HIT_CONE_RADIANS } = require('./gameConstants');

const PORT = process.env.PORT || 8080;

const roomManager = new RoomManager();
const server = http.createServer();
const wss = new WebSocket.Server({ server });

let nextId = 1;
const clients = new Map(); // ws -> { id, code }

function send(ws, type, payload) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type, payload }));
  }
}

/** Sends to every socket in the same room, optionally skipping one (the sender). */
function broadcast(room, type, payload, exceptWs) {
  for (const [ws, meta] of clients.entries()) {
    if (meta.code === room.code && ws !== exceptWs) {
      send(ws, type, payload);
    }
  }
}

function broadcastLobby(room) {
  broadcast(room, 'lobby_state', room.toLobbyState());
}

function normalizeAngle(a) {
  let result = a;
  while (result > Math.PI) result -= 2 * Math.PI;
  while (result < -Math.PI) result += 2 * Math.PI;
  return result;
}

/**
 * Simplified server-side hit validation: rather than simulating full bullet
 * physics, we trust the shooter's reported muzzle position/angle (already
 * broadcast for the tracer) and check which enemy is close to that ray.
 * This stops the obvious client-side cheat (reporting a kill on a player
 * who wasn't in front of you) without needing a full physics step per shot.
 */
function resolveShot(room, shooter, shotX, shotY, shotAngle) {
  for (const target of room.players.values()) {
    if (target.id === shooter.id || target.team === shooter.team || !target.alive) {
      continue;
    }
    const dx = target.x - shotX;
    const dy = target.y - shotY;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const angleToTarget = Math.atan2(dy, dx);
    const angleDiff = Math.abs(normalizeAngle(angleToTarget - shotAngle));
    if (dist < HIT_RANGE && angleDiff < HIT_CONE_RADIANS) {
      return target;
    }
  }
  return null;
}

function handleMessage(ws, meta, msg) {
  const { type, payload = {} } = msg;
  switch (type) {
    case 'create_room': {
      const room = roomManager.createRoom(meta.id);
      const player = room.addPlayer(meta.id, payload.name || 'Player');
      meta.code = room.code;
      send(ws, 'room_created', { code: room.code, youId: meta.id, team: player.team });
      broadcastLobby(room);
      break;
    }

    case 'join_room': {
      try {
        const { room, player } = roomManager.joinRoom(payload.code, meta.id, payload.name || 'Player');
        meta.code = room.code;
        send(ws, 'room_joined', { code: room.code, youId: meta.id, team: player.team });
        broadcastLobby(room);
      } catch (err) {
        send(ws, 'error', { reason: err.message });
      }
      break;
    }

    case 'set_ready': {
      const room = roomManager.getRoom(meta.code);
      if (!room) return;
      room.setReady(meta.id, !!payload.ready);
      broadcastLobby(room);
      if (room.status === 'lobby' && room.allReady()) {
        room.status = 'playing';
        const players = [...room.players.values()];
        // broadcast() has no exceptWs here, so it already reaches every
        // socket in the room including this one — no extra send() needed.
        broadcast(room, 'game_start', { players });
      }
      break;
    }

    case 'player_state': {
      const room = roomManager.getRoom(meta.code);
      if (!room || room.status !== 'playing') return;
      const player = room.players.get(meta.id);
      if (!player || !player.alive) return;
      player.x = payload.x;
      player.y = payload.y;
      player.angle = payload.angle;
      broadcast(room, 'player_state', { id: meta.id, x: player.x, y: player.y, angle: player.angle }, ws);
      break;
    }

    case 'shoot': {
      const room = roomManager.getRoom(meta.code);
      if (!room || room.status !== 'playing') return;
      const shooter = room.players.get(meta.id);
      if (!shooter || !shooter.alive) return;

      broadcast(room, 'shoot', { id: meta.id, x: payload.x, y: payload.y, angle: payload.angle }, ws);

      const target = resolveShot(room, shooter, payload.x, payload.y, payload.angle);
      if (!target) return;

      target.health = Math.max(0, target.health - BULLET_DAMAGE);
      target.alive = target.health > 0;
      const hitPayload = { id: target.id, health: target.health, alive: target.alive, by: shooter.id };
      // No exceptWs: every socket in the room, including the shooter, needs
      // this update.
      broadcast(room, 'player_hit', hitPayload);

      if (!target.alive) {
        shooter.score += 1;
        const winner = room.winningTeam();
        if (winner) {
          room.status = 'finished';
          broadcast(room, 'game_over', { winner });
        }
      }
      break;
    }

    case 'leave_room': {
      const room = roomManager.getRoom(meta.code);
      if (room) {
        room.removePlayer(meta.id);
        meta.code = null;
        if (room.isEmpty()) roomManager.deleteRoom(room.code);
        else broadcastLobby(room);
      }
      break;
    }

    default:
      break;
  }
}

wss.on('connection', (ws) => {
  const id = `p${nextId}`;
  nextId += 1;
  clients.set(ws, { id, code: null });
  send(ws, 'connected', { id });

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch (err) {
      return;
    }
    handleMessage(ws, clients.get(ws), msg);
  });

  ws.on('close', () => {
    const meta = clients.get(ws);
    clients.delete(ws);
    if (meta && meta.code) {
      const room = roomManager.getRoom(meta.code);
      if (room) {
        room.removePlayer(meta.id);
        if (room.isEmpty()) roomManager.deleteRoom(room.code);
        else broadcastLobby(room);
      }
    }
  });
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`War Gaming server listening on port ${PORT}`);
  });
}

module.exports = { server, roomManager, resolveShot };
