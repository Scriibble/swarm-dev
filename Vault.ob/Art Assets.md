# Art Assets

Required visual assets for the current game scope.

## Characters

- [ ] Ash Summoner sprite sheet: idle, walk, cast/attack, hurt, death, and victory animations.
  - Use the default demon silhouette with ash, ember, and summoning-fire details.
  - Keep the design readable at the arena camera distance and distinct from the two unlockable demons.
- [ ] Core Bulwark sprite sheet, portrait, and defensive color treatment.
  - Make the demon broad and armored, with design elements tied to the Infernal Core.
  - Use heavier shapes and cool ember tones to communicate its defensive role.
  - Make the portrait work in Stronghold catalog cards and selection text.
- [ ] Blood Harbinger sprite sheet, portrait, and aggressive color treatment.
  - Emphasize claws, blood effects, and a close-range predator silhouette.
  - Use strong red accents to connect the demon to Blood Orbit and Soul Drain.
  - Make the portrait work in Stronghold catalog cards and selection text.
- [ ] Soldier sprite sheet: idle, walk, attack, hurt, and death animations.
  - Keep the silhouette simple enough to read in large groups.
  - Use a lighter, faster visual profile than the orc.
- [ ] Orc sprite sheet: idle, walk, attack, hurt, and death animations.
  - Give the orc a larger, heavier silhouette than the soldier.
  - Use rough armor and muted colors to distinguish it from the soldier at a glance.
- [ ] Champion enemy sprite, effects, and defeat state.
  - Build on the soldier or orc silhouette with larger scale, stronger contrast, and a clear champion marker.
  - Make the champion readable as the late-run threat without confusing it with the player demon.

## Infernal Core

- [ ] Infernal Core idle sprite.
  - Show a large, ominous demonic core that anchors the arena composition.
  - Make the core readable beneath nearby enemies and combat effects.
- [ ] Infernal Core damaged and low-health states.
  - Add cracks, dimming, smoke, or unstable flame as health falls.
  - Make the change visible before the player needs to read the health label.
- [ ] Infernal Core defeat state.
  - Show the core collapsing or extinguishing when the run ends in defeat.
  - Reserve a clear silhouette for the defeat overlay and result screen.

## Arena

- [ ] Dungeon floor tiles.
  - Build a repeatable floor set with enough variation to avoid a visible grid pattern.
  - Keep the contrast low enough for enemies, projectiles, and the core to stand out.
- [ ] Dungeon wall tiles.
  - Provide connected wall pieces, corners, and transitions for the arena boundary.
  - Match the floor palette and support the camera's full arena view.
- [ ] Dungeon border and edge tiles.
  - Define the playable boundary without looking like a flat rectangle.
  - Make edge and corner pieces tile cleanly around the arena.
- [ ] Enemy entrance and spawn-point visuals.
  - Show where waves enter without distracting from combat.
  - Use a brief activation effect when a wave spawns.
- [ ] Dungeon props and decorative set dressing.
  - Add pillars, rubble, chains, braziers, bones, and other props that reinforce the infernal dungeon theme.
  - Keep props outside combat paths or make their collision and gameplay role clear.
- [ ] Finished obstacle sprites to replace the procedural purple obstacles.
  - Create a small modular set with distinct shapes, readable silhouettes, and compatible footprints.
  - Keep obstacles secondary on screen so the core, player, and enemies stand out.
- [ ] Obstacle damaged or destroyed states where gameplay needs them.
  - Show whether an obstacle blocks movement, takes damage, or disappears.
  - Use a short break or dissolve effect if obstacles can change during a run.
- [ ] Trap and hazard sprites to replace the procedural hazard shapes.
  - Give each hazard a clear footprint and a visual language that signals danger.
  - Match the hazard art to the dungeon tiles without hiding the playable area.
- [ ] Hazard warning, active, and impact states.
  - Give the player time to read a warning before damage begins.
  - Make the active state show the damage area and the impact state show a completed trigger.

## Abilities

- [ ] Ember Bolt projectile, trail, and impact effect.
  - Use a fast ember projectile with a short, readable trail.
  - Point the projectile toward the mouse aim direction and make the impact flash brief.
- [ ] Blood Orbit orbiting weapon and enemy-hit effect.
  - Use a visible blood blade or shard that circles the demon.
  - Keep the orbit radius and hit timing readable when several enemies crowd the player.
- [ ] Core Pulse area ring, pulse animation, and impact effect.
  - Center the pulse on the Infernal Core and show its circular damage area.
  - Use a strong expanding ring without obscuring the core health state.
- [ ] Hellfire Field ground effect, warning state, and damage effect.
  - Place the field on the arena floor with a clear persistent footprint.
  - Use warning flames before activation and a stronger burn effect while it deals damage.
- [ ] Bone Spear projectile, pierce trail, and impact effect.
  - Give the spear a long, narrow silhouette that communicates piercing movement.
  - Keep the trail aligned with the projectile path and make each hit legible through a group.
- [ ] Chain Lash chain segments, lash animation, and hit effect.
  - Show the chain extending between the demon and each chained target.
  - Make the chain count and falloff readable without filling the screen.
- [ ] Imp Swarm imp projectile, imp summon, and impact effect.
  - Create a small imp visual that remains recognizable at projectile scale.
  - Give the swarm a homing motion cue and a distinct hit effect from Ember Bolt.
- [ ] Soul Drain drain beam or projectile, healing effect, and impact effect.
  - Connect the demon to the target with a visible drain path.
  - Show damage moving from the target into healing feedback on the demon.

## Evolved abilities

- [ ] Inferno Bolt distinct projectile and impact treatment.
  - Make it visibly stronger than Ember Bolt through size, color, or multiple projectiles.
  - Preserve the same aim behavior while signaling the evolved rank.
- [ ] Crimson Orbit distinct orbiting weapon and hit treatment.
  - Add more blades, a larger orbit, or a stronger blood trail than Blood Orbit.
  - Keep the effect readable around the demon during dense waves.
- [ ] Cataclysm Pulse distinct area effect and impact treatment.
  - Show a larger or layered pulse centered on the core.
  - Make its evolved scale clear without hiding the arena or HUD.
- [ ] Hellstorm distinct field, warning, and impact treatment.
  - Build from Hellfire Field with wider coverage and a more violent flame pattern.
  - Keep the warning state distinct from the active damage state.
- [ ] Grave Lance distinct projectile and pierce treatment.
  - Give the spear a heavier, more supernatural silhouette than Bone Spear.
  - Show its longer pierce path and stronger final impact.
- [ ] Writhing Chain distinct chain and hit treatment.
  - Use animated or segmented chains that feel more alive than Chain Lash.
  - Make additional links or targets visible without creating visual clutter.
- [ ] Greater Swarm distinct imp swarm treatment.
  - Increase the swarm's visual presence while keeping individual imps readable.
  - Give the evolved swarm a stronger homing trail and impact treatment.
- [ ] Soul Furnace distinct drain, healing, and impact treatment.
  - Make the drain feel like a larger ritual or furnace effect than Soul Drain.
  - Show a stronger return of health without obscuring the player sprite.

## Icons and interface

- [ ] Ability icons for Ember Bolt, Blood Orbit, Core Pulse, Hellfire Field, Bone Spear, Chain Lash, Imp Swarm, and Soul Drain.
  - Give each icon a unique silhouette that remains clear at upgrade-card size.
  - Keep the set consistent in border, lighting, and infernal palette.
- [ ] Passive icons for Emberheart, Cinder Step, Core Ward, Infernal Might, Quickened Flame, Long Reach, Soul Siphon, Grave Magnet, and Flesh of the Pit.
  - Use a simple symbol for each stat or gameplay effect.
  - Make passive icons distinct from ability icons at a glance.
- [ ] Demon icons for Ash Summoner, Core Bulwark, and Blood Harbinger.
  - Match each icon to its full demon sprite and portrait.
  - Make locked and unlocked presentation work without changing the icon silhouette.
- [ ] Evolution icons for Inferno Bolt, Crimson Orbit, Cataclysm Pulse, Hellstorm, Grave Lance, Writhing Chain, Greater Swarm, and Soul Furnace.
  - Reuse the base ability's visual language while adding a clear evolved marker.
  - Make each icon readable in a level-up choice alongside its base ability.
- [ ] Infernal Shards currency icon.
  - Use a small, high-contrast shard shape that reads beside the Stronghold balance.
  - Keep the icon legible in both the Stronghold and reward summary.
- [ ] HUD icons for pause, resume, display settings, upgrade choices, and run rewards.
  - Use familiar silhouettes and consistent button states.
  - Keep icons readable with keyboard, mouse, and controller navigation.
- [ ] Stronghold background and decorative art.
  - Establish the Infernal Stronghold as a persistent home screen rather than a plain color field.
  - Leave clear space for the title, currency, catalog, and start button.
- [ ] Stronghold panels, catalog cards, buttons, and locked/unlocked states.
  - Show ownership, cost, prerequisites, and current selection through clear visual states.
  - Keep long catalog descriptions readable against the panel background.
- [ ] Upgrade-screen panels, cards, buttons, and selected-state art.
  - Make three upgrade choices easy to compare during a paused run.
  - Distinguish new upgrades, rank increases, and evolved abilities.
- [ ] HUD art for the core health bar, XP bar, timer, wave display, level display, and reward summary.
  - Group persistent combat information without covering the arena.
  - Use color and icon states that remain readable during damage and level-up events.
- [ ] Keyboard, mouse, and controller prompt icons for the help text.
  - Show movement, aim, pause, confirm, and display controls for the active input method.
  - Keep prompts legible at the current viewport size.

## Combat feedback

- [ ] Player hit and hurt effects.
  - Flash or shake the player briefly without hiding the demon sprite.
  - Make repeated contact damage readable without creating screen clutter.
- [ ] Enemy hit effects.
  - Use a short effect that confirms damage and works across soldier, orc, and champion targets.
  - Support stronger variants for critical or high-damage hits if needed.
- [ ] Enemy death effects.
  - Give enemies a quick, readable defeat effect that does not obscure nearby targets.
  - Use a stronger treatment for champions.
- [ ] Level-up effect.
  - Signal the transition into the paused upgrade choice screen.
  - Tie the effect to the player's position without covering the upgrade cards.
- [ ] Core-damage effect.
  - Show when enemies damage the Infernal Core, including a direction or impact cue where practical.
  - Match the core's damaged-state art.
- [ ] Victory effect.
  - Mark the ten-minute win and transition cleanly to the reward summary.
  - Use the Infernal Stronghold palette and preserve the result text's readability.
- [ ] Defeat effect.
  - Distinguish player death from core destruction while preserving the run result.
  - Keep the effect short enough for a clear retry or return action.
- [ ] Run-reward effect.
  - Show Infernal Shards being awarded after victory or defeat.
  - Make the reward feel connected to the saved profile and Stronghold currency.
