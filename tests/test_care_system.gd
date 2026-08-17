extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")
const Care := preload("res://src/care/care_system.gd")


static func run() -> int:
	var fails := 0
	var gs: Node = Engine.get_main_loop().root.get_node("GameState")
	var clock: Node = Engine.get_main_loop().root.get_node("GameClock")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 4
	gs.new_game(cfg)
	var h = gs.data.horses[0]
	if int(gs.data.farm.get("hay_days", 0)) != 14 or int(gs.data.farm.get("grain_days", 0)) != 14:
		push_error("care: starter loft hay=%s grain=%s want 14/14" % [
			str(gs.data.farm.get("hay_days", 0)),
			str(gs.data.farm.get("grain_days", 0)),
		])
		fails += 1
	if abs(float(h.hunger) - 85.0) > 0.01:
		push_error("care: start hunger=%s want 85" % str(h.hunger))
		fails += 1
	clock.advance_phase() ## skip Mon morning
	if abs(float(h.hunger) - 47.0) > 0.01:
		push_error("care: after skip AM hunger=%s want 47" % str(h.hunger))
		fails += 1
	clock.advance_phase() ## afternoon
	if abs(float(h.hunger) - 41.0) > 0.01:
		push_error("care: after afternoon hunger=%s want 41" % str(h.hunger))
		fails += 1
	var hay_before := int(gs.data.farm.get("hay_days", 0))
	var msg := Care.feed(gs.data, h)
	if int(gs.data.farm.get("hay_days", 0)) != hay_before - 1:
		push_error("care: evening hay did not decrement")
		fails += 1
	if abs(float(h.hunger) - 69.0) > 0.01:
		push_error("care: after evening feed hunger=%s want 69 (%s)" % [str(h.hunger), msg])
		fails += 1
	clock.advance_phase() ## evening + night
	if abs(float(h.hunger) - 59.0) > 0.01:
		push_error("care: after night hunger=%s want 59" % str(h.hunger))
		fails += 1
	if gs.data.clock.phase != Enums.Phase.MORNING:
		push_error("care: expected Tuesday morning")
		fails += 1
	clock.advance_phase() ## skip Tue morning
	if abs(float(h.hunger) - 21.0) > 0.01:
		push_error("care: dull hunger=%s want 21" % str(h.hunger))
		fails += 1
	if not Care.is_dull(h):
		push_error("care: expected dull after two skipped mornings")
		fails += 1
	if fails == 0:
		print("test_care_system: ok")
	return fails
