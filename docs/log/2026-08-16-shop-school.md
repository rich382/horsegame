# 2026-08-16 — Shop and afternoon school

## Goal

Keep going after the walk-in-place fix: money, feed inventory, farrier, tack, footing, and a real afternoon school.

## What landed

- `Economy` autoload. `post` is the only cash writer. Shop prices match the design table.
- New game loft: 14 hay days, 14 grain days, starter saddle + snaffle, `training_efficiency` 0.15.
- Feed consumes loft stock. Empty bin sends you to the shop.
- Shop panel (walk to the aisle): hay, grain, farrier, open-fronts (`care_mod` +3), running martingale, $1,200 footing 40 → 65.
- School panel (walk to the arena): flat / poles / gymnastic. Afternoon only, energy ≥ 35, soundness ≥ 55, one school per day.
- HUD shows cash + hay/grain. Sheet shows work and farrier due (seeded due day 10).

## Tests

Headless `tests/run_tests.gd`: care loft + hay decrement, economy buys and refusals, training gates and skill gain, boot Shop/School nodes.

## Still open

- Gymnastic recap / rails wait for PR 7a (`ShowResolver`).
- Ashford prize list, haul, entry (PR 7b).
- Farrier overdue hoof decay (2/day) is specified but not ticked yet.
