class_name DemonBalanceReport
extends RefCounted

var mode := "review"
var generated_at := ""
var seeds: Array[int] = []
var criteria: Dictionary = {}
var baseline_runs: Array[DemonBalanceRunResult] = []
var selected_overrides: Dictionary = {}
var selected_runs: Array[DemonBalanceRunResult] = []
var baseline_summary: Dictionary = {}
var selected_summary: Dictionary = {}
var tuning: Dictionary = {}
var verdict := ""

func to_dictionary() -> Dictionary:
	return {
		"mode": mode,
		"generated_at": generated_at,
		"seeds": seeds,
		"criteria": criteria,
		"baseline_runs": _runs_to_dictionaries(baseline_runs),
		"selected_overrides": selected_overrides,
		"selected_runs": _runs_to_dictionaries(selected_runs),
		"baseline_summary": baseline_summary,
		"selected_summary": selected_summary,
		"tuning": tuning,
		"verdict": verdict,
	}

func _runs_to_dictionaries(runs: Array[DemonBalanceRunResult]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for run in runs:
		result.append(run.to_dictionary())
	return result
