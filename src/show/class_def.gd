extends Resource

const Enums := preload("res://src/core/enums.gd")

@export var id: StringName = &""
@export var display_name: String = "0.80 m Jumper"
@export var discipline: int = Enums.Discipline.JUMPER
@export var height_m: float = 0.80
@export var height_label: String = "0.80 m"
@export var course_id: StringName = &""
@export var entry_fee: int = 45
@export var prizes: Array = [180, 120, 80, 50, 30, 15]
@export var field_size: int = 8
@export var atmosphere: float = 4.0
@export var refusal_elim_after: int = 3
@export var ideal_height_hands: float = 16.1
@export var braid_expected: bool = false


static func ashford_080():
	var c = new()
	c.id = &"ashford_080_jp"
	c.display_name = "0.80 m Jumper"
	c.height_m = 0.80
	c.height_label = "0.80 m"
	c.course_id = &"jp_080"
	c.atmosphere = 4.0
	c.refusal_elim_after = 3
	return c


static func home_gym():
	var c = new()
	c.id = &"home_gym_080"
	c.display_name = "Home gymnastic 0.80 m"
	c.height_m = 0.80
	c.height_label = "0.80 m"
	c.course_id = &"home_gym_080"
	c.atmosphere = 2.0
	c.entry_fee = 0
	c.refusal_elim_after = 3
	return c
