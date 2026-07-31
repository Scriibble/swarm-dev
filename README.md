# Infernal Swarm

A desktop-first Godot 4.7.1 fantasy swarm roguelite where a demon defends the hells from human and orc invaders.

## Current slice

- 10-minute fixed dungeon survival run.
- WASD or left stick movement; Space/Escape pauses.
- Directional auto-casting attack, orbiting infernal blades, and a hell-core pulse.
- Soldier and orc invaders with escalating waves.
- XP level-ups with three upgrade choices.
- Victory after the final champion event, or defeat when the demon or core dies.
- Seeded obstacle and hazard layouts for each run.
- Infernal Stronghold with persistent Infernal Shards, unlocks, prerequisites, and demon selection.
- Run-local ability/passive ranks, weighted offers, and evolution-ready synergies.

## Structure

Feature folders contain their own scenes/scripts/resources. Global lifecycle state lives in `autoloads/`; presentation listens to signals and does not own gameplay state.

## Assets and attribution

Runtime references use the original PNGs already present under `sprites/` and `tileset/`; no duplicate runtime asset folder is maintained. Source Aseprite/PSD files remain outside the runtime import paths via `.gdignore`. The supplied dungeon pack includes `license.txt` pointing to https://craftpix.net/file-licenses/. Character packs are retained with their original filenames and should be checked against their original download license before commercial distribution. The dungeon preview references the Digital Disco font: https://www.dafont.com/digital-disco.font

## Godot MCP

`.cursor/mcp.json` configures `@coding-solo/godot-mcp` with the installed Godot executable. The package is an MCP server rather than a Codex skill.

## Roguelite profile

Profile data is saved to Godot's `user://profile.save`. A fresh profile begins with the Ash Summoner, Ember Bolt, Blood Orbit, Core Pulse, Emberheart, Cinder Step, and Core Ward. Run results award Infernal Shards from survival time, kills, core health, and victory. Permanent progression unlocks content and starting loadouts without permanently increasing combat stats.
