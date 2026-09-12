/// The two sides a player can be assigned to. Kept intentionally to two
/// teams for the MVP — see docs/ARCHITECTURE.md for why.
enum Team { red, blue }

extension TeamX on Team {
  String get value => this == Team.red ? 'red' : 'blue';

  static Team fromString(String value) => value == 'red' ? Team.red : Team.blue;
}
