# 2026-08-16 — Barn float / horse through the grass

## Cause

- Barn is a 3/4 painting. Lowest pixels are posts; the painted aisle floor sits higher. Planting the sprite bottom on y=0 left the building hovering.
- Horse card was rotated flat onto the XZ plane in Blender, then only yawed in Godot, so the painting lay in the ground.

## Fix

- Sink the barn 1.65 m (and a little on fence/tree/jump) so the painted floor meets the grass.
- Re-export the horse standing in XY, facing +Z, hooves at y=0. Face the camera with +Z. Tiny lift (3 cm). Softer idle legs.
