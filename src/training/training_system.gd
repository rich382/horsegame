class_name TrainingSystem
extends RefCounted
## Nodeless. rest() is the only night energy/soundness tick. No rng.


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
