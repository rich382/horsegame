extends Resource

const Enums := preload("res://src/core/enums.gd")
const FenceDefScript := preload("res://src/show/fence_def.gd")

@export var id: StringName = &""
@export var theater_scene: String = ""
@export var fences: Array = []
@export var length_m: float = 80.0
@export var time_allowed_sec: float = 0.0
@export var speed_mpm: int = 350
@export var jump_off_id: StringName = &""
@export var discipline: int = Enums.Discipline.JUMPER


func time_allowed() -> float:
	if time_allowed_sec > 0.0:
		return time_allowed_sec
	if length_m <= 0.0:
		return 60.0
	return length_m / (float(speed_mpm) / 60.0)


static func ashford_080():
	var c = new()
	c.id = &"jp_080"
	c.length_m = 320.0
	c.speed_mpm = 350
	c.time_allowed_sec = 55.0
	c.fences = [
		FenceDefScript.make("a1", 0.80, 0.0, 0.10, 0.0),
		FenceDefScript.make("a2", 0.80, 0.0, 0.12, 0.0),
		FenceDefScript.make("a3", 0.80, 0.55, 0.18, 0.0),
		FenceDefScript.make("a4", 0.80, 0.0, 0.10, 21.95),
		FenceDefScript.make("a5", 0.80, 0.0, 0.22, 0.0),
		FenceDefScript.make("a6", 0.80, 0.40, 0.16, 0.0),
	]
	return c


static func home_gym_080():
	var c = new()
	c.id = &"home_gym_080"
	c.length_m = 80.0
	c.speed_mpm = 325
	c.time_allowed_sec = 0.0
	c.fences = [
		FenceDefScript.make("hg1", 0.80, 0.0, 0.08, 0.0),
		FenceDefScript.make("hg2", 0.80, 0.0, 0.12, 7.5),
		FenceDefScript.make("hg3", 0.80, 0.60, 0.22, 0.0),
		FenceDefScript.make("hg4", 0.80, 0.0, 0.10, 0.0),
	]
	return c
