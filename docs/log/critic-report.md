# Critic report — Livia's Stable

Date: 2026-08-17  
Role: critic (read-only). Headless suite: `ALL TESTS PASSED` (Godot 4.7-stable).

## 1. Verdict

**SATISFIED**

The four prior must-fixes are actually in the files, not just claimed. Play no longer opens the till. Root junk is gone. Save writes horse dicts and the suite asserts uid / name / hunger. Load hides the name card when `identity_set` is true (or when an older save already has horses). The homemade horse is still an honest stand-in. Do not block on unbought `hero.glb`.

## 2. Must-fix

None.

Prior items, re-checked:

### MF1 — Playtest till on every Play — **fixed**

- **id:** `playtest-cash-on-boot`
- **file:** `scenes/boot/boot.gd` `_ready` (lines 82–90). F9 still at 112–116. `src/autoload/economy.gd` keeps `grant_playtest_cash` for that key.
- **check:** `_ready` does not call `Economy.grant_playtest_cash()`. First toast is “Name your horse…” (or “Welcome back…” after a named/loaded session). `GameState.new_game()` still starts at `$10,000` with no `debug_unlimited_cash` (`test_economy` asserts both). Pause New game / Load reload the scene; that no longer re-opens the till.

### MF2 — Unused midnight-black horse at repo root — **fixed**

- **id:** `root-junk-midnight-black`
- **file:** project root
- **check:** No `midnight_black_horse_*` glb / jpg / png / `.import`. Grep only hits the previous critic report. Presenter still wants `hero.glb` → `free_horse.glb` → Quaternius.

### MF3 — Save does not serialize horses — **fixed**

- **id:** `save-horses-unserialized`
- **file:** `src/horse/horse_state.gd` (`to_dict` / `from_dict`). `src/core/game_state_data.gd` (`_horses_to_dicts` / `_horses_from_any`). `tests/test_save_migrate.gd`.
- **check:** `to_dict()` writes field dicts, not Resource dumps. `from_dict()` rebuilds `HorseState`. `SaveService` still `JSON.stringify`s `GameState.data.to_dict()`. `test_save_migrate` saves slot 9 after a phase advance, loads it back, and asserts the horse is a Resource whose uid, name, and hunger match. Suite printed `test_save_migrate: ok`.

### MF4 — Load slot 1 reboots the new-game overlay — **fixed**

- **id:** `load-rebrands-as-new-game`
- **file:** `scenes/boot/boot.gd` (`_session_named`, `_on_identity`). `src/core/game_state_data.gd` `from_dict` (infer `identity_set` when horses exist). `scenes/ui/pause_menu.gd` still `load_slot` then `reload_current_scene`.
- **check:** Name confirm sets `farm.identity_set = true`. Boot `_ready` hides `$NewGame` when that flag is set. Load of a save that already has horses and no flag still infers it, so the name card stays off. Pause **New game** calls `GameState.new_game()` (flag unset) and correctly shows the card again.

## 3. Later

- Buy Horse Animset Pro (or BlendSwap) and drop `assets/models/horse/hero.glb`. Homemade 19-bone `free_horse.glb` with Idle / Walk / Jump is an honest stand-in. Tests confirm the clips. Do not treat missing HAP as a fail.
- Changelog still says Meshy truck / trailer GLBs replaced the boxes. `assets/models/farm/` has barn / jump / fence only. `imported_models/` is empty. `FarmYard` falls back to CSG boxes. Fine as block-in; the changelog is ahead of the disk.
- Course theater is a HUD card plus a walk around the home arena (`scenes/show/theater.gd`, `boot.gd` `_run_watch_show`). Not a PathFollow3D overlay, farm is not `PROCESS_MODE_DISABLED`. Watch still has `if bool(ev.jump_to) if false else true:` — always-true leftover.
- Design K9 `ContentDB` + authored `.tres` are missing. `resources/horses/`, `resources/config/`, etc. are empty. Circuit, catalog, and Bayberry live in GDScript tables. Playable; not the data-driven layout.
- Breeding, a hunter class, and a five-show circuit shipped ahead of the slice. `discipline_hunter_enabled` is still unused. Season 2 breeding is in the Office. Later product, not a break.
- No `InjurySystem`. No `Economy.accrue_daily`. Night bundle is rest + care + board + help + foals.
- README still says “Ashford (entry, haul, 0.80 m jumper) is next.” Office already has Watch / Simulate for the circuit.
- Unused-but-not-root: `assets/sprites/` Imagine cutouts, `src/farm/sprite_prop.gd` unused, `src/show/eligibility.gd` unused (Circuit has its own gate). `horse_rigged.glb` is only still loaded by `test_horse_factory`.
- School picker hint still reads `horses[0]`, not the selected horse (`scenes/ui/school.gd`). String turnout still stacks extras at one paddock point (`boot.gd` `_sync_string`).
- F9 remains a hidden playtest till. HUD Help does not mention it. Opt-in is fine; do not wire it to Play again.
- Old pre-MF3 slot files that stored `"():<Resource#…>"` cannot be recovered (the fields were never written). New saves work. Player uses Pause → New game on those slots.
- Prettier barn, Meshy props, PathFollow polish, working-student / boarder meshes.

What is already coherent (not a withhold):

- Name is Livia's Stable. Godot 4.7, Forward Plus, Jolt, six-minus-ContentDB autoloads.
- Care hunger table matches design. Horse sheet uses language, not raw talent (K12).
- Jumper oracles A–D and footing 40 vs 65 are tested. HUD Care / School / Shop / Office / theater buttons are connected.
- Farm lot 160 m, drive at x = −42, Kenney trees, Blender barn. Honest block-in.
- Start cash is $10,000 unless the player hits F9.

## 4. What I actually opened

- `docs/DESIGN.md`
- `docs/ART.md`
- `docs/CHANGELOG.md`
- `docs/log/README.md`
- `docs/log/critic-report.md` (previous)
- `docs/log/2026-08-17-complete-pass.md`
- `README.md`
- `project.godot`
- `scenes/boot/boot.gd`
- `scenes/boot/boot.tscn`
- `scenes/horse/horse_presenter.gd`
- `scenes/ui/new_game.gd`
- `scenes/ui/new_game.tscn`
- `scenes/ui/pause_menu.gd`
- `scenes/ui/school.gd`
- `src/autoload/economy.gd`
- `src/autoload/game_state.gd`
- `src/autoload/save_service.gd`
- `src/core/game_state_data.gd`
- `src/core/player_state.gd`
- `src/farm/farm_yard.gd`
- `src/horse/horse_state.gd`
- `src/horse/horse_genome.gd`
- `tests/run_tests.gd`
- `tests/test_save_migrate.gd`
- `tests/test_boot_actions.gd`
- `tests/test_economy.gd`
- `tests/test_horse_presenter.gd`
- Project root listing
- `assets/models/farm/` listing
- `assets/models/horse/` listing
- `imported_models/` listing
- Grep: `grant_playtest_cash`, `midnight_black`, `identity_set`, `hero.glb`, `horses[0]`

Headless run:

`C:\Users\rich\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe --headless --path "c:\Users\rich\Projects\Horse Game" --script res://tests/run_tests.gd`

Printed `ALL TESTS PASSED` (calendar, save/migrate, boot actions, factory, care, avatar, economy, training, presenter, jumper, barn, breeding, hunter).

Not opened: every remaining `docs/log/2026-08-16-*.md`, full `show_resolver.gd`, hunter/jumper judge bodies, Meshy plugin scripts, Blender tool scripts, live `user://` slots.
