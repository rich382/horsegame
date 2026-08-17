extends Node
## Only writer of GameState.data.player.cash.

const HAY_COST := 40
const GRAIN_COST := 35
const FARRIER_COST := 150
const BOOTS_COST := 180
const MARTINGALE_COST := 95
const FOOTING_COST := 1200


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


func _starter():
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.horses.is_empty():
		return null
	return gs.data.horses[0]
