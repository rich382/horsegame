# 2026-08-16 — Blender rig on the Imagine horse

## Question

Can we use Blender to rig the Imagine paintings?

## Honest answer

Yes, as a **2D cutout puppet**. Blender cannot turn a painting into a real 3D Warmblood skeleton. One textured card is skinned to 8 deform bones. Motion warps the picture. Subtle idle looks fine; walk is a small opposite-leg rock so the paint does not melt.

Barn / jump / fence stay still cards. Only the horse is rigged.

## What shipped

- Blender 5.2 script: `tools/rig_horse.py`
- Export: `assets/models/horse/horse_rigged.glb` (idle 48f, walk 24f)
- `HorsePresenter` instances the glb, loops idle, Y-faces the camera, swaps coat albedo (bay / chestnut / grey / black)

## Limits

- Not a 3D mesh. Orbit to a hard profile and you still see a card.
- Walk is a hint, not a gait.
- Weights are distance-based, not painted. Four influences per vertex (glTF limit).
