# Echoes of Teyvat

A 2D side-scrolling action RPG inspired by Genshin Impact. Control elemental heroes through themed worlds, trigger elemental reactions by switching characters mid-combat.

**Solo project — Yogesh | Godot 4.6 | CPSC Game Development Course**

---

## How to Run

### Option 1 — Godot Editor
1. Install [Godot 4.6](https://godotengine.org/download)
2. Open Godot → Import → select this folder's `project.godot`
3. Press **F5** to run

### Option 2 — Windows .exe
1. Download `builds/windows/EchoesOfTeyvat.exe`
2. Double-click to run — no installation needed

### Option 3 — Browser
1. Open `builds/web/index.html` in Chrome (requires a local server)
2. Or: `python3 -m http.server 8000` in `builds/web/`, then open `localhost:8000`

---

## Controls

| Action | Keys |
|--------|------|
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Jump | Space / W / Up Arrow |
| Normal Attack (3-hit combo) | Z / Left Click |
| Elemental Skill | X / Right Click |
| Dodge Roll (i-frames) | Shift |
| Switch Character 1 | 1 *(Milestone 2)* |
| Switch Character 2 | 2 *(Milestone 2)* |
| Switch Character 3 | 3 *(Milestone 2)* |

---

## Milestone 1 Scope

- **Kira (Pyro)** — movement, jump, 3-hit attack combo, Fire Bomb skill, dodge roll
- **Area 1 — Ember Fields** — volcanic tilemap, parallax background, collision
- **Grunt enemy** — patrol AI, ledge detection, chase behavior
- **Minimal HUD** — health bar + skill cooldown

---

## Project Structure

```
assets/          # Sprites, tilesets, backgrounds, SFX
scenes/          # Godot scene files (.tscn)
scripts/         # GDScript files (.gd)
resources/       # Shared resources (.tres)
docs/            # Documentation and planning
builds/          # Exported game builds
```

---

## Credits

Assets used in this project (add entries as you import):

| Asset | Author | Source | License |
|-------|--------|--------|---------|
| *(placeholder — fill in before submission)* | | | |

All assets used are free/open-source. See individual license files in `assets/` subdirectories.

---

*Engine: Godot 4.6 | Platform: Windows .exe + HTML5 | Style: Pixel Art 2D*
