# 2026-08-16 — Imagine sprites in the yard

## Goal

Owner: use Grok Imagine for better assets. Imagine cannot emit glTF; we painted isolated sprites and stood them up as Y-billboards.

## Generated (flat magenta, then keyed)

| Sprite | Notes | Verdict |
|---|---|---|
| `horse_bay.png` | 16.2hh warmblood 3/4, star, no tack | Pass |
| `horse_chestnut.png` | Edit-chain from bay, flaxen mane | Pass (slightly more rendered) |
| `horse_grey.png` | Dapple grey, same pose | Pass |
| `horse_black.png` | Black, star kept | Pass |
| `barn.png` | 4-stall shedrow, tack room | Pass (painted "TACK" / stall numbers) |
| `jump.png` | Hunter vertical + flower box | Pass |
| `fence.png` | White 3-board | Pass |
| `tree_oak.png` | Isolated oak | Pass |

Key script: `tools/key_sprites.py`. Horse PNG corner alpha is 0.

## In-game

- `SpriteProp` → Sprite3D, Y billboard, opaque-prepass alpha.
- Farm uses Imagine barn/jump/fence/trees on the existing grass + footing planes.
- HorsePresenter swaps coat textures. New-game coat buttons preview live.

## Limits

- Billboards flatten if you orbit to a hard side view.
- Coat edits drifted a bit more 3D-lit than the original bay illustration.
- Barn is a picture of a barn, not walkable stalls.
