extends RefCounted
## Ashford County Schooling Show — Saturday afternoon 0.80 m jumper.

const Enums := preload("res://src/core/enums.gd")
const ShowResolver := preload("res://src/show/show_resolver.gd")
const CourseDefScript := preload("res://src/show/course_def.gd")
const ClassDefScript := preload("res://src/show/class_def.gd")
const HorseStateScript := preload("res://src/horse/horse_state.gd")

const ENTRY := 45
const HAUL_OWN := 40
const HAUL_SHIP := 120
const PRIZES := [180, 120, 80, 50, 30, 15]


static func haul_cost(farm: Dictionary) -> int:
	if bool(farm.get("has_truck", false)) and bool(farm.get("has_trailer", false)):
		return HAUL_OWN
	return HAUL_SHIP


static func block_reason(data, horse) -> String:
	if data == null or data.clock == null:
		return "No clock."
	if horse == null:
		return "No horse."
	if int(data.clock.weekday) != Enums.Weekday.SAT:
		return "Ashford is Saturday."
	if int(data.clock.phase) != Enums.Phase.AFTERNOON:
		return "The 0.80 m is an afternoon class."
	if float(horse.soundness) < 55.0:
		return "Not sound enough to go in."
	if float(horse.energy) < 30.0:
		return "Too tired to show."
	if float(horse.schooled_height_m) + 0.20 < 0.80:
		return "That's a cruelty. School them first."
	var need := ENTRY + haul_cost(data.farm)
	if int(data.player.cash) < need:
		return "Can't cover entry and haul ($%d)." % need
	return ""


static func enter(data, horse, rng):
	var why := block_reason(data, horse)
	if why != "":
		return {"ok": false, "msg": why, "result": null, "placing": 0, "prize": 0}
	var farm: Dictionary = data.farm
	var haul := haul_cost(farm)
	return {
		"ok": true,
		"msg": "",
		"entry": ENTRY,
		"haul": haul,
		"need": ENTRY + haul,
	}


static func ride(data, horse, rng):
	var cls = ClassDefScript.ashford_080()
	var course = CourseDefScript.ashford_080()
	var player = ShowResolver.resolve_trip(horse, float(data.player.rider_skill), course, cls, [], 45.0, rng)
	var field: Array = [player]
	for i in 7:
		var npc = _npc(horse, i)
		field.append(ShowResolver.resolve_trip(npc, 32.0 + float(i), course, cls, [], 45.0, rng))
	field.sort_custom(func(a, b): return _better(a, b))
	var placing := 0
	for i in field.size():
		if field[i] == player:
			placing = i + 1
			break
	var prize := 0
	if placing >= 1 and placing <= PRIZES.size():
		prize = int(PRIZES[placing - 1])
	player.placing = placing
	player.prize = prize
	if placing == 1:
		player.comment = "A blue. That's the job."
	elif prize > 0:
		player.comment = "In the ribbons. Check's on the table."
	elif bool(player.eliminated):
		player.comment = "Whistle. Load them quiet and go home."
	else:
		player.comment = "Out of the money. Honest trip anyway."
	if horse.records is Array:
		horse.records.append({"show": "ashford_schooling", "placing": placing, "faults": player.faults})
	return {"result": player, "placing": placing, "prize": prize, "field": field}


static func _better(a, b) -> bool:
	var ae := bool(a.eliminated)
	var be := bool(b.eliminated)
	if ae != be:
		return not ae
	if int(a.faults) != int(b.faults):
		return int(a.faults) < int(b.faults)
	return float(a.time_sec) < float(b.time_sec)


static func _npc(template, i: int):
	var h = HorseStateScript.new()
	h.uid = "npc_%d" % i
	h.name = "Entry %d" % (i + 2)
	h.scope = float(template.scope) + float(i) - 3.0
	h.carefulness = float(template.carefulness) - 2.0 + float(i % 3)
	h.rideability = 58.0 + float(i)
	h.bravery = 50.0 + float(i)
	h.speed = 46.0 + float(i)
	h.stride = 50.0
	h.gymnastics = 40.0 + float(i)
	h.flatwork = 50.0
	h.jumper_schooling = 30.0 + float(i) * 2.0
	h.schooled_height_m = 0.78 + float(i) * 0.01
	h.fitness = 60.0
	h.soundness = 86.0
	h.hunger = 80.0
	h.hoof = 78.0
	h.weight = 5.2
	h.lead_changes = 48.0
	h.records = ["x"]
	return h
