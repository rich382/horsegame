# 2026-08-16 — Design + bootstrap

## Goal

Plan and start building a Godot Hunter/Jumper farm + show career game. User asked to plan and build; later asked to log everything in the project folder and use https://github.com/rich382/horsegame.

## Product decisions (owner)

| Question | Answer |
|---|---|
| Official name | **Livia's Stable** (Godot `config/name`, window title, copy). Disk folder stays `Horse Game`. |
| First class on screen | Ashford **0.80 m jumper**. Hunter 2'6" is PR 8. |
| Setting | **Ashford County Schooling Show** |
| Starter horse | Same KWPN packer (Bayberry defaults); new-game **name + coat picker** (bay / chestnut / grey / black) |
| Proceed | Start building immediately |

Retired working title: *The Ingate*.

## Design loop

- Design ID `15554683`. Scratch copies lived under `%TEMP%\grok-rich\` during the write/review loop; the **approved** document was copied to [`docs/DESIGN.md`](../DESIGN.md).
- Writer / reviewer loop: **4 review rounds**, **31 issues** closed (4 critical, 11 major, 9 minor, 7 nits). Final verdict: approve, 0 open issues.
- Then owner answers were folded in (name, jumper-first, Ashford, coat picker). Status: **Approved**.

### What the reviews forced into the spec

- Closed `ShowResolver` (every symbol, `Rng` API, 11-step roll, jump-off keeps Wait/Stay/Leave, oracles A–D)
- Schooling + height gap in rail/disobedience; soft overfaced vs +20 cm cruelty gate
- Full hunter judge formulas + major-fault floors
- Two-allele `GenePair` from PR 3 (no Season 2 migration)
- `GameState` autoload holds `GameStateData`
- Year wrap after WINTER; `sleep_until_morning` advances to the *next* morning
- Home footing / care_quality / training_efficiency are mechanical
- 0.80 m jumper ≠ 2'6" hunter (0.76 m)

## Implementation this session

### PR 1 — Project bootstrap

- `project.godot`: name **Livia's Stable**, feature tag `4.7`, Forward Plus, 1920×1080, `canvas_items` / `expand`, Jolt
- Folder tree (`src/`, `scenes/`, `resources/`, `assets/`, `tests/`)
- `src/core/enums.gd`, `src/core/game_config.gd`
- `scenes/boot/boot.tscn`: CSG ground, title, camera
- Engine on this machine: **Godot 4.7-stable** (`C:\Users\rich\Downloads\Godot_v4.7-stable_win64.exe\`). Design pins 4.7.1; both use feature tag `4.7`.

### PR 2 — Clock, EventBus, save

- Autoloads: `EventBus`, `GameState`, `GameClock`, `SaveService`
- `Calendar` with 112-day year wrap
- `sleep_until_morning` = next morning (not a no-op at dawn)
- JSON saves `user://saves/slot_N.json` + autosave + `migrate()`
- Pause menu: Resume / Sleep / Save / Quit
- Clock HUD
- Tests: `tests/test_calendar_wrap.gd`, `tests/test_save_migrate.gd`, `tests/run_tests.gd`

### Verification

```
godot --headless --path . --script res://tests/run_tests.gd
```

- `test_calendar_wrap: ok` (112 Sleeps → year 2, Spring, week 1, Monday, Morning, `abs_day == 112`, no horses)
- `test_save_migrate: ok`
- `ALL TESTS PASSED` exit 0
- `godot --headless --path . --quit-after 2` exit 0

### Git

- Initialized local repo. Root commit `abc85a1` — `feat: Livia's Stable bootstrap, clock, and save (PR 1-2)`.
- This log + CHANGELOG + GitHub remote added in a follow-up commit, then pushed to `https://github.com/rich382/horsegame`.

## Open / next

- **PR 3:** Horse resource, qualitative sheet, new-game name + coat picker, Bayberry `age_months == 132` after 112 Sleeps.
- Music / VO still not a slice blocker.
- Do not start hunter, construction, or breeding until the jumper slice is playable.
