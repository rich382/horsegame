extends Node
## Only writer of GameState.data.player.cash.

const Barn := preload("res://src/barn/barn_system.gd")
const Ashford := preload("res://src/show/ashford.gd")
const Circuit := preload("res://src/show/circuit.gd")
const HorseFactoryScript := preload("res://src/horse/horse_factory.gd")
const Breeding := preload("res://src/horse/breeding_system.gd")
const Quests := preload("res://src/quest/quest_system.gd")

const PROSPECT_COST := 3200
const HELP_WEEK := 90

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
const PLAYTEST_CASH := 999999


func unlimited() -> bool:
	var gs := get_node("/root/GameState")
	if gs.data == null:
		return false
	return bool(gs.data.farm.get("debug_unlimited_cash", false))


func grant_playtest_cash() -> String:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		return "No game."
	gs.data.farm["debug_unlimited_cash"] = true
	var bump: int = PLAYTEST_CASH - int(gs.data.player.cash)
	if bump > 0:
		post(&"debug", bump, "Playtest till")
	return "Playtest till is open. Buy whatever."


func can_afford(amount: int) -> bool:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		return false
	if unlimited():
		return true
	return int(gs.data.player.cash) + amount >= 0 if amount < 0 else true


func post(category: StringName, amount: int, note: String) -> bool:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		return false
	if amount < 0 and not unlimited() and int(gs.data.player.cash) + amount < 0:
		return false
	if unlimited() and amount < 0:
		gs.data.player.cash = PLAYTEST_CASH
	else:
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
	farm["footing_quality"] = 65
	if not post(&"shop", -FOOTING_COST, "Arena footing"):
		farm["footing_quality"] = 40
		return "Can't cover footing ($%d)." % FOOTING_COST
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
	farm["has_drag"] = true
	farm["training_efficiency"] = maxf(float(farm.get("training_efficiency", 0.15)), 0.20)
	if not post(&"shop", -DRAG_COST, "Arena drag"):
		farm["has_drag"] = false
		return "Can't cover a drag ($%d)." % DRAG_COST
	return "Drag's in the shed. Home school rides truer."


func buy_jumps() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if int(farm.get("jump_sets", 1)) >= 2:
		return "Plenty of poles out there."
	farm["jump_sets"] = 2
	if not post(&"shop", -JUMPS_COST, "Extra jump set"):
		farm["jump_sets"] = 1
		return "Can't cover jumps ($%d)." % JUMPS_COST
	return "Another set of standards. You can build a real line."


func buy_truck() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_truck", false)):
		return "Truck's already in the drive."
	farm["has_truck"] = true
	if not post(&"shop", -TRUCK_COST, "Used diesel"):
		farm["has_truck"] = false
		return "Can't cover the truck ($%d)." % TRUCK_COST
	return "Red truck is on the west drive, well past the barn. Zoom out and look left."


func buy_trailer() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_trailer", false)):
		return "Already have a two-horse."
	farm["has_trailer"] = true
	farm["trailer_capacity"] = 2
	if not post(&"shop", -TRAILER_COST, "Two-horse trailer"):
		farm["has_trailer"] = false
		farm["trailer_capacity"] = 0
		return "Can't cover the trailer ($%d)." % TRAILER_COST
	return "Two-horse is hitched on the west drive, clear of the arena."


func buy_barn_wing() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if int(farm.get("barn_tier", 1)) >= 2:
		return "The eight-stall is already up."
	farm["barn_tier"] = 2
	if not post(&"shop", -WING_COST, "Four-stall barn wing"):
		farm["barn_tier"] = 1
		return "Can't cover the wing ($%d)." % WING_COST
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
	farm["has_indoor"] = true
	farm["training_efficiency"] = maxf(float(farm.get("training_efficiency", 0.15)), 0.24)
	if not post(&"shop", -INDOOR_COST, "Covered arena"):
		farm["has_indoor"] = false
		return "Can't cover an indoor ($%d)." % INDOOR_COST
	return "Roof over the ring. You can school when it blows."


func take_boarder() -> String:
	var msg := Barn.take_boarder(get_node("/root/GameState").data)
	Quests.note_boarder(get_node("/root/GameState").data)
	return msg


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
	return enter_show("ashford")


func enter_show(show_id: String) -> Dictionary:
	var gs := get_node("/root/GameState")
	var horse = _selected()
	var show: Dictionary = Circuit.show_by_id(show_id)
	var gate: Dictionary = Circuit.enter_quote(gs.data, horse, show)
	if not bool(gate.get("ok", false)):
		return gate
	var need := int(gate.get("need", 0))
	var haul := int(gate.get("haul", 0))
	if not post(&"show", -need, "%s entry + haul" % show.get("name", "Show")):
		return {"ok": false, "msg": "Couldn't post entry.", "result": null}
	var out: Dictionary = Circuit.ride(gs.data, horse, gs.sim_rng, show)
	var prize := int(out.get("prize", 0))
	if prize > 0:
		post(&"prize", prize, "%s ribbon" % show.get("name", "Show"))
	gs.data.farm["loaded_for"] = ""
	var placing := int(out.get("placing", 0))
	var msg := "%s — placed %d. %s" % [
		show.get("class_label", "Class"),
		placing,
		("+$%d." % prize) if prize > 0 else "No check.",
	]
	if haul == 0:
		msg += " Already on the trailer."
	elif haul == Circuit.HAUL_OWN:
		msg += " You hauled yourself."
	else:
		msg += " Paid a shipper."
	out["ok"] = true
	out["msg"] = msg
	out["title"] = "%s · %s" % [show.get("name", "Show"), show.get("class_label", "")]
	Quests.note_ribbon(gs.data, String(show.get("id", "")), placing)
	return out


func pay_show_entry(show_id: String) -> Dictionary:
	var gs := get_node("/root/GameState")
	var horse = _selected()
	var show: Dictionary = Circuit.show_by_id(show_id)
	var gate: Dictionary = Circuit.enter_quote(gs.data, horse, show)
	if not bool(gate.get("ok", false)):
		return gate
	var need := int(gate.get("need", 0))
	if not post(&"show", -need, "%s entry + haul" % show.get("name", "Show")):
		return {"ok": false, "msg": "Couldn't post entry."}
	gs.data.farm["loaded_for"] = ""
	gate["show"] = show
	gate["horse"] = horse
	return gate


func pay_prize(show_name: String, prize: int, show_id: String, placing: int) -> void:
	if prize > 0:
		post(&"prize", prize, "%s ribbon" % show_name)
	var gs := get_node("/root/GameState")
	Quests.note_ribbon(gs.data, show_id, placing)


func set_dam() -> String:
	var h = _selected()
	if h == null:
		return "No horse."
	if int(h.sex) != 0: ## Enums.Sex.MARE
		return "Mark a mare as the dam."
	get_node("/root/GameState").data.farm["dam_uid"] = String(h.uid)
	return "%s is marked as the dam." % h.name


func breed_selected() -> String:
	var gs := get_node("/root/GameState")
	var sire = _selected()
	var dam_uid := String(gs.data.farm.get("dam_uid", ""))
	var dam = null
	for h in gs.data.horses:
		if String(h.uid) == dam_uid:
			dam = h
			break
	var why := Breeding.can_breed(dam, sire)
	if why != "":
		return why
	if not post(&"breed", -Breeding.STUD_FEE, "Cover"):
		return "Can't cover the stud fee ($%d)." % Breeding.STUD_FEE
	return Breeding.cover(dam, sire, gs.data.clock.abs_day())


func buy_prospect() -> String:
	var gs := get_node("/root/GameState")
	var free: Array = Barn.empty_stalls(gs.data.farm)
	if free.is_empty():
		return "No empty stall. Sell someone or build the wing."
	if not post(&"shop", -PROSPECT_COST, "Prospect horse"):
		return "Can't cover a prospect ($%d)." % PROSPECT_COST
	var h = HorseFactoryScript.make_prospect(gs.sim_rng)
	var stall: Dictionary = free[0]
	h.stall_id = StringName(String(stall.get("id", "stall_1")))
	stall["occupant_uid"] = h.uid
	gs.data.horses.append(h)
	gs.data.farm["selected_uid"] = String(h.uid)
	Quests.note_string(gs.data)
	return "%s is on the card. Green, cheap, yours." % h.name


func sell_selected() -> String:
	var gs := get_node("/root/GameState")
	if gs.data.horses.size() <= 1:
		return "You need to keep one."
	var h = _selected()
	if h == null:
		return "No horse."
	var price: int = 1800 + int(float(h.jumper_schooling) * 35.0) + int(h.records.size()) * 150
	if not post(&"sale", price, "Sold %s" % h.name):
		return "Sale failed."
	var sid := String(h.stall_id)
	for s in gs.data.farm.get("stalls", []):
		if String(s.get("id", "")) == sid:
			s["occupant_uid"] = ""
	gs.data.horses.erase(h)
	gs.data.farm["selected_uid"] = String(gs.data.horses[0].uid)
	return "Sold %s for $%d. Empty stall." % [h.name, price]


func hire_help() -> String:
	var farm: Dictionary = get_node("/root/GameState").data.farm
	if bool(farm.get("has_help", false)):
		return "You already have a working student."
	if not post(&"help", -HELP_WEEK, "Working student, first week"):
		return "Can't cover help ($%d/week)." % HELP_WEEK
	farm["has_help"] = true
	farm["help_paid_abs"] = get_node("/root/GameState").data.clock.abs_day()
	return "Working student starts tomorrow. They pick stalls. $%d a week." % HELP_WEEK


func pay_help() -> String:
	var gs := get_node("/root/GameState")
	var farm: Dictionary = gs.data.farm
	if not bool(farm.get("has_help", false)):
		return ""
	var abs_d: int = gs.data.clock.abs_day()
	if abs_d - int(farm.get("help_paid_abs", 0)) < 7:
		return ""
	if not post(&"help", -HELP_WEEK, "Working student"):
		farm["has_help"] = false
		return "Couldn't make payroll. They left."
	farm["help_paid_abs"] = abs_d
	return "Paid the working student $%d." % HELP_WEEK


func load_trailer(show_id: String) -> String:
	var gs := get_node("/root/GameState")
	var show: Dictionary = Circuit.show_by_id(show_id)
	var why := Circuit.load_block(gs.data, show)
	if why != "":
		return why
	var h = _selected()
	if h == null:
		return "No horse."
	h.energy = maxf(0.0, float(h.energy) - 10.0)
	h.phase_busy = true
	gs.data.farm["loaded_for"] = show_id
	return "%s is on the trailer for %s." % [h.name, show.get("name", "the show")]


func _selected():
	var gs := get_node("/root/GameState")
	if gs.has_method("selected_horse"):
		return gs.selected_horse()
	return _starter()


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
