# Game Physics

This project uses predictable arcade platformer physics. Level design should be planned in tiles, then checked against the pixel values below.

## Core Unit

| Rule | Value |
| --- | ---: |
| Tile size | 32 px |
| Gravity | 980 px/s^2 |
| Player run speed | 192 px/s = 6 tiles/s |
| Player jump velocity | -434 px/s |
| Player acceleration | 1600 px/s^2 |
| Player friction | 1400 px/s^2 |
| Coyote time | 0.10 s |
| Jump buffer | 0.10 s |

## Jump And Run

| Calculation | Value |
| --- | ---: |
| Max jump height | about 96 px = 3 tiles |
| Practical safe rise | 80 px = 2.5 tiles |
| Time to jump apex | about 0.44 s |
| Same-height airtime | about 0.89 s |
| Full-speed same-height jump distance | about 170 px = 5.3 tiles |
| Practical safe flat gap | 160 px = 5 tiles |
| Time to full run speed | about 0.12 s |
| Stop distance from full run | about 13 px = 0.4 tiles |

Level rule: a normal route should keep required rises at or below 2.5 tiles and required flat running gaps at or below 5 tiles. Larger gaps need a special setup, moving platform, or explicit ability gate.

Jump input rule: players get 0.10 seconds of coyote time after leaving a ledge and 0.10 seconds of jump buffering before landing. These values do not change the measured jump height or gap distance; they make the same physics more predictable for human input.

## Player Movement

Kira, Marina, and Ryne share the same base run and jump model. They should feel different through attacks and skills, not through hidden movement drift.

| Character | Run | Jump | Dodge |
| --- | ---: | ---: | ---: |
| Kira | 6 tiles/s | 3 tiles high | 4 tiles |
| Marina | 6 tiles/s | 3 tiles high | 4 tiles |
| Ryne | 6 tiles/s | 3 tiles high | 4 tiles |

## Player Combat

| Action | Pixel Value | Tile Value |
| --- | ---: | ---: |
| Kira melee hitbox | 64 px | 2 tiles |
| Kira thrown fire orb | 160 px | 5 tiles |
| Kira fire bomb | 416 px | 13 tiles |
| Marina water orb | 160 px | 5 tiles |
| Marina water burst | 320 px | 10 tiles |
| Ryne melee hitbox | 48 px | 1.5 tiles |
| Ryne shockwave | 96 px | 3 tiles |

Combat rule: short melee should read as close-range commitment, projectiles should read as lane control, and skill ranges should be long enough to be planned from tile spacing.

## Grunt Physics

| Behavior | Pixel Value | Tile Value |
| --- | ---: | ---: |
| Patrol speed | 96 px/s | 3 tiles/s |
| Chase speed | 128 px/s | 4 tiles/s |
| Retreat speed | 96 px/s | 3 tiles/s |
| Personal space | 48 px | 1.5 tiles |
| Attack range | 64 px | 2 tiles |
| Vertical attack tolerance | 48 px | 1.5 tiles |
| Detection radius | 192 px | 6 tiles |
| Attack wind-up | 0.34 s | readable tell |
| Attack recovery | 0.28 s | punish window |

Enemy placement rule: leave at least 6 tiles of readable approach distance before a Grunt can detect the player, and avoid placing Grunts where the player lands directly inside the 2-tile attack range.

## Map Design Rules

| Situation | Recommended Limit |
| --- | ---: |
| Normal upward platform step | <= 2.5 tiles |
| Normal flat jump gap | <= 5 tiles |
| Checkpoint-to-danger recovery space | >= 3 tiles |
| Grunt approach space | >= 6 tiles |
| Melee training space | >= 2 tiles between player and enemy |

These are the default rules for Ember Fields and Drowned Coast. Boss arenas can override them, but each override should be documented with the boss behavior.
