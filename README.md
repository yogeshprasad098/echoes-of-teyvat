# Echoes of Teyvat

A 2D side-scrolling action RPG inspired by Genshin Impact. Control elemental heroes through themed worlds, trigger elemental reactions by switching characters mid-combat.

**Solo project — Yogesh | Godot 4.6 | Pixel Art 2D Action RPG**

---

## How to Run

### Option 1 — Godot Editor
1. Install [Godot 4.6](https://godotengine.org/download)
2. Open Godot → Import → select this folder's `project.godot`
3. Press **F5** to run

### Option 2 — Windows .exe
1. Download the Windows zip from the latest GitHub Release
2. Extract it
3. Double-click `EchoesOfTeyvat.exe`

### Option 3 — Browser
Open the latest Web build on GitHub Pages:

https://yogeshprasad098.github.io/echoes-of-teyvat/

---

## Automation

Pull requests to `main` run CI for both Windows and Web exports.

Pushes to `main` deploy the latest Web build to GitHub Pages as the staging/live browser build.

Production releases start when a tag starting with `v` is pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```

Release builds export Windows and deploy Web in parallel. When both jobs pass, GitHub Releases is updated with:

- `EchoesOfTeyvat-windows-x86_64.zip`

The release notes link to the live Web build on GitHub Pages.

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
| Switch Character 1 | 1 *(reserved)* |
| Switch Character 2 | 2 *(reserved)* |
| Switch Character 3 | 3 *(reserved)* |

---

## Current Build

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
