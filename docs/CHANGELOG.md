# Changelog

All notable project changes. Session detail lives in [`docs/log/`](log/).

## 2026-08-17

### Changed

- Art pipeline: AAA horse is a bought pack dropped as `assets/models/horse/hero.glb` (`docs/ART.md`). Homemade free-horse rig is the stand-in until then.
- Farm horse uses the free textured GLB (decimated to 28k faces) with Idle / Walk / Jump. Quaternius FBX stays as fallback.
- Meshy official plugin is enabled. Imported truck/trailer GLBs on the west drive replace the box stand-ins.
- Playtest till: Play fills cash to $999,999 and shop/shows never bounce for money. F9 refills. New game turns it off.
- Farm lot is 160 m on a side. Gravel drive and truck/trailer sit on a west entrance (~x = −42), linked by a lane along the barn — well clear of the east arena.

### Added

- Own a string: buy a green prospect ($3,200), sell a made horse, switch with < >.
- Working student ($90/week) picks stalls. Overdue farrier drops hoof.
- Circuit: Ashford Saturday 0.80, Crossridge Sunday 0.80, Mill Brook Saturday 0.90, Ashford 2'6" hunter, Willow Park 1.00 m. Load the trailer the evening before.
- Breeding: mark a mare, cover with a stallion ($250), foal in 21 days.
- Watch a class: Stay / Wait / Leave at each fence. Skip = all Stay.
- Hunter score. Quests on the HUD. Pause: load slot 1 / new game. Whole string stands in the aisle.

### Added

- Barn office: take boarders ($160/week), haul-for-hire (needs truck + trailer), enter Ashford Saturday 0.80 m.
- Shop catalog: more tack, drag, extra jumps, barn wing (8 stalls), indoor, used diesel, two-horse trailer.
- Farm grows when you buy: second barn, truck/trailer blocks, extra fences, arena roof.

## 2026-08-16

### Fixed

- School shows Flat / Poles / Gymnastic as soon as you click it (lead no longer swallows the picker).
- Picking a school trip in the morning advances to afternoon and starts the work. A click always applies the session, then the horse walks the trip.
- Boot scene is playable: orbit camera, visible barn/arena, on-screen Next Phase / Sleep / Save / Pause. Esc no longer the only control (the editor eats Esc).

### Added

- Shop: hay, grain, farrier, open-front boots, running martingale, arena footing. Cash only moves through `Economy.post`.
- Afternoon school: lead the horse to the arena, then flat / poles / gymnastic (one trip a day). The horse walks the trip; gymnastic uses the two fences.
- Jumper resolver (oracles A–D). Home gymnastic rolls a 4-fence trip and shows a recap (rails / refusals / faults). Footing 40 vs 65 changes home `p_rail`.
- Approved design for **Livia's Stable** (`docs/DESIGN.md`): Hunter/Jumper farm + show career, Godot 4.7, management sim + course theater.
- Godot project bootstrap (PR 1): `project.godot`, boot scene, enums, game config, folder tree.
- Clock, EventBus, GameState, JSON save/migrate, pause Sleep (PR 2).
- Headless tests: 112-day calendar wrap; save/load + v0 migrate.
- Project log convention under `docs/log/`.
- GitHub remote: https://github.com/rich382/horsegame

### Changed

- New games start with 14 days of hay and grain. Feed pulls from the loft.
- Farm and horse are Grok Imagine paintings (cutout sprites): shedrow barn, hunter jump, white fence, oak, four coats. Coat buttons preview live.
- Horse card is Blender-rigged (`horse_rigged.glb`) with looping idle; coats swap the same skin.
- Barn sunk so the painted floor meets the grass; horse stands on the ground instead of lying through it.
- Replaced billboard barn/jump/fence with Blender 3D meshes. Horse is the Quaternius 3D model, planted on the grass.
- Daily care: feed, pick stall, turnout, groom, horse sheet. Hunger follows the design table.
- Owner-rider walks to each chore and does it (KayKit Ranger). Click the yard to walk.
- Fixed in-place walk: used integer `mini` for a float step.
