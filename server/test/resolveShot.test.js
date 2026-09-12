const { RoomManager, Room } = require('../src/roomManager');
const { resolveShot } = require('../src/index');

describe('resolveShot', () => {
  function setup() {
    const rm = new RoomManager();
    const room = rm.createRoom('host1');
    const shooter = room.addPlayer('shooter', 'Alice'); // red
    const enemy = room.addPlayer('enemy', 'Bob'); // blue
    const ally = room.addPlayer('ally', 'Carol'); // red (balances to red)
    return { room, shooter, enemy, ally };
  }

  test('hits an enemy directly in front of the shooter', () => {
    const { room, shooter, enemy } = setup();
    enemy.x = 100;
    enemy.y = 0;
    const target = resolveShot(room, shooter, 0, 0, 0); // aiming along +x axis
    expect(target).toBe(enemy);
  });

  test('never hits a teammate, even standing on the shot line', () => {
    const { room, shooter, ally, enemy } = setup();
    ally.x = 100;
    ally.y = 0;
    enemy.x = 9999; // move the enemy well out of the way for this case
    enemy.y = 9999;
    const target = resolveShot(room, shooter, 0, 0, 0);
    expect(target).toBeNull();
  });

  test('misses when the enemy is outside the angular cone', () => {
    const { room, shooter, enemy } = setup();
    enemy.x = 0;
    enemy.y = 100; // 90 degrees off from the shot angle
    const target = resolveShot(room, shooter, 0, 0, 0);
    expect(target).toBeNull();
  });

  test('misses when the enemy is beyond hit range', () => {
    const { room, shooter, enemy } = setup();
    enemy.x = 1000;
    enemy.y = 0;
    const target = resolveShot(room, shooter, 0, 0, 0);
    expect(target).toBeNull();
  });

  test('never hits an already-dead player', () => {
    const { room, shooter, enemy } = setup();
    enemy.x = 100;
    enemy.y = 0;
    enemy.alive = false;
    const target = resolveShot(room, shooter, 0, 0, 0);
    expect(target).toBeNull();
  });
});
