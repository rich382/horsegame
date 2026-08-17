# 2026-08-16 — Player walked in place

`mini(dist, WALK_MPS * dt)` is integer min. Frame step (~0.05 m) truncated to 0, so the walk clip played and the node never moved. Switched to `minf`.
