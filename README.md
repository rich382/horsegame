# Livia's Stable

A single-player Hunter/Jumper farm and show career game, built in Godot 4.7.

You run a small show barn: care for horses, school them at home, haul to the **Ashford County Schooling Show**, and grow from a four-stall starter farm into a competitive H/J program. This is a management sim with a cinematic course-run, not a riding-physics game.

**Repo:** https://github.com/rich382/horsegame

| Doc | Path |
|---|---|
| Design spec | [`docs/DESIGN.md`](docs/DESIGN.md) |
| Changelog | [`docs/CHANGELOG.md`](docs/CHANGELOG.md) |
| Session logs | [`docs/log/`](docs/log/) |

Durable notes go in `docs/`. Do not leave design or session records only in temp folders.

## Requirements

- **Godot 4.7.x** (developed against 4.7-stable; feature tag `4.7`, Forward Plus)
- Windows first, 1920×1080, mouse + keyboard

## Run

Open this folder in Godot, or from a console:

```
godot --path .
```

Headless smoke:

```
godot --headless --path . --quit-after 2
```

Press **Play (F5)** in Godot. Name the horse, pick a coat, then orbit the **3D** barn, jumps, and fence. The horse is a 3D mesh (coat tint).

- **Left-drag** to orbit, **mouse wheel** to zoom
- **Feed / Pick / In-Out / Groom** — walk over and do the chore
- **School** — lead the horse to the arena; afternoon flat, poles, or gymnastic (gymnastic shows a recap)
- **Shop** — walk to the aisle; hay, grain, farrier, boots, martingale, footing
- **Next Phase** / **N** advances Morning → Afternoon → Evening
- **Sleep** / **M** skips to the next morning
- **Save** / **F5** writes slot 1
- **Pause** / **P** (do not use Esc inside the editor — Esc stops Play)

Ashford (entry, haul, 0.80 m jumper) is next.

## Vertical slice

Own one horse (name + coat at new game), daily care, school at home, enter the **0.80 m jumper** at Ashford, take a ribbon, spend it on footing or boots.
