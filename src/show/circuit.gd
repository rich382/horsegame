extends RefCounted
## Schooling circuit. Ashford Saturday, Crossridge Sunday, Mill Brook 0.90.

const Enums := preload("res://src/core/enums.gd")
const ShowResolver := preload("res://src/show/show_resolver.gd")
const CourseDefScript := preload("res://src/show/course_def.gd")
const ClassDefScript := preload("res://src/show/class_def.gd")
const HorseStateScript := preload("res://src/horse/horse_state.gd")
const HunterJudge := preload("res://src/show/hunter_judge.gd")
const JumperJudge := preload("res://src/show/jumper_judge.gd")

const HAUL_OWN := 40
const HAUL_SHIP := 120
const PRIZES := [180, 120, 80, 50, 30, 15]

const SHOWS := [
	{
		"id": "ashford",
		"name": "Ashford County Schooling",
		"class_label": "0.80 m Jumper",
		"weekday": Enums.Weekday.SAT,
		"height_m": 0.80,
		"footing": 45.0,
		"entry": 45,
	},
	{
		"id": "crossridge",
		"name": "Crossridge Schooling",
		"class_label": "0.80 m Jumper",
		"weekday": Enums.Weekday.SUN,
		"height_m": 0.80,
		"footing": 42.0,
		"entry": 40,
	},
	{
		"id": "millbrook",
		"name": "Mill Brook",
		"class_label": "0.90 m Jumper",
		"weekday": Enums.Weekday.SAT,
		"height_m": 0.90,
		"footing": 48.0,
		"entry": 55,
	},
	{
		"id": "ashford_hu",
		"name": "Ashford County Schooling",
		"class_label": "2'6\" Hunter",
		"weekday": Enums.Weekday.SAT,
		"height_m": 0.76,
		"footing": 45.0,
		"entry": 45,
		"hunter": true,
	},
	{
		"id": "willow",
		"name": "Willow Park",
		"class_label": "1.00 m Jumper",
		"weekday": Enums.Weekday.SUN,
		"height_m": 1.00,
		"footing": 50.0,
		"entry": 65,
	},
]


static func show_by_id(show_id: String) -> Dictionary:
	for s in SHOWS:
		if String(s["id"]) == show_id:
			return s
	return {}


static func haul_cost(farm: Dictionary, show_id: String = "") -> int:
	if show_id != "" and String(farm.get("loaded_for", "")) == show_id:
		return 0
	if bool(farm.get("has_truck", false)) and bool(farm.get("has_trailer", false)):
		return HAUL_OWN
	return HAUL_SHIP


static func block_reason(data, horse, show: Dictionary) -> String:
	if data == null or data.clock == null:
		return "No clock."
	if horse == null:
		return "No horse."
	if show.is_empty():
		return "No class."
	if int(data.clock.weekday) != int(show["weekday"]):
		return "%s is %s." % [show["name"], _day_name(int(show["weekday"]))]
	if int(data.clock.phase) != Enums.Phase.AFTERNOON:
		return "That class is afternoon."
	if float(horse.soundness) < 55.0:
		return "Not sound enough to go in."
	if float(horse.energy) < 30.0:
		return "Too tired to show."
	var ht := float(show["height_m"])
	if float(horse.schooled_height_m) + 0.20 < ht:
		return "That's a cruelty. School them first."
	var need := int(show["entry"]) + haul_cost(data.farm, String(show["id"]))
	if int(data.player.cash) < need:
		return "Can't cover entry and haul ($%d)." % need
	return ""


static func enter_quote(data, horse, show: Dictionary) -> Dictionary:
	var why := block_reason(data, horse, show)
	if why != "":
		return {"ok": false, "msg": why}
	var haul := haul_cost(data.farm, String(show["id"]))
	return {"ok": true, "entry": int(show["entry"]), "haul": haul, "need": int(show["entry"]) + haul}


static func ride(data, horse, rng, show: Dictionary) -> Dictionary:
	var cls = ClassDefScript.ashford_080()
	cls.display_name = String(show["class_label"])
	cls.height_m = float(show["height_m"])
	cls.id = StringName(String(show["id"]))
	var course = CourseDefScript.ashford_080()
	if float(show["height_m"]) > 0.85:
		for f in course.fences:
			f.height_m = float(show["height_m"])
	var hunter := bool(show.get("hunter", false))
	if hunter:
		cls.discipline = Enums.Discipline.HUNTER
		cls.height_label = "2'6\""
	var player = _one_trip(horse, float(data.player.rider_skill), course, cls, float(show["footing"]), rng, hunter)
	var field: Array = [player]
	for i in 7:
		field.append(_one_trip(_npc(horse, i), 32.0 + float(i), course, cls, float(show["footing"]), rng, hunter))
	if hunter:
		field.sort_custom(func(a, b): return _better_hunter(a, b))
	else:
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
	player.class_id = cls.id
	if placing == 1:
		player.comment = "A blue. That's the job."
	elif prize > 0:
		player.comment = "In the ribbons. Check's on the table."
	elif bool(player.eliminated):
		player.comment = "Whistle. Load them quiet and go home."
	else:
		player.comment = "Out of the money. Honest trip anyway."
	if horse.records is Array:
		horse.records.append({"show": String(show["id"]), "placing": placing, "faults": player.faults})
	return {"result": player, "placing": placing, "prize": prize}


static func load_block(data, show: Dictionary) -> String:
	if data == null or data.clock == null:
		return "No clock."
	if not (bool(data.farm.get("has_truck", false)) and bool(data.farm.get("has_trailer", false))):
		return "Need the rig to load yourself."
	if int(data.clock.phase) != Enums.Phase.EVENING:
		return "Load in the evening."
	var eve := int(show["weekday"]) - 1
	if eve < 0:
		eve = 6
	if int(data.clock.weekday) != eve:
		return "Load the night before %s." % _day_name(int(show["weekday"]))
	return ""


static func _day_name(d: int) -> String:
	var names := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
	if d < 0 or d >= names.size():
		return "show day"
	return names[d]


static func _one_trip(horse, rider: float, course, cls, footing: float, rng, hunter: bool):
	var events: Array = ShowResolver.resolve_events(horse, rider, course, cls, [], footing, rng)
	if hunter:
		return HunterJudge.finalize(horse, cls, course, events, rng)
	return JumperJudge.finalize(horse, cls, course, events)


static func _better_hunter(a, b) -> bool:
	if bool(a.eliminated) != bool(b.eliminated):
		return not bool(a.eliminated)
	return float(a.score) > float(b.score)


static func _better(a, b) -> bool:
	if bool(a.eliminated) != bool(b.eliminated):
		return not bool(a.eliminated)
	if int(a.faults) != int(b.faults):
		return int(a.faults) < int(b.faults)
	return float(a.time_sec) < float(b.time_sec)


static func _npc(template, i: int):
	var h = HorseStateScript.new()
	h.uid = "npc_%d" % i
	h.name = "Entry %d" % (i + 2)
	h.scope = float(template.scope) + float(i) - 3.0
	h.carefulness = float(template.carefulness) - 2.0
	h.rideability = 58.0 + float(i)
	h.bravery = 50.0 + float(i)
	h.speed = 46.0
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
