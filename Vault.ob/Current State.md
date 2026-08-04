# Current State

## Status

The game has a playable first slice. You can open the Infernal Stronghold, begin a run, fight through an arena, choose upgrades, and receive a reward at the end. Headless lifecycle and balance checks cover the implementation.

## What you can play

- The demon and Infernal Core start in a new arena.
- Soldiers and orcs arrive in growing groups and attack the core.
- The demon fires Ember Bolts toward the mouse, strikes nearby enemies with Blood Orbit, and clears enemies near the core with Core Pulse.
- Enemy kills give XP. Each level offers three choices and pauses the fight until you choose one.
- You win after 600 seconds. The demon or core dying ends the run in defeat.
- The arena changes with its seed, while the same seed produces the same obstacles and hazards.
- The Stronghold saves Infernal Shards, unlocks, the selected demon, and lifetime run totals.
- The demon balance agent compares five deterministic seeds, reports role metrics, and searches bounded demon-only candidates.
- The combat camera follows the demon through the full arena, and the HUD help text is anchored to the active viewport.
- The Stronghold provides a persisted fullscreen/windowed display toggle.
- Desktop export presets and a public-release smoke test cover Windows, Linux, and macOS.
- The arena generator retries seeded layouts until the core, player start, and enemy entrances connect through a runtime-baked navigation map.
- Enemies use navigation agents, obstacle clearance checks, avoidance, and stuck-path retries.
- Stronghold and paused upgrade menus support keyboard, D-pad, and controller focus navigation, including return-to-Stronghold flow.
- Profile loading migrates older save versions, filters invalid catalog IDs, and recovers from corrupt data.
- The player scene owns an editor-visible demon `Sprite2D`; the reusable enemy scene owns an editor-visible soldier `Sprite2D` and swaps to the orc texture when spawned with orc data.

## Open work

The catalog lists eight abilities. All eight have runtime implementations:

1. Ember Bolt, a directional projectile.
2. Blood Orbit, a strike against the nearest enemy.
3. Core Pulse, an area attack around the core.
4. Hellfire Field, a damaging hazard.
5. Bone Spear, a piercing projectile.
6. Chain Lash, a chaining attack.
7. Imp Swarm, homing imp projectiles.
8. Soul Drain, a damaging healing attack.

The lifecycle integration test covers all eight runtime classes. Seven evolved forms have distinct runtime behavior. Soul Furnace remains catalogued as an evolution, but Soul Drain keeps its base behavior after that choice.

## Next checks

- Manually play a full ten-minute run and compare it with the deterministic balance suite.
- Check the alternate demon loadouts and evolved abilities in the desktop build.
- Run the five-seed demon review before changing the live demon configuration.
- Run the navigation, enemy-routing, UI-focus, and profile-migration integration checks after changes to those systems.
- Replace the placeholder core art and add stronger hit and death feedback.
- Replace procedural ability, hazard, and obstacle visuals with finished art and VFX.
- Add character animation sets, alternate demon identities, and Stronghold/upgrade UI art.
- Install the matching Godot export templates and verify real exported builds on each target platform.
- Resolve third-party asset/font licensing before any public distribution.
