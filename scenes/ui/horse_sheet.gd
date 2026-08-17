extends PanelContainer

const Care := preload("res://src/care/care_system.gd")
const Enums := preload("res://src/core/enums.gd")

@onready var _body: Label = $Margin/Body


func refresh(data, horse) -> void:
	if horse == null:
		_body.text = "Click a horse."
		return
	var age_y := int(horse.age_months) / 12
	var loc := "in"
	if bool(horse.at_arena):
		loc = "in the arena"
	elif bool(horse.turned_out):
		loc = "out"
	var lines: PackedStringArray = [
		"%s  ·  %s" % [horse.name, loc],
		"%d yo  ·  %.1f hh  ·  %s" % [age_y, horse.height_hands, _coat_name(int(horse.coat))],
		"",
		"Keep: %s" % Care.hunger_line(horse),
		"Energy: %s" % Care.band(float(horse.energy)),
		"Coat: %s" % Care.band(float(horse.cleanliness)),
		Care.dirt_line(data, horse),
		"Work: %s" % _work_line(horse),
		_farrier_line(data, horse),
		"",
		Care.trainer_line(data, horse),
	]
	_body.text = "\n".join(lines)


func _work_line(horse) -> String:
	if bool(horse.schooled_today):
		return "already schooled"
	return "not worked today"


func _farrier_line(data, horse) -> String:
	if data == null or data.clock == null:
		return "Farrier: —"
	var due_in := 14 - (int(data.clock.abs_day()) - int(horse.last_farrier_abs_day))
	if due_in <= 0:
		return "Farrier is due."
	return "Farrier in %d days." % due_in


func _coat_name(coat: int) -> String:
	match coat:
		Enums.CoatColor.CHESTNUT:
			return "chestnut"
		Enums.CoatColor.GREY:
			return "grey"
		Enums.CoatColor.BLACK:
			return "black"
		_:
			return "bay"
