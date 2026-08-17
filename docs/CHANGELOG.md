# Changelog

All notable project changes. Session detail lives in [`docs/log/`](log/).

## 2026-08-16

### Fixed

- Boot scene is playable: orbit camera, visible barn/arena, on-screen Next Phase / Sleep / Save / Pause. Esc no longer the only control (the editor eats Esc).

### Added

- Approved design for **Livia's Stable** (`docs/DESIGN.md`): Hunter/Jumper farm + show career, Godot 4.7, management sim + course theater.
- Godot project bootstrap (PR 1): `project.godot`, boot scene, enums, game config, folder tree.
- Clock, EventBus, GameState, JSON save/migrate, pause Sleep (PR 2).
- Headless tests: 112-day calendar wrap; save/load + v0 migrate.
- Project log convention under `docs/log/`.
- GitHub remote: https://github.com/rich382/horsegame
