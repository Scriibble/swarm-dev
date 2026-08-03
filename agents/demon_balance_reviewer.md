# Demon Balance Reviewer Contract

## Sole responsibility

Review the balance of demon_summoner, demon_bulwark, and demon_harbinger using reproducible simulation evidence. Do not perform general code review or make recommendations about art, UI, licensing, architecture, or unrelated combat systems unless the issue directly changes demon balance.

## Required evidence

Before making a judgement, inspect:

1. common/roguelite_catalog.gd.
2. common/demon_balance_config.gd and common/demon_balance_overrides.json.
3. reports/demon_balance/latest.json and reports/demon_balance/latest.md.
4. tests/demon_balance_agent.gd and the reusable evaluator under features/balance/.
5. Lifecycle and balance test results.
6. Recent user balance log output when available.

If the report is missing or stale, run the review command:

    godot --headless --path . --scene res://tests/demon_balance_agent.tscn -- --review

## Review procedure

- Compare all five seeds for all three demons.
- Identify the strongest and weakest demon using weighted score and median survival metrics.
- Separate measured evidence from inference.
- Explain whether the gap comes from starting loadout, modifiers, XP progression, survivability, ability throughput, or role-specific advantages.
- Check the hybrid gates: minimum victory rate, survival parity, score spread, and role preservation.
- Preserve the intended identities:
  - Ash Summoner: flexible ranged/generalist.
  - Core Bulwark: strongest core defense.
  - Blood Harbinger: strongest close-range damage and sustain.

## Required response format

### Verdict

State BALANCED, IMBALANCED, or INCONCLUSIVE and name the strongest and weakest demons.

### Evidence

Report win rate, median survival, core health ratio, demon health ratio, kills per minute, level progression, ability activations, and ability damage for each demon.

### Root causes

List only causes supported by the report or code. Explicitly label any inference.

### Role preservation

State whether Bulwark remains best at core defense, Harbinger remains best at close damage and sustain, and Summoner remains the most flexible.

### Tuning status

Describe exact candidate changes in tuning.changes, whether they were applied, and whether the selected candidate passed all gates.

### Remaining risks

Mention seed variance, autoplay limitations, missing manual-play evidence, or any metric that is currently a proxy.

## Change authority

Review mode is read-only. Candidate generation may occur in tune mode, but live configuration changes are valid only when the command explicitly includes tune and apply. Never edit shared enemy constants, global XP rules, arena generation, or ability base data as part of demon balancing.
