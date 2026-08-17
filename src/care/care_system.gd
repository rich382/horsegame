class_name CareSystem
extends RefCounted
## Nodeless care ticks and chores. No rng.

const Enums := preload("res://src/core/enums.gd")

const CARE_QUALITY_STARTER := 0.50


static func barn_care_quality(data) -> float:
	if data == null:
		return CARE_QUALITY_STARTER
	var farm: Dictionary = data.farm if data.farm else {}
	return float(farm.get("care_quality", CARE_QUALITY_STARTER))


static func stall_for(data, horse) -> Dictionary:
	if data == null or horse == null:
		return {}
	var farm: Dictionary = data.farm if data.farm else {}
	var stalls: Array = farm.get("stalls", [])
	var sid := String(horse.stall_id)
	for s in stalls:
		if String(s.get("id", "")) == sid:
			return s
	return {}


static func apply_phase_decay(data, phase) -> void:
	if data == null:
		return
	var cq := barn_care_quality(data)
	for h in data.horses:
		if h == null:
			continue
		_hunger_for_phase(h, phase)
		if not bool(h.phase_busy):
			h.energy = minf(_energy_cap(h), float(h.energy) + 8.0)
		if bool(h.turned_out):
			h.happiness = minf(100.0, float(h.happiness) + 4.0)
		if int(phase) == Enums.Phase.MORNING and not bool(h.picked_stall_today) and not bool(h.turned_out):
			var stall := stall_for(data, h)
			if not stall.is_empty():
				stall["dirt"] = float(stall.get("dirt", 0.0)) + 25.0 * (1.0 - 0.40 * cq)
		var stall2 := stall_for(data, h)
		if not stall2.is_empty() and float(stall2.get("dirt", 0.0)) > 60.0:
			h.happiness = maxf(0.0, float(h.happiness) - 6.0 * (1.0 - 0.50 * cq))
		_update_dull_bcs(h, phase)


static func apply_night(data) -> void:
	if data == null:
		return
	for h in data.horses:
		if h == null:
			continue
		h.hunger = maxf(0.0, float(h.hunger) - 10.0)
		h.phase_busy = false
		h.schooled_today = false
		h.fed_morning = false
		h.fed_evening = false
		h.picked_stall_today = false
		h.turned_out = false


static func feed(data, horse) -> String:
	if horse == null:
		return "No horse."
	var phase = data.clock.phase
	if int(phase) == Enums.Phase.AFTERNOON:
		return "Hay and grain are a morning and evening job."
	if int(phase) == Enums.Phase.MORNING:
		if horse.fed_morning:
			return "%s already had breakfast." % horse.name
		horse.hunger = minf(100.0, float(horse.hunger) + 40.0)
		horse.fed_morning = true
		return "Grain and hay. %s tucks in." % horse.name
	if horse.fed_evening:
		return "%s already had night hay." % horse.name
	horse.hunger = minf(100.0, float(horse.hunger) + 28.0)
	horse.fed_evening = true
	return "Night hay. %s settles." % horse.name


static func pick_stall(data, horse) -> String:
	if horse == null:
		return "No horse."
	if horse.picked_stall_today:
		return "That stall is already picked."
	var stall := stall_for(data, horse)
	if stall.is_empty():
		return "No stall assigned."
	stall["dirt"] = 8.0
	horse.picked_stall_today = true
	horse.cleanliness = minf(100.0, float(horse.cleanliness) + 6.0)
	return "Stall picked. Aisle looks respectable."


static func toggle_turnout(horse) -> String:
	if horse == null:
		return "No horse."
	horse.turned_out = not bool(horse.turned_out)
	if horse.turned_out:
		horse.happiness = minf(100.0, float(horse.happiness) + 6.0)
		horse.turnout_score = minf(100.0, float(horse.turnout_score) + 4.0)
		return "%s is out." % horse.name
	return "%s is in." % horse.name


static func groom(horse) -> String:
	if horse == null:
		return "No horse."
	if horse.cleanliness >= 92.0:
		return "%s already shines." % horse.name
	horse.cleanliness = minf(100.0, float(horse.cleanliness) + 18.0)
	horse.turnout_score = minf(100.0, float(horse.turnout_score) + 8.0)
	return "Curry, brush, pick feet. %s is presentable." % horse.name


static func is_dull(horse) -> bool:
	return horse != null and float(horse.hunger) < 30.0


static func band(value: float) -> String:
	if value < 30.0:
		return "limited"
	if value < 45.0:
		return "adequate"
	if value < 60.0:
		return "good"
	if value < 75.0:
		return "genuine"
	if value < 88.0:
		return "exceptional"
	return "the real thing"


static func hunger_line(horse) -> String:
	var h := float(horse.hunger)
	if h < 30.0:
		return "dull — needs a meal"
	if h < 50.0:
		return "getting light"
	if h < 75.0:
		return "fine"
	return "comfortably full"


static func dirt_line(data, horse) -> String:
	var stall := stall_for(data, horse)
	var d := float(stall.get("dirt", 0.0))
	if d > 60.0:
		return "stall is filthy"
	if d > 35.0:
		return "stall needs picking"
	return "stall is decent"


static func trainer_line(data, horse) -> String:
	if is_dull(horse):
		return "They're dull. Feed before you expect a good trip."
	var stall := stall_for(data, horse)
	if float(stall.get("dirt", 0.0)) > 60.0:
		return "You can smell that stall from the aisle."
	if float(horse.cleanliness) < 40.0:
		return "Mud to the elbows. Get a brush."
	if horse.turned_out:
		return "Happy to be out. Don't leave them out all night without a rug thought — later."
	return "Honest type. Keep the routine and they'll stay that way."


static func _hunger_for_phase(horse, phase) -> void:
	if int(phase) == Enums.Phase.MORNING and not bool(horse.fed_morning):
		horse.hunger = maxf(0.0, float(horse.hunger) - 38.0)
	elif int(phase) == Enums.Phase.EVENING and not bool(horse.fed_evening):
		horse.hunger = maxf(0.0, float(horse.hunger) - 22.0)
	elif int(phase) == Enums.Phase.AFTERNOON:
		horse.hunger = maxf(0.0, float(horse.hunger) - 6.0)


static func _energy_cap(horse) -> float:
	if is_dull(horse):
		return 50.0
	if float(horse.weight) < 4.0:
		return 60.0
	return 100.0


static func _update_dull_bcs(horse, phase) -> void:
	if int(phase) != Enums.Phase.MORNING:
		return
	if float(horse.hunger) < 30.0:
		horse.dull_mornings = int(horse.dull_mornings) + 1
		if int(horse.dull_mornings) >= 3:
			horse.weight = maxf(1.0, float(horse.weight) - 0.10)
	else:
		horse.dull_mornings = 0
