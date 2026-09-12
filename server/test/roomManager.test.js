const { RoomManager } = require('../src/roomManager');

describe('RoomManager', () => {
  test('creates a room with a unique 5-character code', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    expect(room.code).toHaveLength(5);
    expect(rm.getRoom(room.code)).toBe(room);
  });

  test('balances teams as players join', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    room.addPlayer('p1', 'Alice');
    room.addPlayer('p2', 'Bob');
    room.addPlayer('p3', 'Carol');
    const counts = room.teamCounts();
    expect(counts.red + counts.blue).toBe(3);
    expect(Math.abs(counts.red - counts.blue)).toBeLessThanOrEqual(1);
  });

  test('rejects joining a full room', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    for (let i = 0; i < 8; i += 1) room.addPlayer(`p${i}`, `Player${i}`);
    expect(() => room.addPlayer('p8', 'Extra')).toThrow('room_full');
  });

  test('joinRoom throws for an unknown code', () => {
    const rm = new RoomManager();
    expect(() => rm.joinRoom('ZZZZZ', 'p1', 'Alice')).toThrow('room_not_found');
  });

  test('joinRoom throws once the room has started', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    room.status = 'playing';
    expect(() => rm.joinRoom(room.code, 'p1', 'Alice')).toThrow('room_in_progress');
  });

  test('allReady requires at least 2 players, all marked ready', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    room.addPlayer('p1', 'Alice');
    expect(room.allReady()).toBe(false);
    room.addPlayer('p2', 'Bob');
    room.setReady('p1', true);
    expect(room.allReady()).toBe(false);
    room.setReady('p2', true);
    expect(room.allReady()).toBe(true);
  });

  test('winningTeam reflects an eliminated team', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    room.addPlayer('p1', 'Alice'); // red (first player)
    const p2 = room.addPlayer('p2', 'Bob'); // blue
    expect(room.winningTeam()).toBeNull();
    p2.alive = false;
    expect(room.winningTeam()).toBe('red');
  });

  test('removePlayer frees the room and RoomManager reports it empty', () => {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    room.addPlayer('p1', 'Alice');
    room.removePlayer('p1');
    expect(room.isEmpty()).toBe(true);
  });
});
