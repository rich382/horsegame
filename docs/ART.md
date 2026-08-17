# Art — how this game gets AAA horses

Meshy, a free statue, and a 19-bone homemade walk will never look like a sold horse game. AAA quadruped motion is **bought or commissioned**. This file is the pipeline.

Design lock (K4): stylized 3D diorama + cinematic course theater, **6–8 baked clips**. Not riding physics. Not a painted card.

## What “AAA” means here

A game-ready **hero horse**, not a film render:

| Piece | Bar |
|---|---|
| Mesh | 15–40k tris body, separate mane/tail/eyes, clean quads or game tris |
| Textures | 2K PBR, **swapable coats** (bay / chestnut / grey / black) |
| Rig | Real quadruped (spine, neck, 4 IK legs, tail). Not 19 distance-weighted bones. |
| Clips | Idle, walk, trot, canter, gallop, jump, halt. In-place cycles. |
| Export | One `hero.glb` Godot can play |

The zip we used is a high-res **statue**. It has no professional skeleton and no gaits. Skinning it ourselves is a placeholder.

## Do not use for the hero

- Meshy / image-to-3D as the final horse (no horse mocap, humanoid auto-rig)
- Mixamo (people only)
- The current `free_horse.glb` homemade Idle/Walk/Jump
- Quaternius as the hero (fine as a block-in)

Meshy stays for **props** (truck, trailer, jumps, tack trunks) once a real API key exists.

## Buy this (recommended)

**[Horse Animset Pro](https://assetstore.unity.com/packages/3d/characters/animals/horse-animset-pro-riding-system-79902)** — Malbers Animations, **$74.99**, Unity Asset Store.

- 80+ clips, walk / trot / canter / gallop / jump / idle
- Realistic mesh + coat textures
- FBX out of Unity → Blender → `hero.glb`
- Standard store EULA covers a shipped game

Horse people prefer **[Horse Herd by 3D Bear](https://www.unrealengine.com/marketplace/en-US/product/horse-herd)** for anatomy. It is Unreal-first; same idea, heavier convert.

Optional if we keep a custom sculpt: **[Auto-Rig Pro](https://superhivemarket.com/products/auto-rig-pro)** + **[ARP Horse Animations](https://superhivemarket.com/products/arp--horse-animations-pack)** (~$18 pack, ARP is separate). That retargets bought gaits onto *our* mesh. Only worth it after HAP or a real sculpt.

## Drop-in slot

1. Buy HAP (or another pack).
2. Export the realistic horse + Idle / Walk / Jump (Trot/Canter extra) as **glTF Binary**.
3. Save it as:

```
assets/models/horse/hero.glb
```

`HorsePresenter` loads `hero.glb` first, then `free_horse.glb`, then Quaternius. Clip names only need to contain `idle`, `walk`, `jump` (and later `trot` / `canter`).

## Free fallback (not AAA, better than homemade)

[BlendSwap — Horse Rigged All Gaits](https://blendswap.com/blend/28627) (CC0, walk/trot/canter/gallop, 584 MB `.blend`, needs a BlendSwap login). Drop the file in the project and say so — it can replace the homemade rig the same day. Particle hair must be baked or stripped before Godot.

## Coats

Bought packs usually ship 3–6 albedo maps. Those become the coat picker. Multiplying one bay texture with a color (what we do now) is a stand-in.

## Farm / rider

Same rule: Kenney trees and CSG truck are block-in. Next paid/Meshy props: truck, two-horse, standards. Rider stays KayKit until a matching rider clip exists in the horse pack.
