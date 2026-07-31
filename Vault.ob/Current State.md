# Current State

## Status

The game has a playable first slice. You can open the Infernal Stronghold, begin a run, fight through an arena, choose upgrades, and receive a reward at the end.

## What you can play

- The demon and Infernal Core start in a new arena.
- Soldiers and orcs arrive in growing groups and attack the core.
- The demon fires Ember Bolts toward the mouse, strikes nearby enemies with Blood Orbit, and clears enemies near the core with Core Pulse.
- Enemy kills give XP. Each level offers three choices and pauses the fight until you choose one.
- You win after 600 seconds. The demon or core dying ends the run in defeat.
- The arena changes with its seed, while the same seed produces the same obstacles and hazards.
- The Stronghold saves Infernal Shards, unlocks, the selected demon, and lifetime run totals.

## What still needs work

The catalog lists eight abilities. Combat currently uses three of them:

1. Ember Bolt, a directional projectile.
2. Blood Orbit, a strike against the nearest enemy.
3. Core Pulse, an area attack around the core.

Hellfire Field, Bone Spear, Chain Lash, Imp Swarm, and Soul Drain appear in the Stronghold and can enter a starting loadout, but they do not have their own combat behavior yet. The same applies to the planned evolved forms.

## Next checks

- Play a full ten-minute run and tune enemy pressure.
- Check the alternate demon loadouts after their abilities have runtime behavior.
- Add tests for pause, level-up choices, defeat, victory, and saved rewards.
- Replace the placeholder core art and add stronger hit and death feedback.
