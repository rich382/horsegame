extends RefCounted
## Table II-style schooling jumper. No rng.

const Enums := preload("res://src/core/enums.gd")


static func time_faults(time_sec: float, time_allowed: float) -> int:
	if time_sec <= time_allowed:
		return 0
	return ceili(time_sec - time_allowed - 1e-9)


static func finalize(horse, class_def, course, events: Array):
	var ResultScript = load("res://src/show/show_result.gd")
	var result = ResultScript.new()
	if horse:
		result.horse_uid = String(horse.uid)
	if class_def:
		result.class_id = class_def.id
	var ta := 60.0
	if course:
		ta = float(course.time_allowed())
	var elim_after := 3
	if class_def:
		elim_after = int(class_def.refusal_elim_after)
	var faults := 0
	var disob := 0
	var time_sec := 0.0
	var rails := 0
	for e in events:
		if e == null:
			continue
		if not bool(e.finish_leg):
			time_sec += float(e.actual_leg)
		else:
			time_sec += float(e.actual_leg)
		if bool(e.fall):
			result.eliminated = true
		if bool(e.rail):
			faults += 4
			rails += 1
		if bool(e.refusal) or bool(e.runout):
			disob += 1
			if disob >= elim_after:
				result.eliminated = true
			else:
				faults += 4
	if time_sec > 2.0 * ta:
		result.eliminated = true
	else:
		faults += time_faults(time_sec, ta)
	result.faults = faults
	result.time_sec = time_sec
	result.events = events
	if result.eliminated:
		result.comment = "That's the whistle."
	elif rails == 0 and disob == 0:
		result.comment = "A nice clear. That's the job."
	elif rails > 0 and disob == 0:
		result.comment = "A rail. They'll learn from it."
	elif disob > 0:
		result.comment = "They said no. Don't make a thing of it."
	else:
		result.comment = "Honest trip."
	return result
