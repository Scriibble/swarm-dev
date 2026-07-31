class_name RunReward
extends RefCounted

var survival_seconds: int = 0
var kills: int = 0
var core_health_ratio: float = 0.0
var victory: bool = false
var currency_awarded: int = 0

func to_dictionary() -> Dictionary:
	return {
		"survival_seconds": survival_seconds,
		"kills": kills,
		"core_health_ratio": core_health_ratio,
		"victory": victory,
		"currency_awarded": currency_awarded,
	}
