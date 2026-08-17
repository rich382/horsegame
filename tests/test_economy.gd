extends RefCounted

const GameConfig := preload("res://src/core/game_config.gd")


static func run() -> int:
	var fails := 0
	var root: Window = Engine.get_main_loop().root
	var gs: Node = root.get_node("GameState")
	var econ: Node = root.get_node("Economy")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 11
	gs.new_game(cfg)
	var start_cash := int(gs.data.player.cash)
	if start_cash != 10000:
		push_error("economy: start cash=%d want 10000" % start_cash)
		fails += 1
	if int(gs.data.farm.get("hay_days", 0)) != 14:
		push_error("economy: start hay_days want 14")
		fails += 1

	var msg: String = econ.buy_hay()
	if int(gs.data.player.cash) != start_cash - 40:
		push_error("economy: hay cash=%d want %d (%s)" % [int(gs.data.player.cash), start_cash - 40, msg])
		fails += 1
	if int(gs.data.farm.get("hay_days", 0)) != 21:
		push_error("economy: hay_days=%s want 21" % str(gs.data.farm.get("hay_days", 0)))
		fails += 1
	if gs.data.ledger.is_empty():
		push_error("economy: ledger empty after hay")
		fails += 1

	msg = econ.buy_grain()
	if int(gs.data.farm.get("grain_days", 0)) != 21:
		push_error("economy: grain_days=%s want 21 (%s)" % [str(gs.data.farm.get("grain_days", 0)), msg])
		fails += 1

	var h = gs.data.horses[0]
	msg = econ.buy_farrier(h)
	if not msg.contains("due"):
		push_error("economy: farrier should not be due yet (%s)" % msg)
		fails += 1
	h.last_farrier_abs_day = -20
	var cash_before := int(gs.data.player.cash)
	msg = econ.buy_farrier(h)
	if int(gs.data.player.cash) != cash_before - 150:
		push_error("economy: farrier cash (%s)" % msg)
		fails += 1
	if abs(float(h.hoof) - 90.0) > 0.01:
		push_error("economy: hoof=%s want 90" % str(h.hoof))
		fails += 1

	msg = econ.buy_boots()
	if String(h.tack.get("boots_uid", "")) != "t_boots":
		push_error("economy: boots not on horse (%s)" % msg)
		fails += 1
	var again: String = econ.buy_boots()
	if not again.contains("Already"):
		push_error("economy: second boots should refuse (%s)" % again)
		fails += 1

	msg = econ.buy_footing()
	if int(gs.data.farm.get("footing_quality", 0)) != 65:
		push_error("economy: footing=%s want 65 (%s)" % [str(gs.data.farm.get("footing_quality", 0)), msg])
		fails += 1
	again = econ.buy_footing()
	if not again.contains("already"):
		push_error("economy: second footing should refuse (%s)" % again)
		fails += 1

	gs.data.player.cash = 10
	var broke: String = econ.buy_hay()
	if int(gs.data.player.cash) != 10:
		push_error("economy: broke buy mutated cash")
		fails += 1
	if not broke.contains("Can't"):
		push_error("economy: broke hay should refuse (%s)" % broke)
		fails += 1

	var hay0 := int(gs.data.farm.get("hay_days", 0))
	var granted: String = econ.grant_playtest_cash()
	if not bool(gs.data.farm.get("debug_unlimited_cash", false)):
		push_error("economy: playtest till flag missing (%s)" % granted)
		fails += 1
	if int(gs.data.player.cash) != 999999:
		push_error("economy: playtest cash=%d want 999999" % int(gs.data.player.cash))
		fails += 1
	var rich: String = econ.buy_hay()
	if int(gs.data.farm.get("hay_days", 0)) != hay0 + 7:
		push_error("economy: playtest hay failed (%s)" % rich)
		fails += 1
	if int(gs.data.player.cash) != 999999:
		push_error("economy: playtest buy should not drain cash")
		fails += 1
	gs.new_game(cfg)
	if int(gs.data.player.cash) != 10000:
		push_error("economy: new_game should reset playtest cash")
		fails += 1
	if bool(gs.data.farm.get("debug_unlimited_cash", false)):
		push_error("economy: new_game should clear playtest till")
		fails += 1

	if fails == 0:
		print("test_economy: ok")
	return fails
