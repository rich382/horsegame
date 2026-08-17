extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const ShowResolver := preload("res://src/show/show_resolver.gd")
const JumperJudge := preload("res://src/show/jumper_judge.gd")
const ScriptRng := preload("res://tests/script_rng.gd")
const HorseStateScript := preload("res://src/horse/horse_state.gd")
const FenceDefScript := preload("res://src/show/fence_def.gd")
const FenceEventScript := preload("res://src/show/fence_event.gd")
const ClassDefScript := preload("res://src/show/class_def.gd")
const CourseDefScript := preload("res://src/show/course_def.gd")


static func run() -> int:
	var fails := 0
	fails += _oracle_a()
	fails += _oracle_b()
	fails += _oracle_c()
	fails += _oracle_d()
	fails += _footing_contrast()
	fails += _judge_time()
	fails += _home_gym_trip()
	if fails == 0:
		print("test_jumper_judge: ok")
	return fails


static func _bayberry():
	var h = HorseStateScript.new()
	h.uid = "bayberry_fix"
	h.name = "Bayberry"
	h.scope = 56.0
	h.carefulness = 62.0
	h.style = 58.0
	h.rideability = 64.0
	h.bravery = 55.0
	h.speed = 48.0
	h.stride = 52.0
	h.lead_changes = 50.0
	h.movement = 54.0
	h.conformation = 60.0
	h.gymnastics = 48.0
	h.flatwork = 55.0
	h.jumper_schooling = 42.0
	h.hunter_schooling = 40.0
	h.schooled_height_m = 0.85
	h.fitness = 62.0
	h.soundness = 88.0
	h.hunger = 85.0
	h.hoof = 80.0
	h.weight = 5.2
	h.temperament = Enums.Temperament.HONEST
	h.records = []
	h.tack = {}
	return h


static func _cls():
	return ClassDefScript.ashford_080()


static func _fence_a():
	return FenceDefScript.make("f1", 0.80, 0.0, 0.10, 0.0)


static func _near(got: float, want: float, eps: float, label: String) -> int:
	if abs(got - want) > eps:
		push_error("jumper %s: got %s want %s" % [label, str(got), str(want)])
		return 1
	return 0


static func _oracle_a() -> int:
	var fails := 0
	var fx: Dictionary = ShowResolver.preview(_bayberry(), 35.0, _fence_a(), null, Enums.Approach.STAY, _cls(), 0.0)
	fails += _near(float(fx["spot"]), -0.2089, 0.01, "A spot")
	fails += _near(float(fx["p_disob"]), 0.02664, 0.001, "A p_disob")
	fails += _near(float(fx["p_refuse"]), 0.02038, 0.001, "A p_refuse")
	fails += _near(float(fx["p_rail"]), 0.03320, 0.001, "A p_rail")
	return fails


static func _oracle_b() -> int:
	var fails := 0
	var fence = FenceDefScript.make("rel", 0.80, 0.0, 0.10, 21.95)
	var prev = FenceEventScript.new()
	prev.time_delta = 0.0
	var fx: Dictionary = ShowResolver.preview(_bayberry(), 35.0, fence, prev, Enums.Approach.STAY, _cls(), 0.0)
	fails += _near(float(fx["stride_adjust"]), -0.0476, 0.01, "B stride")
	fails += _near(float(fx["spot"]), -0.2565, 0.01, "B spot")
	return fails


static func _oracle_c() -> int:
	var fails := 0
	var fence = FenceDefScript.make("ox", 0.80, 0.80, 0.55, 0.0)
	var fx: Dictionary = ShowResolver.preview(_bayberry(), 35.0, fence, null, Enums.Approach.STAY, _cls(), 0.0)
	fails += _near(float(fx["scope_margin"]), -6.56, 0.05, "C margin")
	fails += _near(float(fx["p_disob"]), 0.0748, 0.001, "C p_disob")
	fails += _near(float(fx["p_rail"]), 0.1380, 0.001, "C p_rail")
	return fails


static func _oracle_d() -> int:
	var fails := 0
	var h = _bayberry()
	h.schooled_height_m = 0.65
	h.jumper_schooling = 18.0
	var fx: Dictionary = ShowResolver.preview(h, 35.0, _fence_a(), null, Enums.Approach.STAY, _cls(), 0.0)
	fails += _near(float(fx["p_disob"]), 0.0705, 0.001, "D p_disob")
	fails += _near(float(fx["p_rail"]), 0.0770, 0.001, "D p_rail")
	var a: Dictionary = ShowResolver.preview(_bayberry(), 35.0, _fence_a(), null, Enums.Approach.STAY, _cls(), 0.0)
	if float(fx["p_rail"]) <= float(a["p_rail"]):
		push_error("jumper D: unschooled rail should be worse")
		fails += 1
	return fails


static func _footing_contrast() -> int:
	var fails := 0
	var sig := 0.03320
	fails += _near(ShowResolver.apply_footing(sig, 50.0), 0.03320, 0.0001, "foot 50")
	fails += _near(ShowResolver.apply_footing(sig, 40.0), 0.08320, 0.0001, "foot 40")
	fails += _near(ShowResolver.apply_footing(sig, 65.0), 0.0, 0.0001, "foot 65")
	return fails


static func _judge_time() -> int:
	var fails := 0
	if JumperJudge.time_faults(54.9, 55.0) != 0:
		push_error("jumper: time under TA should be 0")
		fails += 1
	if JumperJudge.time_faults(56.1, 55.0) != 2:
		push_error("jumper: 56.1 vs 55 should be 2 commenced seconds")
		fails += 1
	return fails


static func _home_gym_trip() -> int:
	var fails := 0
	var rng = ScriptRng.new()
	var result = ShowResolver.resolve_trip(
		_bayberry(),
		35.0,
		CourseDefScript.home_gym_080(),
		ClassDefScript.home_gym(),
		[],
		40.0,
		rng
	)
	if result == null or result.events.is_empty():
		push_error("jumper: home gym produced no events")
		fails += 1
		return fails
	if result.recap_lines().is_empty():
		push_error("jumper: recap empty")
		fails += 1
	return fails
