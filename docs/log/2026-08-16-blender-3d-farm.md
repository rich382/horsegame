# 2026-08-16 — Blender 3D farm kit

## Ask

Model in Blender (real meshes, not Imagine cards).

## Built

`tools/model_farm.py` (Blender 5.2, Z-up, glTF Y-up):

| File | What |
|---|---|
| `assets/models/farm/barn.glb` | 11.2×5.4 shedrow: 3 stalls + tack, aisle posts, pitched roof, overhang, cupola. Imagine wood + shake textures. |
| `assets/models/farm/jump.glb` | Two standards, two rails, planter, simple flowers. |
| `assets/models/farm/fence.glb` | 3-board white fence segment (~2.9 m). |

Farm yard instances these plus Kenney 3D trees. Horse presenter uses the Quaternius **3D** FBX again, scaled to ~2.05 m and planted so the AABB bottom is y=0. No billboard look-at.

## Not

This is block-modeled architecture, not a sculpted Warmblood. Imagine paintings stay in `assets/sprites/` for UI / future use.
