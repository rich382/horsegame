# 2026-08-16 — Better assets + starter horse

## Goal

Continue after the playable boot. Owner asked for better assets.

## Art

- **Kenney Nature Kit (CC0):** trees, bushes, fence, grass tufts, rock copied into `assets/models/nature/`.
- **Quaternius Farm Animal Pack (CC0):** `Horse.fbx` / `Horse.obj` in `assets/models/horse/`.
- **Generated tileable textures (1024²):** grass, arena footing, barn wood, barn roof. 2×2 composite of grass showed no obvious seam or landmark repeat.
- Sources listed in `assets/SOURCES.md`.

Defects to flag:
- Barn is still boxes with painted wood/roof (no Kenney barn in that kit).
- Horse is a low-poly farm horse, not a Warmblood hunter type. Coat is a body/mane tint, not a painted star marking yet.
- Kenney tiles are props, not a full modular barn.

## Code

- PR 3 start: `HorseDef` / `HorseState` / `HorseFactory` / Bayberry pairs (`express_sigma = 0` → scope 56).
- New-game overlay: name + Bay / Chestnut / Grey / Black.
- `FarmYard` builds grass, barn, arena, jumps, Kenney trees/fence.
- `HorsePresenter` instances the FBX (OBJ fallback), scales to ~16.2 hh, plays idle if present, tints coat.

## Verify

```
godot --headless --path . --script res://tests/run_tests.gd
```

Includes `test_horse_factory` (identity + 112 Sleeps → `age_months == 132`).
