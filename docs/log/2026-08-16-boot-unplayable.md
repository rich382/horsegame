# 2026-08-16 — Boot scene felt broken

## Goal

Owner: “nothing works when I start the game.”

## Cause

The project launched (headless smoke was already green). Play showed a flat CSG plane and a title. The only action was **Esc → pause**, and **Esc inside the Godot editor stops Play** instead of opening the menu. Camera had no orbit. No on-screen buttons. So Play looked like a frozen screenshot.

## Fix

- Replaced the empty plane with a visible yard (barn, arena, jump rails) as `MeshInstance3D` boxes.
- Orbit camera: left-drag, wheel zoom.
- On-screen **Next Phase / Sleep / Save / Pause**.
- Keys: **N**, **M**, **F5**, **P**. Help text warns that Esc stops Play in the editor.
- Toast line confirms each action.
- Test `test_boot_actions.gd`: Morning→Afternoon→Evening→Tuesday Morning; `boot.tscn` instantiates with buttons + camera.

## Files

- `scenes/boot/boot.gd`, `boot.tscn`, `orbit_camera.gd`
- `scenes/ui/pause_menu.gd` (P as well as Esc)
- `tests/test_boot_actions.gd`, `tests/run_tests.gd`
- `README.md`

## Verify

```
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --quit-after 2
```

## Still later

Farm click-care, horses, shop, Ashford (PRs 3–7c).
