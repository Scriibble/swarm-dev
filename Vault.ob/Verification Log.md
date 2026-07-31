# Verification Log

## 2026-07-31

I ran the Godot smoke test from the project folder:

```text
godot --headless --path /Users/evananderson/Documents/Swarm-dev --script res://tests/roguelite_smoke.gd
```

Godot 4.7.1 passed the test.

- The game produced three upgrade choices.
- The choices had different IDs.
- Two arenas made with seed `98765` produced the same obstacles and hazards.
- The test found 46 obstacle cells and 13 hazard cells.

The test checks the upgrade picker and arena seed. It does not play through a full run, test keyboard or controller input, check the Stronghold screen, or confirm that a saved profile loads correctly.
