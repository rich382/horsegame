class_name TrainingSystem
extends RefCounted
## Nodeless. rest() is the only night energy/soundness tick. No rng.

const Enums := preload("res://src/core/enums.gd")


static func arena_training_efficiency(data) -> float:
	if data == null:
		return 0.15
	return float(data.farm.get("training_efficiency", 0.15))


static func block_reason(horse, data) -> String:
	if horse == null:
		return "No horse."
	if data == null or data.clock == null:
		return "No clock."
	if int(data.clock.phase) != Enums.Phase.AFTERNOON:
		return "Schooling is an afternoon job."
	if bool(horse.schooled_today):
		return "%s already worked today." % horse.name
	if float(horse.energy) < 35.0:
		return "Too tired to school."
	if float(horse.soundness) < 55.0:
		return "Not sound enough to school."
	return ""


static func kind_label(kind: int) -> String:
	if kind == Enums.TrainingKind.POLES:
		return "poles"
	if kind == Enums.TrainingKind.GYMNASTIC:
		return "gymnastic"
	return "flat"


static func apply_session(horse, kind: int, data, intensity: float = 0.55) -> String:
	var why := block_reason(horse, data)
	if why != "":
		return why
	var te := arena_training_efficiency(data)
	var rider := 35.0
	if data.player:
		rider = float(data.player.rider_skill)
	var skill := _skill_for(horse, kind)
	var gain := intensity * float(horse.rideability) / 100.0 * (1.0 - skill / 120.0) * (0.7 + rider / 200.0)
	gain *= 0.85 + te
	horse.energy = maxf(0.0, float(horse.energy) - (20.0 + intensity * 25.0))
	horse.fitness = minf(100.0, float(horse.fitness) + intensity * 6.0)
	horse.overwork = float(horse.overwork) + maxf(0.0, intensity * 20.0 - 8.0)
	horse.schooled_today = true
	horse.at_arena = true
	horse.turned_out = false
	var label := "flat"
	if kind == Enums.TrainingKind.POLES:
		horse.gymnastics = minf(100.0, float(horse.gymnastics) + gain)
		label = "poles"
	elif kind == Enums.TrainingKind.GYMNASTIC:
		horse.jumper_schooling = minf(100.0, float(horse.jumper_schooling) + gain)
		horse.gymnastics = minf(100.0, float(horse.gymnastics) + gain * 0.5)
		var ask := 0.80
		if ask <= float(horse.schooled_height_m) + 0.10:
			horse.schooled_height_m = maxf(float(horse.schooled_height_m), lerpf(float(horse.schooled_height_m), ask, 0.35))
		label = "gymnastic"
	else:
		horse.flatwork = minf(100.0, float(horse.flatwork) + gain)
	return "Worked %s. %s is a little fitter, a little more organized." % [label, horse.name]


static func _skill_for(horse, kind: int) -> float:
	if kind == Enums.TrainingKind.POLES:
		return float(horse.gymnastics)
	if kind == Enums.TrainingKind.GYMNASTIC:
		return float(horse.jumper_schooling)
	return float(horse.flatwork)


static func rest(horse) -> void:
	if horse == null:
		return
	if float(horse.energy) < 70.0:
		horse.energy = minf(100.0, float(horse.energy) + 15.0)
	else:
		horse.energy = minf(100.0, float(horse.energy) + 6.0)
	horse.soundness = minf(100.0, float(horse.soundness) + 0.35)
	if float(horse.overwork) > 0.0:
		horse.overwork = maxf(0.0, float(horse.overwork) - 8.0)
	if not bool(horse.schooled_today):
		horse.fitness = maxf(0.0, float(horse.fitness) - 0.25)
	else:
		horse.fitness = minf(100.0, float(horse.fitness) + 0.4)
