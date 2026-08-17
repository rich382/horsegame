extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const HunterJudge := preload("res://src/show/hunter_judge.gd")
const ShowResolver := preload("res://src/show/show_resolver.gd")
const CourseDefScript := preload("res://src/show/course_def.gd")
const ClassDefScript := preload("res://src/show/class_def.gd")
const ScriptRng := preload("res://tests/script_rng.gd")
const HorseStateScript := preload("res://src/horse/horse_state.gd")


static func run() -> int:
	var fails := 0
	var h = HorseStateScript.new()
	h.uid = "hu"
	h.scope = 56.0
	h.carefulness = 62.0
	h.style = 58.0
	h.rideability = 64.0
	h.bravery = 55.0
	h.speed = 48.0
	h.stride = 52.0
	h.gymnastics = 48.0
	h.flatwork = 55.0
	h.hunter_schooling = 40.0
	h.jumper_schooling = 42.0
	h.schooled_height_m = 0.85
	h.fitness = 62.0
	h.soundness = 88.0
	h.hunger = 85.0
	h.hoof = 80.0
	h.weight = 5.2
	h.movement = 54.0
	h.conformation = 60.0
	h.turnout_score = 40.0
	h.cleanliness = 65.0
	h.happiness = 70.0
	h.energy = 80.0
	h.lead_changes = 50.0
	h.records = ["x"]
	var cls = ClassDefScript.ashford_080()
	cls.discipline = Enums.Discipline.HUNTER
	cls.height_m = 0.76
	var rng = ScriptRng.new()
	var evs: Array = ShowResolver.resolve_events(h, 35.0, CourseDefScript.home_gym_080(), cls, [], 50.0, rng)
	var result = HunterJudge.finalize(h, cls, CourseDefScript.home_gym_080(), evs, rng)
	if result == null:
		push_error("hunter: no result")
		fails += 1
	elif float(result.score) < 0.0:
		push_error("hunter: bad score")
		fails += 1
	if fails == 0:
		print("test_hunter: ok")
	return fails
