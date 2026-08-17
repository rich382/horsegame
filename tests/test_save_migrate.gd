extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")


static func run() -> int:
	var fails := 0
	var gs: Node = Engine.get_main_loop().root.get_node("GameState")
	var clock: Node = Engine.get_main_loop().root.get_node("GameClock")
	var saves: Node = Engine.get_main_loop().root.get_node("SaveService")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 42
	gs.new_game(cfg)
	clock.advance_phase() ## Monday Morning → Afternoon
	var saved_uid := String(gs.data.horses[0].uid)
	var saved_hunger := float(gs.data.horses[0].hunger)
	var saved_name := String(gs.data.horses[0].name)

	var err: Error = saves.save_slot(9)
	if err != OK:
		push_error("save migrate: save_slot failed %s" % error_string(err))
		fails += 1
		return fails

	clock.sleep_until_morning()
	if gs.data.clock.phase != Enums.Phase.MORNING:
		push_error("save migrate: sleep did not reach morning")
		fails += 1

	err = saves.load_slot(9)
	if err != OK:
		push_error("save migrate: load_slot failed %s" % error_string(err))
		fails += 1
		return fails

	var c = gs.data.clock
	if c.weekday != Enums.Weekday.MON or c.phase != Enums.Phase.AFTERNOON:
		push_error("save migrate: loaded clock weekday=%d phase=%d" % [int(c.weekday), int(c.phase)])
		fails += 1
	if gs.data.seed != 42:
		push_error("save migrate: seed=%d want 42" % gs.data.seed)
		fails += 1
	if gs.data.horses.is_empty() or not (gs.data.horses[0] is Resource):
		push_error("save migrate: horse did not round-trip as HorseState")
		fails += 1
	else:
		var loaded = gs.data.horses[0]
		if String(loaded.uid) != saved_uid or String(loaded.name) != saved_name:
			push_error("save migrate: horse identity lost uid=%s name=%s" % [loaded.uid, loaded.name])
			fails += 1
		if abs(float(loaded.hunger) - saved_hunger) > 0.01:
			push_error("save migrate: hunger=%s want %s" % [str(loaded.hunger), str(saved_hunger)])
			fails += 1

	var legacy := {"version": 0, "seed": 7}
	var migrated: Dictionary = saves.migrate(legacy)
	if int(migrated.get("version", -1)) != 1:
		push_error("save migrate: version not bumped")
		fails += 1
	if not migrated.has("clock") or not migrated.has("player"):
		push_error("save migrate: v0 missing defaults")
		fails += 1
	if fails == 0:
		print("test_save_migrate: ok")
	return fails
