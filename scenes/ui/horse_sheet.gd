extends PanelContainer

const Care := preload("res://src/care/care_system.gd")
const Enums := preload("res://src/core/enums.gd")

@onready var _body: Label = $Margin/Body


func refresh(data, horse) -> void:
	if horse == null:
		_body.text = "Click a horse."
		return
	var age_y := int(horse.age_months) / 12
	var loc := "out" if bool(horse.turned_out) else "in"
	var lines: PackedStringArray = [
		"%s  ·  %s" % [horse.name, loc],
		"%d yo  ·  %.1f hh  ·  %s" % [age_y, horse.height_hands, _coat_name(int(horse.coat))],
		"",
		"Keep: %s" % Care.hunger_line(horse),
		"Energy: %s" % Care.band(float(horse.energy)),
		"Coat: %s" % Care.band(float(horse.cleanliness)),
		Care.dirt_line(data, horse),
		"",
		Care.trainer_line(data, horse),
	]
	_body.text = "\n".join(lines)


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
