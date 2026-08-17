# 2026-08-17 — Free horse mesh

## Source

`C:\Users\rich\Projects\horsetraderv3\horse-3d-model-free.zip`

One GLB (`source/model.glb`, 51 MB): 620k verts / 956k tris, PBR textures, no skeleton, no clips. THREE.GLTFExporter r170. No license file in the zip.

## What shipped

- Decimate in Blender 5.2 (`tools/decimate_free_horse.py`) to **28k faces**.
- Game mesh: `assets/models/horse/free_horse.glb` (~22 MB). Raw source is gitignored.
- `HorsePresenter` prefers that GLB, plants it, tints coats through the albedo map, and bobs the root on walk (no walk clip). Quaternius FBX remains the fallback and still supplies walk/idle/jump for tests.

## Rig (same day)

The zip mesh has no skeleton. `tools/rig_free_horse.py` adds a 19-bone quadruped (horse faces −Y), distance weights (heat weighting failed on the decimate), and **Idle / Walk / Jump** NLA clips. Walk is a 4-beat in-place cycle; jump is an in-place tuck so the presenter still supplies the arc.
