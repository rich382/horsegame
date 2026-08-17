# Changelog

All notable project changes. Session detail lives in [`docs/log/`](log/).

## 2026-08-16

### Fixed

- Boot scene is playable: orbit camera, visible barn/arena, on-screen Next Phase / Sleep / Save / Pause. Esc no longer the only control (the editor eats Esc).

### Added

- Shop: hay, grain, farrier, open-front boots, running martingale, arena footing. Cash only moves through `Economy.post`.
- Afternoon school: walk to the arena, then flat / poles / gymnastic (one trip a day).
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
