extends RefCounted

const Enums := preload("res://src/core/enums.gd")


static func evaluate(horse, class_height_m: float, cash: int, need: int) -> Dictionary:
	var hard := PackedStringArray()
	var soft := PackedStringArray()
	if horse == null:
		hard.append("No horse.")
	else:
		if float(horse.soundness) < 55.0:
			hard.append("Not sound.")
		if float(horse.energy) < 30.0:
			hard.append("Too tired.")
		if int(horse.age_months) < 48:
			hard.append("Too young.")
		if float(horse.schooled_height_m) + 0.20 < class_height_m:
			hard.append("Cruelty — they have not schooled this.")
		if float(horse.schooled_height_m) + 0.05 < class_height_m:
			soft.append("Overfaced — they have not schooled this height.")
	if cash < need:
		hard.append("Can't cover entry and haul.")
	return {"ok": hard.is_empty(), "hard": hard, "soft": soft}
