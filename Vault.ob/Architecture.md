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
| Saved progress | `autoloads/profile_manager.gd` | Stores Shards, unlocks, the chosen demon, and lifetime totals |
| Game signals | `autoloads/event_bus.gd` | Lets the game announce XP, pauses, damage, rewards, and endings |
| Run scene | `levels/main.gd` | Creates the arena, spawns enemies, runs attacks, and updates the HUD |
| Stronghold | `levels/stronghold.gd` | Shows unlocks and starts the next run |
| Arena | `features/arena/arena_generator.gd` | Places obstacles, hazards, and enemy entrances |
| Player | `entities/player/player.gd` | Handles movement, auto-fire, damage, and run upgrades |
| Enemies | `entities/enemy/enemy.gd` | Move toward the core, deal contact damage, and drop XP |
| Core | `entities/core/hell_core.gd` | Holds the objective's health and ends the run when it reaches zero |
| Game data | `common/` | Defines abilities, passives, enemies, rewards, and the upgrade catalog |

## A few rules worth remembering

- `GameManager` owns the state of the current run.
- `ProfileManager` owns progress between runs.
- The Stronghold shows that data. It does not decide combat rules.
- The arena uses a seed, so a test can compare two runs built from the same seed.
- The game uses the supplied PNG artwork from `sprites/` and `tileset/`. Source Aseprite and PSD files stay in the project for editing.
