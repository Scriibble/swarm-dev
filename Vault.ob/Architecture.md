# Architecture

## How a run unfolds

```text
Infernal Stronghold
  -> choose a demon and begin a run
  -> build the arena, core, demon, and HUD
  -> spawn waves and run the combat clock
  -> earn XP and choose upgrades
  -> win or lose
  -> award Infernal Shards and save the profile
```

## Where the work lives

| Part of the game | Main files | Job |
|---|---|---|
| Run rules | `autoloads/game_manager.gd` | Tracks time, waves, XP, levels, upgrades, and the end of a run |
| Saved progress | `autoloads/profile_manager.gd` | Stores Shards, unlocks, the chosen demon, lifetime totals, and save-version migrations |
| Game signals | `autoloads/event_bus.gd` | Lets the game announce XP, pauses, damage, rewards, and endings |
| Run scene | `levels/main.gd` | Creates the arena, spawns enemies, runs attacks, and updates the HUD |
| Stronghold | `levels/stronghold.gd` | Shows unlocks and starts the next run |
| Display settings | `autoloads/settings_manager.gd` | Persists the public demo's fullscreen/windowed preference |
| Arena | `features/arena/arena_generator.gd` | Places obstacles, hazards, enemy entrances, and the runtime navigation map |
| Player | `entities/player/player.gd` | Handles movement, auto-fire, damage, and run upgrades |
| Enemies | `entities/enemy/enemy.gd` | Navigate around obstacles, deal contact damage, and drop XP |
| Core | `entities/core/hell_core.gd` | Holds the objective's health and ends the run when it reaches zero |
| Game data | `common/` | Defines abilities, passives, enemies, rewards, and the upgrade catalog |
| Menu focus | `common/menu_focus_navigation.gd` | Connects keyboard and controller focus movement across menus and paused choices |
| Demon balance | `features/balance/`, `tests/demon_balance_agent.gd` | Runs deterministic demon comparisons, scores role parity, and writes review/tuning reports |

## Rules

- `GameManager` owns the state of the current run.
- `ProfileManager` owns progress between runs.
- The Stronghold shows that data. It does not decide combat rules.
- The arena uses a seed, so a test can compare two runs built from the same seed.
- The game uses the supplied PNG artwork from `sprites/` and `tileset/`. Source Aseprite and PSD files remain in the project for editing.
- The player and enemy scenes own their visible `Sprite2D` nodes. Godot's 2D editor can display and edit that art. Enemy setup may swap the scene preview texture between soldier and orc data at runtime.
- Scripts generate data-driven and transient visuals such as ability projectiles, hazards, arena obstacles, and combat feedback. These visuals need finished art later.
- The balance system stores candidates in `DemonBalanceConfig`; an explicit `--tune --apply` run writes `common/demon_balance_overrides.json`.
- The arena retries seeded layouts until the player and enemy entrances can reach the core, then bakes a navigation map at runtime.
- Enemies use `NavigationAgent2D` avoidance, safe movement checks, and stuck-path retries.
- Stronghold and paused upgrade menus share keyboard, D-pad, and controller focus navigation.
- Profile loading validates catalog IDs, migrates older save versions, and recovers from corrupt data.
- The combat camera follows the demon inside the 1440×940 arena while the HUD remains in viewport space.
- `export_presets.cfg` describes desktop builds; test each exported artifact on its target platform.
