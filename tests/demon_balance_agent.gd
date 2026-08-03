extends Node

const DEMONS: Array[StringName] = [&"demon_summoner", &"demon_bulwark", &"demon_harbinger"]
const DEFAULT_SEEDS: Array[int] = [71001, 71002, 71003, 71004, 71005]
const DEFAULT_REPORT_PATH := "res://reports/demon_balance/latest"
const MAX_SURVIVAL_SECONDS := 600.0
const AGENT_VERSION := "1.0"
const MAX_CANDIDATES_PER_DEMON := 3

var evaluator: DemonBalanceEvaluator
var args: Dictionary = {}

func _ready() -> void:
	args = _parse_args(OS.get_cmdline_user_args())
	evaluator = DemonBalanceEvaluator.new()
	add_child(evaluator)
	await get_tree().process_frame
	var success := await _execute()
	get_tree().quit(0 if success else 1)

func _execute() -> bool:
	var seeds: Array[int] = args.seeds
	var report := DemonBalanceReport.new()
	report.mode = "tune" if args.tune else "review"
	report.generated_at = Time.get_datetime_string_from_system()
	report.seeds = seeds
	report.criteria = _criteria()
	var demon_ids: Array[StringName] = args.demons
	var baseline_runs := await evaluator.evaluate_batch(demon_ids, seeds, {})
	report.baseline_runs = baseline_runs
	report.baseline_summary = _summarize(baseline_runs)
	var selected_overrides: Dictionary = {}
	var selected_runs := baseline_runs
	if args.tune:
		var tuned := await _tune(baseline_runs, seeds, int(args.iterations), demon_ids)
		selected_overrides = tuned.overrides
		selected_runs = tuned.runs
		report.tuning = tuned.log
	else:
		report.tuning = {"applied": false, "iterations": 0, "candidates_evaluated": 0}
	report.selected_overrides = selected_overrides
	report.selected_runs = selected_runs
	report.selected_summary = _summarize(selected_runs)
	report.verdict = _verdict(report.selected_summary)
	if args.apply:
		if not args.tune:
			push_error("--apply requires --tune")
			return false
		if not _validate_overrides(selected_overrides):
			push_error("Selected balance candidate failed validation")
			return false
		if not DemonBalanceConfig.write_applied_overrides(selected_overrides):
			push_error("Could not write demon balance overrides")
			return false
		report.tuning["applied"] = true
	_write_report(report, String(args.report))
	print(report.verdict)
	return _report_is_valid(report)

func _tune(baseline_runs: Array[DemonBalanceRunResult], seeds: Array[int], iterations: int, demon_ids: Array[StringName]) -> Dictionary:
	var current := _catalog_candidates()
	var current_runs := baseline_runs
	var current_summary := _summarize(current_runs)
	var candidates_evaluated := 0
	var changes: Array[Dictionary] = []
	if iterations <= 0:
		return {"overrides": current, "runs": current_runs, "log": {"applied": false, "iterations": 0, "candidates_evaluated": 0, "changes": []}}
	for iteration in range(iterations):
		var improved := false
		for demon_id in demon_ids:
			var base: Dictionary = current[demon_id]
			for candidate in _candidate_variants(demon_id, base):
				var candidate_overrides := current.duplicate(true)
				candidate_overrides[demon_id] = candidate
				if not _validate_overrides(candidate_overrides):
					continue
				var candidate_runs := await evaluator.evaluate_batch(DEMONS, seeds, candidate_overrides)
				candidates_evaluated += 1
				var candidate_summary := _summarize(candidate_runs)
				if _is_better_candidate(candidate_summary, current_summary):
					changes.append({"iteration": iteration + 1, "demon_id": String(demon_id), "before": base, "after": candidate, "summary": candidate_summary})
					current = candidate_overrides
					current_runs = candidate_runs
					current_summary = candidate_summary
					improved = true
		if not improved:
			break
	return {"overrides": current, "runs": current_runs, "log": {"applied": false, "iterations": iterations, "candidates_evaluated": candidates_evaluated, "changes": changes}}

func _candidate_variants(demon_id: StringName, base: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var modifier_domains: Dictionary = {
		&"demon_summoner": {"xp_requirement_multiplier": [0.90, 0.95, 1.0, 1.05]},
		&"demon_bulwark": {"core_max_health": [30, 300, 600, 900], "core_effectiveness": [1.05, 1.15, 1.25, 1.35], "core_damage_multiplier": [0.05, 0.06, 0.07, 0.08]},
		&"demon_harbinger": {"xp_requirement_multiplier": [0.95, 1.0, 1.05], "close_damage": [0.12, 0.18, 0.24, 0.30], "drain_effectiveness": [1.25, 1.4, 1.55]},
	}
	for key in modifier_domains.get(demon_id, {}):
		var selected_for_key := false
		for value in modifier_domains[demon_id][key]:
			var candidate := base.duplicate(true)
			candidate["modifiers"][key] = value
			if _candidate_equal(candidate, base):
				continue
			result.append(candidate)
			selected_for_key = true
			break
		if selected_for_key and result.size() >= MAX_CANDIDATES_PER_DEMON:
			return result
	return result

func _candidate_equal(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(a) == JSON.stringify(b)

func _catalog_candidates() -> Dictionary:
	var result := {}
	for demon in RogueliteCatalog.demon_data():
		result[demon.id] = DemonBalanceConfig.candidate_from_demon(demon)
	return result

func _summarize(runs: Array[DemonBalanceRunResult]) -> Dictionary:
	var by_demon := {}
	for demon_id in DEMONS:
		var demon_runs: Array[DemonBalanceRunResult] = []
		for run in runs:
			if run.demon_id == demon_id:
				demon_runs.append(run)
		by_demon[String(demon_id)] = _summarize_demon(demon_runs)
	var ranked: Array[Dictionary] = []
	for demon_id in DEMONS:
		var summary: Dictionary = by_demon[String(demon_id)]
		ranked.append({"demon_id": String(demon_id), "weighted_score": summary.weighted_score})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.weighted_score) > float(b.weighted_score))
	var scores: Array[float] = []
	for entry in ranked: scores.append(float(entry.weighted_score))
	return {"demons": by_demon, "ranking": ranked, "strongest": ranked[0].demon_id if not ranked.is_empty() else "", "weakest": ranked[-1].demon_id if not ranked.is_empty() else "", "score_spread": _max(scores) - _min(scores)}

func _summarize_demon(runs: Array[DemonBalanceRunResult]) -> Dictionary:
	var survival: Array[float] = []
	var core: Array[float] = []
	var health: Array[float] = []
	var kills_per_minute: Array[float] = []
	var levels: Array[float] = []
	var first_levels: Array[float] = []
	var total_damage := 0
	var total_activations := 0
	var wins := 0
	for run in runs:
		if run.victory: wins += 1
		survival.append(run.survival_seconds)
		core.append(run.core_health_ratio)
		health.append(run.demon_health_ratio)
		kills_per_minute.append(run.kills_per_minute)
		levels.append(float(run.level))
		if run.first_level_seconds >= 0.0: first_levels.append(run.first_level_seconds)
		for key in run.ability_damage: total_damage += int(run.ability_damage[key])
		for key in run.ability_activations: total_activations += int(run.ability_activations[key])
	var median_survival := _median(survival)
	var median_core := _median(core)
	var median_health := _median(health)
	var median_kpm := _median(kills_per_minute)
	var median_level := _median(levels)
	var victory_rate := float(wins) / float(maxi(runs.size(), 1))
	var weighted_score := victory_rate * 40.0 + median_survival / MAX_SURVIVAL_SECONDS * 25.0 + median_core * 15.0 + median_health * 10.0 + minf(median_kpm / 3.0, 1.0) * 5.0 + minf(median_level / 25.0, 1.0) * 3.0 + minf(float(total_damage) / 10000.0, 1.0) * 2.0
	return {"runs": runs.size(), "wins": wins, "victory_rate": victory_rate, "median_survival_seconds": median_survival, "worst_survival_seconds": _min(survival), "median_core_health_ratio": median_core, "median_demon_health_ratio": median_health, "median_kills_per_minute": median_kpm, "median_level": median_level, "median_first_level_seconds": _median(first_levels), "total_ability_damage": total_damage, "total_ability_activations": total_activations, "weighted_score": weighted_score, "role_metrics": _role_metrics(runs)}

func _role_metrics(runs: Array[DemonBalanceRunResult]) -> Dictionary:
	var orbit_damage := 0
	var drain_damage := 0
	var unique_abilities := {}
	for run in runs:
		orbit_damage += int(run.ability_damage.get("blood_orbit", 0))
		drain_damage += int(run.ability_damage.get("life_drain", 0))
		for ability_id in run.ability_activations: unique_abilities[ability_id] = true
	return {"core_defense_proxy": _median(_values(runs, "core_health_ratio")), "close_damage_proxy": orbit_damage + drain_damage, "unique_abilities": unique_abilities.size()}

func _is_better_candidate(candidate: Dictionary, current: Dictionary) -> bool:
	if not _report_is_valid_summary(candidate): return false
	if not _report_is_valid_summary(current): return true
	return float(candidate.get("score_spread", 999.0)) < float(current.get("score_spread", 999.0)) or float(candidate.ranking[0].weighted_score) > float(current.ranking[0].weighted_score) and float(candidate.get("score_spread", 999.0)) <= float(current.get("score_spread", 999.0)) + 2.0

func _report_is_valid(report: DemonBalanceReport) -> bool:
	return _report_is_valid_summary(report.selected_summary)

func _report_is_valid_summary(summary: Dictionary) -> bool:
	var demons: Dictionary = summary.get("demons", {})
	if demons.size() != DEMONS.size(): return false
	var scores: Array[float] = []
	var survival: Array[float] = []
	for demon_id in DEMONS:
		var data: Dictionary = demons.get(String(demon_id), {})
		if float(data.get("victory_rate", 0.0)) < 0.8: return false
		scores.append(float(data.get("weighted_score", 0.0)))
		survival.append(float(data.get("median_survival_seconds", 0.0)))
	if _min(survival) < _max(survival) * 0.9: return false
	if _max(scores) - _min(scores) > 15.0: return false
	var summoner_role: Dictionary = demons.get("demon_summoner", {}).get("role_metrics", {})
	var bulwark_role: Dictionary = demons.get("demon_bulwark", {}).get("role_metrics", {})
	var harbinger_role: Dictionary = demons.get("demon_harbinger", {}).get("role_metrics", {})
	if float(bulwark_role.get("core_defense_proxy", 0.0)) + 0.02 < float(summoner_role.get("core_defense_proxy", 0.0)): return false
	if int(harbinger_role.get("close_damage_proxy", 0)) < int(summoner_role.get("close_damage_proxy", 0)): return false
	if int(demons.get("demon_summoner", {}).get("role_metrics", {}).get("unique_abilities", 0)) < 1: return false
	return true

func _verdict(summary: Dictionary) -> String:
	var valid := _report_is_valid_summary(summary)
	var demons: Dictionary = summary.get("demons", {})
	var weakest := String(summary.get("weakest", "unknown"))
	var strongest := String(summary.get("strongest", "unknown"))
	return ("BALANCED: " if valid else "IMBALANCED: ") + "%s strongest, %s weakest; hybrid gates %s" % [strongest, weakest, "pass" if valid else "fail"]

func _criteria() -> Dictionary:
	return {"minimum_victory_rate": 0.8, "minimum_survival_fraction_of_best": 0.9, "maximum_weighted_score_spread": 15.0, "role_policy": "Bulwark core defense, Harbinger close damage/sustain, Summoner flexibility"}

func _validate_overrides(overrides: Dictionary) -> bool:
	for demon_id in DEMONS:
		var validation := DemonBalanceConfig.validate_candidate(Dictionary(overrides.get(demon_id, {})))
		if not bool(validation.valid): return false
	return true

func _write_report(report: DemonBalanceReport, base_path: String) -> void:
	var output_path := base_path if not base_path.is_empty() else DEFAULT_REPORT_PATH
	if output_path.ends_with(".md"): output_path = output_path.trim_suffix(".md")
	if output_path.ends_with(".json"): output_path = output_path.trim_suffix(".json")
	var absolute_dir := ProjectSettings.globalize_path(output_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var json_file := FileAccess.open(output_path + ".json", FileAccess.WRITE)
	if json_file:
		json_file.store_string(JSON.stringify(report.to_dictionary(), "\t"))
		json_file.close()
	var markdown_file := FileAccess.open(output_path + ".md", FileAccess.WRITE)
	if markdown_file:
		markdown_file.store_string(_markdown(report))
		markdown_file.close()

func _markdown(report: DemonBalanceReport) -> String:
	var lines: Array[String] = ["# Demon Balance Review", "", "- Mode: `%s`" % report.mode, "- Generated: `%s`" % report.generated_at, "- Seeds: `%s`" % ", ".join(PackedStringArray(report.seeds.map(func(value: int) -> String: return str(value)))), "", "## Verdict", "", report.verdict, "", "## Ranking", "", "| Demon | Win rate | Median survival | Core | Demon HP | Kills/min | Level | Score |", "|---|---:|---:|---:|---:|---:|---:|---:|"]
	for entry in report.selected_summary.get("ranking", []):
		var data: Dictionary = report.selected_summary.demons[entry.demon_id]
		lines.append("| %s | %.0f%% | %.1fs | %.0f%% | %.0f%% | %.2f | %.1f | %.2f |" % [entry.demon_id, float(data.victory_rate) * 100.0, data.median_survival_seconds, float(data.median_core_health_ratio) * 100.0, float(data.median_demon_health_ratio) * 100.0, data.median_kills_per_minute, data.median_level, data.weighted_score])
	lines.append_array(["", "## Per-seed results", "", "| Demon | Seed | Result | Survival | Core | Kills/min | Level |", "|---|---:|---|---:|---:|---:|---:|"])
	for run in report.selected_runs:
		lines.append("| %s | %d | %s | %.1fs | %.0f%% | %.2f | %d |" % [run.demon_id, run.seed, "VICTORY" if run.victory else "DEFEAT", run.survival_seconds, run.core_health_ratio * 100.0, run.kills_per_minute, run.level])
	lines.append_array(["", "## Role metrics", "", "| Demon | Core defense proxy | Close damage proxy | Unique abilities |", "|---|---:|---:|---:|"])
	for demon_id in DEMONS:
		var data: Dictionary = report.selected_summary.demons[String(demon_id)]
		var role: Dictionary = data.role_metrics
		lines.append("| %s | %.0f%% | %d | %d |" % [demon_id, float(role.core_defense_proxy) * 100.0, role.close_damage_proxy, role.unique_abilities])
	lines.append_array(["", "## Baseline comparison", "", "The baseline is retained in `latest.json` under `baseline_runs` and `baseline_summary`. Tuning changes are listed under `tuning.changes`."])
	return "\n".join(lines) + "\n"

func _parse_args(command_args: PackedStringArray) -> Dictionary:
	var result := {"tune": false, "apply": false, "seeds": DEFAULT_SEEDS.duplicate(), "demons": DEMONS.duplicate(), "iterations": 1, "report": DEFAULT_REPORT_PATH}
	for value in command_args:
		if value == "--tune": result.tune = true
		elif value == "--apply": result.apply = true
		elif value.begins_with("--seeds="):
			var raw := value.trim_prefix("--seeds=")
			var parsed: Array[int] = []
			for item in raw.split(","):
				if not String(item).is_empty(): parsed.append(int(item))
			if not parsed.is_empty(): result.seeds = parsed
		elif value.begins_with("--iterations="): result.iterations = maxi(int(value.trim_prefix("--iterations=")), 0)
		elif value.begins_with("--demons="):
			var selected: Array[StringName] = []
			for item in value.trim_prefix("--demons=").split(","):
				if String(item) in ["demon_summoner", "demon_bulwark", "demon_harbinger"]: selected.append(StringName(item))
			if not selected.is_empty(): result.demons = selected
		elif value.begins_with("--report="): result.report = value.trim_prefix("--report=")
	return result

func _median(values: Array[float]) -> float:
	if values.is_empty(): return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2]) if sorted.size() % 2 == 1 else (float(sorted[sorted.size() / 2 - 1]) + float(sorted[sorted.size() / 2])) * 0.5

func _min(values: Array[float]) -> float:
	return values.min() if not values.is_empty() else 0.0

func _max(values: Array[float]) -> float:
	return values.max() if not values.is_empty() else 0.0

func _values(runs: Array[DemonBalanceRunResult], key: String) -> Array[float]:
	var result: Array[float] = []
	for run in runs:
		result.append(float(run.to_dictionary().get(key, 0.0)))
	return result
