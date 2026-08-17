---
name: critic
description: >
  Spawn the Livia's Stable critic agent, fix its must-fix list, and re-run
  until VERDICT is SATISFIED (max 3 rounds). Use when the user says critic,
  /critic, "add a critic", or "iterate until the critic is satisfied".
---

# Critic loop

1. Spawn a **critic** subagent (`subagent_type: critic` if available, else `general-purpose` with the prompt in `.grok/agents/critic.md`). `capability_mode: execute`. Tell it to write `docs/log/critic-report.md`.
2. Wait for it. Read the report. Do not invent a SATISFIED verdict yourself.
3. If `VERDICT: SATISFIED`, stop. Tell the user what the critic accepted.
4. If `NEEDS_WORK`, implement **only** the must-fix items. Re-run headless tests. Spawn the critic again (new spawn, not a self-grade).
5. Stop after 3 critic rounds even if still NEEDS_WORK, and list what is left.

Do not treat "buy Horse Animset Pro" as a must-fix unless the user asked to buy it.
