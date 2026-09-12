const { customAlphabet } = require('nanoid');
const { TEAMS, MAX_PLAYERS_PER_TEAM, PLAYER_MAX_HEALTH } = require('./gameConstants');

// Alphabet avoids visually-confusable characters (0/O, 1/I) since players
// read this code aloud or type it on a phone keyboard.
const generateCode = customAlphabet('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 5);

class Room {
  constructor(code, hostId) {
    this.code = code;
    this.hostId = hostId;
    this.players = new Map(); // id -> player
    this.status = 'lobby'; // 'lobby' | 'playing' | 'finished'
    this.createdAt = Date.now();
  }

  addPlayer(id, name) {
    if (this.players.size >= MAX_PLAYERS_PER_TEAM * 2) {
      throw new Error('room_full');
    }
    const team = this._pickBalancedTeam();
    const player = {
      id,
      name,
      team,
      x: 0,
      y: 0,
      angle: 0,
      health: PLAYER_MAX_HEALTH,
      ready: false,
      alive: true,
      score: 0,
    };
    this.players.set(id, player);
    return player;
  }

  removePlayer(id) {
    this.players.delete(id);
  }

  _pickBalancedTeam() {
    const { red, blue } = this.teamCounts();
    return red <= blue ? TEAMS.RED : TEAMS.BLUE;
  }

  setReady(id, ready) {
    const player = this.players.get(id);
    if (player) player.ready = ready;
  }

  allReady() {
    if (this.players.size < 2) return false;
    return [...this.players.values()].every((p) => p.ready);
  }

  isEmpty() {
    return this.players.size === 0;
  }

  teamCounts() {
    let red = 0;
    let blue = 0;
    for (const p of this.players.values()) {
      if (p.team === TEAMS.RED) red += 1;
      else blue += 1;
    }
    return { red, blue };
  }

  /** Returns the winning team code, 'draw', or null if the game continues. */
  winningTeam() {
    let aliveRed = 0;
    let aliveBlue = 0;
    for (const p of this.players.values()) {
      if (!p.alive) continue;
      if (p.team === TEAMS.RED) aliveRed += 1;
      else aliveBlue += 1;
    }
    if (aliveRed === 0 && aliveBlue === 0) return 'draw';
    if (aliveRed === 0) return TEAMS.BLUE;
    if (aliveBlue === 0) return TEAMS.RED;
    return null;
  }

  toLobbyState() {
    return {
      code: this.code,
      status: this.status,
      players: [...this.players.values()].map((p) => ({
        id: p.id,
        name: p.name,
        team: p.team,
        ready: p.ready,
      })),
    };
  }
}

class RoomManager {
  constructor() {
    this.rooms = new Map();
  }

  createRoom(hostId) {
    let code;
    do {
      code = generateCode();
    } while (this.rooms.has(code));
    const room = new Room(code, hostId);
    this.rooms.set(code, room);
    return room;
  }

  getRoom(code) {
    return this.rooms.get(code);
  }

  deleteRoom(code) {
    this.rooms.delete(code);
  }

  joinRoom(code, id, name) {
    const room = this.rooms.get(code);
    if (!room) throw new Error('room_not_found');
    if (room.status !== 'lobby') throw new Error('room_in_progress');
    const player = room.addPlayer(id, name);
    return { room, player };
  }
}

module.exports = { Room, RoomManager };
