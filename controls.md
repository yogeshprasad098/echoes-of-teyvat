# Controls Reference — Echoes of Teyvat

## Input Map (Godot Action Names)

| Action Name | Primary Key | Secondary Key | Notes |
|-------------|-------------|---------------|-------|
| `move_left` | A | Left Arrow | |
| `move_right` | D | Right Arrow | |
| `jump` | Space | W / Up Arrow | Requires `is_on_floor()` |
| `attack` | Z | Left Mouse Button | Triggers 3-hit combo |
| `skill` | X | Right Mouse Button | 8-second cooldown |
| `dodge` | Shift | — | 0.4s i-frame window |
| `switch_1` | 1 | — | Reserved |
| `switch_2` | 2 | — | Reserved |
| `switch_3` | 3 | — | Reserved |

## Combat Notes

- **Normal Attack combo:** Press `attack` up to 3 times. Combo resets after 0.6s window or after 3rd hit.
- **Elemental Skill (Fire Bomb):** Press `skill` — throws a fire bomb projectile. Cooldown shown on HUD.
- **Dodge Roll:** Press `dodge` for a burst of horizontal speed + invincibility frames (0.4s). Works in air.

## Character Switching
Keys 1, 2, 3 are already registered in the input map as `switch_1`, `switch_2`, `switch_3` for a later character-switching update.
