# Echoes of Teyvat

Echoes of Teyvat is a 2D pixel-art action RPG prototype built in Godot. The current build focuses on Kira, a pyro fighter, exploring Ember Fields, fighting Grunts, and reaching the level goal while avoiding lava gaps.

This repo contains the Godot project, gameplay scripts, scenes, generated pixel assets, export presets, tests, and GitHub Actions workflows used to build and deploy the game.

## Play

Browser build:

https://yogeshprasad098.github.io/echoes-of-teyvat/

Windows builds are available from GitHub Releases:

https://github.com/yogeshprasad098/echoes-of-teyvat/releases

Each release includes:

- `EchoesOfTeyvat-windows-x86_64.zip`

The Web build is hosted through GitHub Pages instead of being attached as a release zip.

## Requirements

- Godot 4.6.x
- Git
- A modern browser for the Web build
- Windows for running the exported `.exe`

## Run Locally

1. Install Godot 4.6.
2. Clone this repository.
3. Open `project.godot` in the Godot editor.
4. Press `F5` to run the main scene.

The project is configured to start from:

```text
res://scenes/main.tscn
```

## Controls

| Action | Input |
| --- | --- |
| Move left | `A` / Left Arrow |
| Move right | `D` / Right Arrow |
| Jump | `Space` / `W` / Up Arrow |
| Normal attack | `Z` / Left Click |
| Fire Bomb | `X` / Right Click |
| Dodge roll | Shift |
| Character slot 1 | `1` |
| Character slot 2 | `2` |
| Character slot 3 | `3` |

## Current Gameplay

- Kira movement, jumping, dodge roll, temporary invincibility, and hit reactions
- Three-hit normal attack combo
- Fire Bomb skill with cooldown and 50 damage
- Grunt enemy patrol, chase, attack, health, damage feedback, and death behavior
- Ember Fields level with platforms, lava gaps, collision, parallax backgrounds, and a reachable goal
- HUD for player health and Fire Bomb cooldown
- Start screen, restart flow, and exit flow

## Project Layout

```text
assets/              Character, enemy, environment, and background art
controls.md          Player control reference
export_presets.cfg   Godot export presets for Windows and Web
project.godot        Godot project configuration
resources/           Shared SpriteFrames, TileSets, and other reusable resources
scenes/              Godot scene files
scripts/             GDScript gameplay, UI, enemy, projectile, and area logic
test/                Godot smoke tests and visual capture scripts
tools/               Asset generation and wiring helpers
```

Generated build output is written to `builds/` and is ignored by Git.

## Development Workflow

Use feature branches for changes:

```bash
git switch -c feature/my-change
```

Open a pull request into `main`. Pull requests run CI to validate both Windows and Web exports before merge.

After a PR is merged into `main`, the Web build is deployed to GitHub Pages.

To ship a versioned release:

```bash
git checkout main
git pull origin main
git tag v0.1.1
git push origin v0.1.1
```

Tag releases run Windows export and Web deploy in parallel. The GitHub Release is published only after both jobs pass.

## Automation

There are two active GitHub Actions workflows:

- `Godot Pull Request CI`
  - Runs on pull requests into `main`
  - Validates Windows export
  - Validates Web export
  - Does not deploy

- `Godot Deploy`
  - Runs on pushes to `main`
  - Runs on tags matching `v*`
  - Supports manual `workflow_dispatch`
  - Deploys Web to GitHub Pages
  - Builds and uploads the Windows zip for tagged releases

## Testing

Run Godot test scripts from the editor or with the Godot CLI:

```bash
godot --headless --path . --script test/core_demo.gd
```

Visual capture helpers live in `test/`. Generated artifacts should stay under ignored artifact/output folders.

## Releases

Release artifacts are produced by GitHub Actions from immutable `v*` tags. The release page contains the Windows download and a link to the live Web build.

The latest playable Web build is always available at:

https://yogeshprasad098.github.io/echoes-of-teyvat/

## Notes

Echoes of Teyvat is a fan-inspired prototype and is not affiliated with or endorsed by any external game studio. Project assets in this repository are generated for this prototype unless a file or folder states otherwise.
