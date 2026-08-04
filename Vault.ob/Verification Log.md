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

The test checks the upgrade picker and arena seed. It does not play through a full run, test keyboard or controller input, check the Stronghold screen, or confirm that a saved profile loads.

## 2026-08-01

Godot 4.7.1 headless verification passed:

- Editor project scan completed successfully.
- `tests/roguelite_smoke.gd` passed.
- `tests/lifecycle_integration.tscn` passed pause/resume, level-up application, all eight ability activations, evolution activation, player defeat, core defeat, victory, reward calculation, unlocks, demon selection, and profile persistence using an isolated `user://` save.
- `tests/balance_runner.tscn` completed ten-minute victories for Ash Summoner, Core Bulwark, and Blood Harbinger under its deterministic autoplay policy.
- The balance harness reports result, elapsed time, level, kills, core health, rewards, upgrades, and evolutions, and fails on non-terminal or non-victory outcomes.

The unused `tileset/spike-trap-ani_files/` directory had no runtime references. We moved it to a recoverable temporary archive, then removed it from the project.

The demon balance agent uses a typed candidate/configuration layer, reusable evaluator, Markdown/JSON report output, and a Codex reviewer contract. The authoritative five-seed review passed across all 15 demon runs: each demon won 5/5, median survival reached at least 90% of the strongest demon, and the weighted-score spread stayed within the 15-point gate. The report identified Bulwark as strongest overall under the measured policy and Harbinger as weakest while preserving the intended role metrics. A one-seed review remains as a smoke check.

The bounded tuner smoke completed without applying changes: seven candidates ran against one seed, and the tuner selected one candidate in memory. We left persistent overrides unchanged because `--apply` was not supplied.

## 2026-08-02

Release-readiness work completed:

- Added a player-following camera with arena limits and anchored the combat help text to the viewport.
- Added a persistent fullscreen/windowed display preference through `SettingsManager`.
- Added `assets/icon.svg`, desktop export presets, and `tests/public_release_smoke.gd`.
- Editor scan, public-release smoke, project smoke, lifecycle integration, and the deterministic three-demon runner passed after the changes.
- A Linux export reached the export stage, but this machine lacks the Godot 4.7.1 export templates. Target artifacts remain unverified until the templates are installed.

## 2026-08-03

Godot 4.7.1 verification passed after moving character visuals into the scene files:

- `entities/player/player.tscn` owns the editor-visible `PlayerSprite` node and demon idle texture.
- `entities/enemy/enemy.tscn` owns the editor-visible `EnemySprite` node and soldier preview texture; runtime enemy data swaps the texture for orcs.
- The headless editor scan completed successfully.
- `tests/roguelite_smoke.gd` passed with 3 upgrade offers, 46 obstacle cells, and 13 hazard cells.

Navigation, menu focus, profile migration, and release checks passed after the latest workspace changes:

- `tests/navigation_integration.tscn` passed eight deterministic layouts, including synchronized navigation maps and valid spawn-to-core paths.
- `tests/enemy_navigation_integration.tscn` passed with 26 soldier and orc agents routing safely around obstacles.
- `tests/ui_focus_integration.tscn` passed Stronghold focus movement, controller accept input, paused upgrade selection, and D-pad mappings.
- `tests/profile_migration_smoke.tscn` passed legacy-profile migration, invalid catalog-ID removal, and corrupt-profile recovery.
- `tests/roguelite_smoke.gd` passed with 3 upgrade offers, 46 obstacle cells, and 13 hazard cells.
- `tests/lifecycle_integration.tscn` passed pause, upgrades, all eight ability activations, evolution activation, defeat, victory, rewards, and persistence.
- `tests/public_release_smoke.gd` passed metadata, icon, export presets, and resizable-window checks.
- `tests/balance_runner.tscn` completed victories for Ash Summoner, Core Bulwark, and Blood Harbinger on seed `424242`.
