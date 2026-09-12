/**
 * Shared gameplay constants. These must stay in sync with the Dart mirrors:
 *   - mobile/lib/network/host_authority.dart (shot validation on the
 *     Bluetooth host, which referees local games the way this server
 *     referees online ones)
 *   - mobile/lib/game/war_game.dart (movement speed, arena size)
 */

const ARENA_WIDTH = 800;
const ARENA_HEIGHT = 600;
const PLAYER_MAX_HEALTH = 100;
const PLAYER_SPEED = 200; // px/sec, applied client-side
const BULLET_DAMAGE = 20;
const HIT_RANGE = 260; // px, must match BulletComponent.maxRange
const HIT_CONE_RADIANS = 0.18; // angular tolerance for a hit
const MAX_PLAYERS_PER_TEAM = 4;

const TEAMS = Object.freeze({ RED: 'red', BLUE: 'blue' });

module.exports = {
  ARENA_WIDTH,
  ARENA_HEIGHT,
  PLAYER_MAX_HEALTH,
  PLAYER_SPEED,
  BULLET_DAMAGE,
  HIT_RANGE,
  HIT_CONE_RADIANS,
  MAX_PLAYERS_PER_TEAM,
  TEAMS,
};
