extends RefCounted
## Hunter numeric score. Uses rng only for mood / judge noise.

const Enums := preload("res://src/core/enums.gd")


static func turnout_mod(horse) -> float:
	var m := 0.0
	if horse and horse.tack:
		if String(horse.tack.get("boots_uid", "")) != "" or float(horse.tack.get("care_mod", 0.0)) > 0.0:
			m -= 25.0
	return m


static func finalize(horse, class_def, course, events: Array, rng):
	var ResultScript = load("res://src/show/show_result.gd")
	var result = ResultScript.new()
	if horse:
		result.horse_uid = String(horse.uid)
	if class_def:
		result.class_id = class_def.id
	var spots: Array = []
	var tds: Array = []
	var margins: Array = []
	var majors := 0
	var disob := 0
	var elim := false
	var first_disob := true
	for e in events:
		if e == null or bool(e.finish_leg):
			continue
		if bool(e.fall):
			elim = true
		if bool(e.rail) or bool(e.refusal) or bool(e.runout):
			majors += 1
		if bool(e.refusal) or bool(e.runout):
			disob += 1
		if not bool(e.refusal) and not bool(e.runout):
			spots.append(absf(float(e.spot)))
			tds.append(float(e.time_delta))
			margins.append(float(e.scope_margin))
	var elim_after := 3
	if class_def:
		elim_after = int(class_def.refusal_elim_after)
	if disob >= elim_after:
		elim = true
	var mean_abs := 0.5
	if spots.size() > 0:
		var s := 0.0
		for v in spots:
			s += float(v)
		mean_abs = s / float(spots.size())
	var stdev := 0.0
	if tds.size() >= 2:
		var m := 0.0
		for v in tds:
			m += float(v)
		m /= float(tds.size())
		var acc := 0.0
		for v in tds:
			acc += (float(v) - m) * (float(v) - m)
		stdev = sqrt(acc / float(tds.size() - 1))
	var mean_margin := 0.0
	if margins.size() > 0:
		for v in margins:
			mean_margin += float(v)
		mean_margin /= float(margins.size())
	var ht := 0.76
	if class_def:
		ht = float(class_def.height_m)
	var gap := maxf(0.0, ht - float(horse.schooled_height_m))
	var fit_pen := clampf((55.0 - float(horse.fitness)) / 55.0, 0.0, 1.0)
	var even_pace := clampf(
		100.0 - mean_abs * 55.0 - stdev * 25.0
		- (50.0 - float(horse.hunter_schooling)) * 0.12
		- gap * 40.0 - fit_pen * 18.0,
		0.0, 100.0
	)
	var temp := 100.0
	match int(horse.temperament):
		Enums.Temperament.QUIET:
			temp = 90.0
		Enums.Temperament.LAZY:
			temp = 70.0
		Enums.Temperament.HOT:
			temp = 45.0
		Enums.Temperament.SPOOKY:
			temp = 40.0
	var manners := clampf(
		0.40 * float(horse.rideability) + 0.25 * temp + 0.15 * float(horse.energy)
		+ 0.10 * (100.0 - float(horse.overwork))
		+ 0.10 * (100.0 if float(horse.hunger) >= 30.0 else 40.0)
		- (8.0 if int(horse.temperament) == Enums.Temperament.HOT and float(horse.fitness) > 88.0 else 0.0)
		- (5.0 if float(horse.weight) > 7.0 else 0.0),
		0.0, 100.0
	)
	var form := clampf(
		0.55 * float(horse.style)
		+ 0.25 * clampf(50.0 + mean_margin * 1.2, 20.0, 90.0)
		+ 0.20 * (100.0 * (1.0 - mean_abs))
		- gap * 80.0
		- (50.0 - float(horse.hunter_schooling)) * 0.15,
		0.0, 100.0
	)
	var ideal := 16.1
	if class_def:
		ideal = float(class_def.ideal_height_hands)
	var height_fit := 100.0 - absf(float(horse.height_hands) - ideal) * 12.0
	var suitability := clampf(
		0.45 * float(horse.movement) + 0.35 * float(horse.conformation)
		+ 0.20 * clampf(height_fit, 40.0, 100.0),
		0.0, 100.0
	)
	var turnout := clampf(
		0.70 * float(horse.turnout_score) + 0.30 * float(horse.cleanliness) + turnout_mod(horse),
		0.0, 100.0
	)
	var expression := clampf(0.55 * float(horse.happiness) + 0.45 * float(horse.cleanliness), 0.0, 100.0)
	var style_c := float(horse.style)
	var base: float = (0.26 * style_c + 0.16 * even_pace + 0.14 * manners + 0.22 * form
		+ 0.10 * suitability + 0.07 * turnout + 0.05 * expression) * 0.92 + 8.0
	var d := 0.0
	first_disob = true
	for e in events:
		if e == null or bool(e.finish_leg):
			continue
		if bool(e.rub):
			d += clampf(-1.0 + _mood(rng), -1.5, -0.5)
		if absf(float(e.spot)) > 0.35 and not bool(e.refusal) and not bool(e.runout):
			d += -1.0 * absf(float(e.spot))
		if bool(e.swap):
			d += clampf(-3.0 + _mood(rng), -4.0, -2.0)
		if bool(e.break_gait):
			d += clampf(-4.5 + _mood(rng), -6.0, -3.0)
		if bool(e.rail):
			d += clampf(-6.0 + _mood(rng), -8.0, -4.0)
		if bool(e.refusal) or bool(e.runout):
			d += -8.0 if first_disob else -12.0
			first_disob = false
		if not bool(e.swap) and absf(float(e.spot)) > 0.55 and not bool(e.refusal) and not bool(e.runout):
			d += -2.0
	var raw := clampf(base + d + _mood(rng) * (0.40 / 0.30), 0.0, 100.0)
	var score := raw
	if elim:
		result.eliminated = true
		result.comment = "Major. They won't pin this one."
	elif majors >= 2:
		score = minf(raw, 58.0)
		result.comment = "A couple of majors. Low 50s."
	elif majors == 1:
		score = minf(raw, 69.5)
		result.comment = "One major. They won't win it."
	else:
		result.comment = "A pleasing trip." if score >= 80.0 else "Adequate. A bit plain."
	result.score = snapped(score, 0.5)
	result.events = events
	result.faults = majors * 4
	return result


static func _mood(rng) -> float:
	if rng == null:
		return 0.0
	return rng.randfn(0.0, 0.30)
