extends Node
## Only writer of GameState.data.player.cash.

const Barn := preload("res://src/barn/barn_system.gd")
const Ashford := preload("res://src/show/ashford.gd")

const HAY_COST := 40
const GRAIN_COST := 35
const FARRIER_COST := 150
const VET_COST := 200
const BOOTS_COST := 180
const MARTINGALE_COST := 95
const STANDING_COST := 70
const BELLS_COST := 55
const COOLER_COST := 90
const FOOTING_COST := 1200
const DRAG_COST := 620
const JUMPS_COST := 380
const TRUCK_COST := 8500
const TRAILER_COST := 4200
const WING_COST := 12000
const INDOOR_COST := 15000


func can_afford(amount: int) -> bool:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		return false
	return int(gs.data.player.cash) + amount >= 0 if amount < 0 else true


func post(category: StringName, amount: int, note: String) -> bool:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		return false
	if amount < 0 and int(gs.data.player.cash) + amount < 0:
		return false
	gs.data.player.cash = int(gs.data.player.cash) + amount
	var clock = gs.data.clock
	var entry := {
		"when": clock.to_dict() if clock else {},
		"category": String(category),
		"amount": amount,
		"note": note,
	}
	gs.data.ledger.append(entry)
	if gs.data.ledger.size() > 200:
		gs.data.ledger = gs.data.ledger.slice(gs.data.ledger.size() - 200)
	var bus := get_node("/root/EventBus")
	bus.cash_changed.emit(int(gs.data.player.cash), entry)
	bus.clock_changed.emit()
	return true


func buy_hay() -> String:
	if not post(&"shop", -HAY_COST, "Hay, 7 days"):
		return "Can't cover hay ($%d)." % HAY_COST
	var farm: Dictionary = get_node("/root/GameState").data.farm
	farm["hay_days"] = int(farm.get("hay_days", 0)) + 7
	return "Hay stacked. %d days in the loft." % int(farm["hay_days"])


func buy_grain() -> String:
	if not post(&"shop", -GRAIN_COST, "Grain, 7 days"):
		return "Can't cover grain ($%d)." % GRAIN_COST
	var farm: Dictionary = get_node("/root/GameState").data.farm
	farm["grain_days"] = int(farm.get("grain_days", 0)) + 7
	return "Grain in the bin. %d days." % int(farm["grain_days"])


func buy_farrier(horse) -> String:
	if horse == null:
		return "No horse."
	var gs := get_node("/root/GameState")
	var abs_d: int = gs.data.clock.abs_day()
	if abs_d - int(horse.last_farrier_abs_day) < 14:
		return "Feet aren't due yet."
	if not post(&"farrier", -FARRIER_COST, "Farrier"):
		return "Can't cover the farrier ($%d)." % FARRIER_COST
	horse.hoof = 90.0
	horse.last_farrier_abs_day = abs_d
	return "Reset and shod. Hooves feel good."


func buy_boots() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	var owned: Array = farm.get("tack_owned", [])
	for t in owned:
		if String(t.get("def_id", "")) == "open_front_boots":
			return "Already have open-fronts."
	if not post(&"shop", -BOOTS_COST, "Open-front boots"):
		return "Can't cover boots ($%d)." % BOOTS_COST
	owned.append({"uid": "t_boots", "def_id": "open_front_boots", "care_mod": 3})
	farm["tack_owned"] = owned
	var h = _starter()
	if h:
		h.tack["boots_uid"] = "t_boots"
		h.tack["care_mod"] = 3
	return "Open-fronts on the rack."


func buy_martingale() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	var owned: Array = farm.get("tack_owned", [])
	for t in owned:
		if String(t.get("def_id", "")) == "running_martingale":
			return "Already have a running martingale."
	if not post(&"shop", -MARTINGALE_COST, "Running martingale"):
		return "Can't cover the martingale ($%d)." % MARTINGALE_COST
	owned.append({"uid": "t_mart", "def_id": "running_martingale"})
	farm["tack_owned"] = owned
	return "Running martingale hung up."


func buy_footing() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if int(farm.get("footing_quality", 40)) >= 65:
		return "Footing is already upgraded."
	if not post(&"shop", -FOOTING_COST, "Arena footing"):
		return "Can't cover footing ($%d)." % FOOTING_COST
	farm["footing_quality"] = 65
	return "New fiber mix. Home arena rides better."


func buy(id: String) -> String:
	match id:
		"hay":
			return buy_hay()
		"grain":
			return buy_grain()
		"farrier":
			return buy_farrier(_starter())
		"vet":
			return buy_vet(_starter())
		"boots":
			return buy_boots()
		"martingale":
			return buy_martingale()
		"standing":
			return _buy_unique_tack("standing_martingale", STANDING_COST, "Standing martingale")
		"bells":
			return _buy_unique_tack("bell_boots", BELLS_COST, "Bell boots")
		"cooler":
			return _buy_unique_tack("cooler", COOLER_COST, "Cooler")
		"footing":
			return buy_footing()
		"drag":
			return buy_drag()
		"jumps":
			return buy_jumps()
		"truck":
			return buy_truck()
		"trailer":
			return buy_trailer()
		"wing":
			return buy_barn_wing()
		"indoor":
			return buy_indoor()
		_:
			return "Not in the catalog."


func buy_vet(horse) -> String:
	if horse == null:
		return "No horse."
	if not post(&"vet", -VET_COST, "Vet exam"):
		return "Can't cover the vet ($%d)." % VET_COST
	horse.soundness = minf(100.0, float(horse.soundness) + 4.0)
	return "Looked over. Nothing dramatic."


func buy_drag() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_drag", false)):
		return "Already have a drag."
	if not post(&"shop", -DRAG_COST, "Arena drag"):
		return "Can't cover a drag ($%d)." % DRAG_COST
	farm["has_drag"] = true
	farm["training_efficiency"] = maxf(float(farm.get("training_efficiency", 0.15)), 0.20)
	return "Drag's in the shed. Home school rides truer."


func buy_jumps() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if int(farm.get("jump_sets", 1)) >= 2:
		return "Plenty of poles out there."
	if not post(&"shop", -JUMPS_COST, "Extra jump set"):
		return "Can't cover jumps ($%d)." % JUMPS_COST
	farm["jump_sets"] = 2
	return "Another set of standards. You can build a real line."


func buy_truck() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_truck", false)):
		return "Truck's already in the drive."
	if not post(&"shop", -TRUCK_COST, "Used diesel"):
		return "Can't cover the truck ($%d)." % TRUCK_COST
	farm["has_truck"] = true
	return "Keys on the hook. Needs a trailer."


func buy_trailer() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_trailer", false)):
		return "Already have a two-horse."
	if not post(&"shop", -TRAILER_COST, "Two-horse trailer"):
		return "Can't cover the trailer ($%d)." % TRAILER_COST
	farm["has_trailer"] = true
	farm["trailer_capacity"] = 2
	return "Two-horse in the yard. Hitch it and go to work."


func buy_barn_wing() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if int(farm.get("barn_tier", 1)) >= 2:
		return "The eight-stall is already up."
	if not post(&"shop", -WING_COST, "Four-stall barn wing"):
		return "Can't cover the wing ($%d)." % WING_COST
	farm["barn_tier"] = 2
	var stalls: Array = farm.get("stalls", [])
	var start := stalls.size()
	for i in 4:
		stalls.append({"id": "stall_%d" % (start + i), "dirt": 0.0, "occupant_uid": "", "boarder": ""})
	farm["stalls"] = stalls
	farm["care_quality"] = maxf(float(farm.get("care_quality", 0.50)), 0.58)
	return "Four more stalls. That's a real aisle."


func buy_indoor() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_indoor", false)):
		return "Indoor's already framed."
	if not post(&"shop", -INDOOR_COST, "Covered arena"):
		return "Can't cover an indoor ($%d)." % INDOOR_COST
	farm["has_indoor"] = true
	farm["training_efficiency"] = maxf(float(farm.get("training_efficiency", 0.15)), 0.24)
	return "Roof over the ring. You can school when it blows."


func take_boarder() -> String:
	return Barn.take_boarder(get_node("/root/GameState").data)


func collect_board() -> String:
	var gs := get_node("/root/GameState")
	var abs_d: int = gs.data.clock.abs_day()
	var due: int = Barn.due_board(gs.data.farm, abs_d)
	if due <= 0:
		return "No board due."
	if not post(&"board", due, "Weekly board"):
		return "Board post failed."
	Barn.mark_board_paid(gs.data.farm, abs_d)
	return "Board checks in. +$%d." % due


func do_haul(job_id: String) -> String:
	var gs := get_node("/root/GameState")
	var why := Barn.haul_blocked(gs.data)
	if why != "":
		return why
	var job: Dictionary = Barn.job_by_id(job_id)
	if job.is_empty():
		return "That job fell through."
	var pay := int(job.get("pay", 0))
	if not post(&"haul", pay, String(job.get("label", "Haul"))):
		return "Haul post failed."
	gs.data.farm["last_haul_abs_day"] = gs.data.clock.abs_day()
	return "Hauled. $%d on the books. %s." % [pay, job.get("label", "")]


func enter_ashford() -> Dictionary:
	var gs := get_node("/root/GameState")
	var horse = _starter()
	var gate: Dictionary = Ashford.enter(gs.data, horse, gs.sim_rng)
	if not bool(gate.get("ok", false)):
		return gate
	var need := int(gate.get("need", 0))
	var haul := int(gate.get("haul", 0))
	if not post(&"show", -need, "Ashford entry + haul"):
		return {"ok": false, "msg": "Couldn't post entry.", "result": null}
	var out: Dictionary = Ashford.ride(gs.data, horse, gs.sim_rng)
	var prize := int(out.get("prize", 0))
	if prize > 0:
		post(&"prize", prize, "Ashford ribbon")
	var placing := int(out.get("placing", 0))
	var msg := "Ashford 0.80 m — %s. %s" % [
		("placed %d" % placing) if placing > 0 else "no ribbon",
		("+$%d." % prize) if prize > 0 else "No check.",
	]
	if haul == Ashford.HAUL_OWN:
		msg += " You hauled yourself."
	else:
		msg += " Paid a shipper."
	out["ok"] = true
	out["msg"] = msg
	return out


func _buy_unique_tack(def_id: String, cost: int, label: String) -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	var owned: Array = farm.get("tack_owned", [])
	for t in owned:
		if String(t.get("def_id", "")) == def_id:
			return "Already have %s." % label.to_lower()
	if not post(&"shop", -cost, label):
		return "Can't cover %s ($%d)." % [label.to_lower(), cost]
	owned.append({"uid": "t_%s" % def_id, "def_id": def_id})
	farm["tack_owned"] = owned
	return "%s on the rack." % label


func _starter():
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.horses.is_empty():
		return null
	return gs.data.horses[0]
