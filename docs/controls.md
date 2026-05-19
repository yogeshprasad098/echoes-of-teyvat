# Controls Reference — Echoes of Teyvat

## Input Map (Godot Action Names)

| Action Name | Primary Key | Secondary Key | Notes |
|-------------|-------------|---------------|-------|
| `move_left` | A | Left Arrow | |
| `move_right` | D | Right Arrow | |
| `jump` | Space | W / Up Arrow | Requires `is_on_floor()` |
| `attack` | Z | Left Mouse Button | Triggers 3-hit combo |
| `throw` | C | — | Kira throws a fire orb |
| `skill` | X | Right Mouse Button | 8-second cooldown |
| `dodge` | Shift | — | 4-tile dodge burst |
| `switch_1` | 1 | — | Switch to Kira |
| `switch_2` | 2 | — | Switch to Marina |
| `switch_3` | 3 | — | Switch to Ryne |

## Combat Notes

- **Normal attack:** Press `attack` for the active character's basic attack or combo.
- **Kira throw:** Press `throw` to fire a small Pyro orb. This is separate from Kira's melee combo.
- **Elemental skill:** Press `skill` for the active character's skill. Cooldown is shown on the HUD.
- **Dodge:** Press `dodge` for a predictable 4-tile horizontal burst. Kira also gets invincibility during this window.

## Character Switching
Keys 1, 2, 3 switch between Kira, Marina, and Ryne when a full party is available in the current area.
