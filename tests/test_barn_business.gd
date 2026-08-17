extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")
const Barn := preload("res://src/barn/barn_system.gd")
const Care := preload("res://src/care/care_system.gd")


static func run() -> int:
	var fails := 0
	var root: Window = Engine.get_main_loop().root
	var gs: Node = root.get_node("GameState")
	var econ: Node = root.get_node("Economy")
	var clock: Node = root.get_node("GameClock")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 21
	gs.new_game(cfg)
	var farm: Dictionary = gs.data.farm
	if int(farm.get("barn_tier", 0)) != 1:
		push_error("barn: starter tier want 1")
		fails += 1
	if farm.get("stalls", []).size() != 4:
		push_error("barn: starter stalls want 4")
		fails += 1

	var haul0: String = econ.do_haul("vet_run")
	if not haul0.contains("truck"):
		push_error("barn: haul without rig should refuse (%s)" % haul0)
		fails += 1

	gs.data.player.cash = 40000
	var truck: String = econ.buy_truck()
	var trailer: String = econ.buy_trailer()
	if not bool(farm.get("has_truck", false)) or not bool(farm.get("has_trailer", false)):
		push_error("barn: truck/trailer not owned (%s / %s)" % [truck, trailer])
		fails += 1
	var haul1: String = econ.do_haul("vet_run")
	if not haul1.contains("Hauled"):
		push_error("barn: haul with rig failed (%s)" % haul1)
		fails += 1
	var haul2: String = econ.do_haul("clinic_haul")
	if not haul2.contains("Already"):
		push_error("barn: second haul same day should refuse (%s)" % haul2)
		fails += 1

	var b1: String = econ.take_boarder()
	if farm.get("boarders", []).size() != 1:
		push_error("barn: take boarder failed (%s)" % b1)
		fails += 1
	var cash0 := int(gs.data.player.cash)
	var none: String = econ.collect_board()
	if int(gs.data.player.cash) != cash0:
		push_error("barn: board collected too soon (%s)" % none)
		fails += 1
	gs.data.farm["boarders"][0]["last_paid_abs"] = -10
	var paid: String = econ.collect_board()
	if int(gs.data.player.cash) != cash0 + Barn.BOARDER_RATE:
		push_error("barn: board pay cash=%d (%s)" % [int(gs.data.player.cash), paid])
		fails += 1

	var wing: String = econ.buy_barn_wing()
	if farm.get("stalls", []).size() != 8:
		push_error("barn: wing stalls=%d want 8 (%s)" % [farm.get("stalls", []).size(), wing])
		fails += 1

	var early: Dictionary = econ.enter_ashford()
	if bool(early.get("ok", false)):
		push_error("barn: Ashford on Monday should refuse")
		fails += 1
	while int(gs.data.clock.weekday) != Enums.Weekday.SAT:
		clock.sleep_until_morning()
	clock.advance_phase()
	if int(gs.data.clock.phase) != Enums.Phase.AFTERNOON:
		push_error("barn: expected Saturday afternoon")
		fails += 1
	gs.data.player.cash = 500
	var show: Dictionary = econ.enter_ashford()
	if not bool(show.get("ok", false)):
		push_error("barn: Ashford enter failed (%s)" % str(show.get("msg", "")))
		fails += 1
	elif int(show.get("placing", 0)) < 1:
		push_error("barn: Ashford placing missing")
		fails += 1

	gs.data.player.cash = 20000
	var n0: int = gs.data.horses.size()
	var bought: String = econ.buy_prospect()
	if gs.data.horses.size() != n0 + 1:
		push_error("barn: prospect buy failed (%s)" % bought)
		fails += 1
	var sold: String = econ.sell_selected()
	if gs.data.horses.size() != n0:
		push_error("barn: sell did not shrink string (%s)" % sold)
		fails += 1
	var keep: String = econ.sell_selected()
	if gs.data.horses.size() < 1 or not keep.contains("keep"):
		push_error("barn: should keep one horse (%s)" % keep)
		fails += 1
	var help: String = econ.hire_help()
	if not bool(gs.data.farm.get("has_help", false)):
		push_error("barn: hire help failed (%s)" % help)
		fails += 1
	var h = gs.data.horses[0]
	h.last_farrier_abs_day = -30
	h.hoof = 80.0
	Care.apply_night(gs.data)
	if float(h.hoof) >= 80.0:
		push_error("barn: overdue hoof should decay")
		fails += 1

	if fails == 0:
		print("test_barn_business: ok")
	return fails
