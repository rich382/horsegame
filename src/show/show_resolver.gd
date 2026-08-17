extends RefCounted
## Closed fence math. Does not mutate the horse. Always mutates rng.

const Enums := preload("res://src/core/enums.gd")
const JumperJudgeScript := preload("res://src/show/jumper_judge.gd")
const FenceEventScript := preload("res://src/show/fence_event.gd")
const TackModsScript := preload("res://src/tack/tack_mods.gd")

const HEIGHT_KNOTS := [
	[0.60, 28.0],
	[0.76, 40.0],
	[0.80, 42.0],
	[0.91, 53.0],
	[1.00, 60.0],
	[1.10, 68.0],
	[1.20, 78.0],
	[1.30, 88.0],
]


static func height_to_need(height_m: float) -> float:
	if height_m <= float(HEIGHT_KNOTS[0][0]):
		return float(HEIGHT_KNOTS[0][1])
	for i in range(1, HEIGHT_KNOTS.size()):
		var a: Array = HEIGHT_KNOTS[i - 1]
		var b: Array = HEIGHT_KNOTS[i]
		if height_m <= float(b[0]):
			var t := (height_m - float(a[0])) / (float(b[0]) - float(a[0]))
			return lerpf(float(a[1]), float(b[1]), t)
	return float(HEIGHT_KNOTS.back()[1])


static func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))


static func resolve_fence(
	horse,
	rider_skill: float,
	fence,
	fence_index: int,
	prev_event,
	decision: int,
	class_def,
	course,
	footing_quality: float,
	rng
):
	var ev = FenceEventScript.new()
	ev.fence_index = fence_index
	ev.decision = decision
	var finish: bool = fence == null or fence_index >= course.fences.size()
	ev.finish_leg = finish
	var tack = TackModsScript.from_horse(horse)
	var planned := _planned_leg(course, fence_index)
	ev.planned_leg = planned

	if finish:
		_roll_time(ev, horse, tack, rider_skill, decision, planned, rng, false)
		return ev

	var spot_noise: float = rng.randfn(0.0, 0.35)
	var fx := _effects_with_footing(
		horse, tack, rider_skill, fence, prev_event, decision, class_def, spot_noise, footing_quality
	)
	ev.spot = float(fx["spot"])
	ev.p_disob = float(fx["p_disob"])
	ev.p_rail = float(fx["p_rail"])
	ev.p_refuse = float(fx["p_refuse"])
	ev.scope_margin = float(fx["scope_margin"])

	var p_refuse: float = float(fx["p_refuse"])
	var p_runout: float = float(fx["p_runout"])
	var u_disob: float = rng.randf()
	if u_disob < p_refuse:
		ev.refusal = true
	elif u_disob < p_refuse + p_runout:
		ev.runout = true
	if not ev.refusal and not ev.runout:
		var u_rail: float = rng.randf()
		var p_rail: float = float(fx["p_rail"])
		var p_rub: float = p_rail * 0.35
		if u_rail < p_rail:
			ev.rail = true
		elif u_rail < p_rail + p_rub:
			ev.rub = true
		ev.swap = rng.randf() < float(fx["p_swap"])
		ev.break_gait = rng.randf() < float(fx["p_break"])
	var p_fall: float = float(fx["p_fall"])
	if ev.rail or ev.refusal or ev.runout:
		ev.fall = rng.randf() < p_fall
	else:
		rng.randf()
	_roll_time(ev, horse, tack, rider_skill, decision, planned, rng, ev.refusal or ev.runout)
	return ev


static func resolve_events(
	horse,
	rider_skill: float,
	course,
	class_def,
	decisions: Array,
	footing_quality: float,
	rng
) -> Array:
	var events: Array = []
	var prev = null
	var i := 0
	var n: int = course.fences.size()
	var disob := 0
	var elim_after: int = int(class_def.refusal_elim_after)
	while i < n:
		var dec := Enums.Approach.STAY
		if i < decisions.size():
			dec = int(decisions[i])
		var ev = resolve_fence(
			horse, rider_skill, course.fences[i], i, prev, dec, class_def, course, footing_quality, rng
		)
		events.append(ev)
		if ev.fall:
			break
		if ev.refusal or ev.runout:
			disob += 1
			if disob >= elim_after:
				break
			prev = ev
			continue
		prev = ev
		i += 1
	if not _trip_dead(events, elim_after):
		var fin = resolve_fence(
			horse, rider_skill, null, n, prev, Enums.Approach.STAY, class_def, course, footing_quality, rng
		)
		events.append(fin)
	return events


static func resolve_trip(
	horse,
	rider_skill: float,
	course,
	class_def,
	decisions: Array,
	footing_quality: float,
	rng
):
	var events: Array = resolve_events(
		horse, rider_skill, course, class_def, decisions, footing_quality, rng
	)
	return JumperJudgeScript.finalize(horse, class_def, course, events)


static func preview(
	horse,
	rider_skill: float,
	fence,
	prev_event,
	decision: int,
	class_def,
	spot_noise: float = 0.0
) -> Dictionary:
	return _effects(horse, TackModsScript.from_horse(horse), rider_skill, fence, prev_event, decision, class_def, spot_noise)


static func _effects(
	horse,
	tack,
	rider_skill: float,
	fence,
	prev_event,
	decision: int,
	class_def,
	spot_noise: float
) -> Dictionary:
	var scope_eff: float = float(horse.scope) + float(horse.gymnastics) * 0.08 + float(tack.scope_mod)
	var hoof_penalty := clampf((70.0 - float(horse.hoof)) / 5.0, 0.0, 12.0)
	var care_eff: float = float(horse.carefulness) + float(horse.gymnastics) * 0.10 + float(tack.care_mod) - hoof_penalty
	var atmosphere := float(class_def.atmosphere)
	if horse.records == null or horse.records.is_empty():
		atmosphere += 6.0
	var brave_eff := float(horse.bravery) + rider_skill * 0.15 - atmosphere
	var ride_base := float(horse.rideability) + (-10.0 if float(horse.hunger) < 30.0 else 0.0)
	var ride_eff := ride_base + float(horse.flatwork) * 0.15 + rider_skill * 0.20
	var fit_pen := clampf((55.0 - float(horse.fitness)) / 55.0, 0.0, 1.0)
	var sound_pen := clampf((70.0 - float(horse.soundness)) / 70.0, 0.0, 1.0)
	var height_ask := float(fence.height_m) + float(fence.width_m) * 0.35
	var scope_need := height_to_need(height_ask)
	var scope_margin: float = scope_eff - scope_need
	var school_skill := float(horse.jumper_schooling)
	if int(class_def.discipline) == Enums.Discipline.HUNTER:
		school_skill = float(horse.hunter_schooling)
	var height_gap := maxf(0.0, float(fence.height_m) - float(horse.schooled_height_m))
	var school_term := (50.0 - school_skill) / 70.0
	var gap_term := height_gap / 0.15
	var hunter_track := int(class_def.discipline) == Enums.Discipline.HUNTER
	var skill_scale := 1.0 - (rider_skill - 35.0) / 200.0
	var leave_wait := 0.0
	if decision == Enums.Approach.WAIT:
		leave_wait = -0.25 * skill_scale
	elif decision == Enums.Approach.LEAVE:
		leave_wait = 0.28 * skill_scale
	var related := float(fence.related_distance_m)
	var stride_adj := _stride_adjust(float(horse.stride), related)
	var combo := 0.0
	if related > 0.0 and prev_event != null:
		if float(prev_event.time_delta) > 0.80:
			combo += 0.22
		elif float(prev_event.time_delta) < -0.80:
			combo -= 0.22
		if bool(prev_event.refusal) or bool(prev_event.runout):
			combo += 0.15
	var decision_tax := 0.0
	if decision == Enums.Approach.LEAVE and float(fence.spook) >= 0.40:
		decision_tax += 0.50
	if decision == Enums.Approach.WAIT and height_gap == 0.0 and float(fence.spook) < 0.20:
		decision_tax += 0.30
	decision_tax *= 1.0 - rider_skill / 130.0

	var spot := clampf(
		spot_noise + leave_wait + (50.0 - ride_eff) / 140.0 + fit_pen * 0.25 + stride_adj + combo,
		-1.2,
		1.2
	)
	var p_disob := sigmoid(
		-2.2
		+ float(fence.spook) * 1.6
		- brave_eff / 70.0
		- ride_eff / 90.0
		+ maxf(0.0, -scope_margin) / 18.0
		+ sound_pen * 0.8
		+ (0.4 if decision == Enums.Approach.LEAVE and int(horse.temperament) == Enums.Temperament.HOT else 0.0)
		+ school_term * 0.35
		+ gap_term * 0.90
		+ decision_tax
	)
	var p_runout_share := clampf(0.20 + float(fence.spook) * 0.35, 0.20, 0.55)
	var p_refuse := p_disob * (1.0 - p_runout_share)
	var p_runout := p_disob * p_runout_share
	var p_rail_sig := sigmoid(
		-1.6
		- care_eff / 55.0
		- maxf(scope_margin, -10.0) / 20.0
		+ absf(spot) * 1.3
		+ fit_pen * 0.9
		+ sound_pen * 0.7
		+ (0.35 if decision == Enums.Approach.LEAVE else 0.0)
		- (0.25 if decision == Enums.Approach.WAIT else 0.0)
		+ float(fence.width_m) * 0.4
		+ school_term * 0.55
		+ gap_term * 0.70
		+ decision_tax
	)
	var p_swap := sigmoid(
		-2.8 + (1.2 if hunter_track else 0.0)
		- float(horse.lead_changes) / 50.0
		- ride_eff / 80.0
		+ absf(spot) * 0.6
	)
	var p_break := sigmoid(
		-3.4
		+ absf(spot) * 0.9
		+ fit_pen * 1.1
		+ (0.6 if int(horse.temperament) == Enums.Temperament.LAZY else 0.0)
		- ride_eff / 90.0
		+ gap_term * 0.4
	)
	var p_fall := 0.012 + fit_pen * 0.010 + sound_pen * 0.015
	if int(horse.temperament) == Enums.Temperament.HOT and decision == Enums.Approach.LEAVE:
		p_fall += 0.02
	return {
		"spot": spot,
		"p_disob": p_disob,
		"p_refuse": p_refuse,
		"p_runout": p_runout,
		"p_rail_sig": p_rail_sig,
		"p_rail": p_rail_sig,
		"p_swap": p_swap,
		"p_break": p_break,
		"p_fall": p_fall,
		"scope_margin": scope_margin,
		"ride_eff": ride_eff,
		"stride_adjust": stride_adj,
	}


static func apply_footing(p_rail_sig: float, footing_quality: float) -> float:
	var rail_mod := (50.0 - footing_quality) / 200.0
	return clampf(p_rail_sig + rail_mod, 0.0, 0.95)


static func _effects_with_footing(
	horse,
	tack,
	rider_skill: float,
	fence,
	prev_event,
	decision: int,
	class_def,
	spot_noise: float,
	footing_quality: float
) -> Dictionary:
	var fx := _effects(horse, tack, rider_skill, fence, prev_event, decision, class_def, spot_noise)
	fx["p_rail"] = apply_footing(float(fx["p_rail_sig"]), footing_quality)
	return fx


static func _stride_adjust(stride: float, related_distance_m: float) -> float:
	if related_distance_m <= 0.0:
		return 0.0
	var stride_m := 3.10 + stride / 100.0 * 1.20
	var leftover: float = related_distance_m / stride_m - float(round(related_distance_m / stride_m))
	return leftover * 0.45


static func _planned_legs(course) -> PackedFloat32Array:
	var n: int = course.fences.size()
	var weights: Array = []
	var related_sum := 0.0
	for i in n:
		var rel := float(course.fences[i].related_distance_m)
		if rel > 0.0:
			weights.append(rel)
			related_sum += rel
		else:
			weights.append(-1.0)
	weights.append(-1.0)
	var n_open := 0
	for w in weights:
		if float(w) < 0.0:
			n_open += 1
	var open_share := (float(course.length_m) - related_sum) / float(maxi(n_open, 1))
	var ta: float = float(course.time_allowed())
	var out := PackedFloat32Array()
	var length := maxf(float(course.length_m), 0.001)
	for w in weights:
		var ww := float(w)
		if ww < 0.0:
			ww = open_share
		out.append(ta * (ww / length))
	return out


static func _planned_leg(course, fence_index: int) -> float:
	var legs := _planned_legs(course)
	if fence_index < 0 or fence_index >= legs.size():
		return 0.0
	return legs[fence_index]


static func _roll_time(
	ev,
	horse,
	tack,
	rider_skill: float,
	decision: int,
	planned: float,
	rng,
	disob: bool
) -> void:
	var time_noise: float = rng.randfn(0.0, 0.25)
	var fit_pen := clampf((55.0 - float(horse.fitness)) / 55.0, 0.0, 1.0)
	var sound_pen := clampf((70.0 - float(horse.soundness)) / 70.0, 0.0, 1.0)
	var speed_eff: float = float(horse.speed) + float(tack.speed_mod)
	if float(horse.weight) > 7.0:
		speed_eff -= 8.0
	var pace := 1.0
	if decision == Enums.Approach.WAIT:
		pace = 1.08
	elif decision == Enums.Approach.LEAVE:
		pace = 0.94
	var actual := planned
	actual *= 1.0 + fit_pen * 0.10 + sound_pen * 0.06
	actual *= 1.0 - (speed_eff - 50.0) / 400.0
	actual *= pace
	actual += time_noise
	if disob:
		actual += 6.0 + rng.randf_range(4.0, 8.0)
	ev.actual_leg = actual
	ev.time_delta = actual - planned


static func _trip_dead(events: Array, elim_after: int) -> bool:
	var disob := 0
	for e in events:
		if e.fall:
			return true
		if e.refusal or e.runout:
			disob += 1
			if disob >= elim_after:
				return true
	return false
