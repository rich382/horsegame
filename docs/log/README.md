# Project log

All design notes, session write-ups, review findings, and implementation records live **in this repo**, under `docs/`. Do not leave durable work only in temp directories (`%TEMP%\grok-*`).

| Path | What |
|---|---|
| [`docs/DESIGN.md`](../DESIGN.md) | Approved design document |
| [`docs/CHANGELOG.md`](../CHANGELOG.md) | User-facing changes |
| [`docs/log/`](.) | Dated session logs (latest: school picker fix) |

## How to log

1. Add a new file `docs/log/YYYY-MM-DD-short-slug.md` for each working session (or append if the same day continues).
2. Include: goal, decisions, files touched, tests run, what is still open.
3. Update `docs/CHANGELOG.md` when something playable or spec-level changes.
4. Commit the log in the same change set as the work it describes.

Remote: https://github.com/rich382/horsegame
