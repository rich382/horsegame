extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")


static func run() -> int:
	var fails := 0
	var root: Window = Engine.get_main_loop().root
	var gs: Node = root.get_node("GameState")
	var clock: Node = root.get_node("GameClock")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 3
	gs.new_game(cfg)
	if gs.data.clock.phase != Enums.Phase.MORNING:
		push_error("boot actions: expected Morning")
		fails += 1
	clock.advance_phase()
	if gs.data.clock.phase != Enums.Phase.AFTERNOON:
		push_error("boot actions: Next Phase did not reach Afternoon")
		fails += 1
	clock.advance_phase()
	if gs.data.clock.phase != Enums.Phase.EVENING:
		push_error("boot actions: Next Phase did not reach Evening")
		fails += 1
	clock.sleep_until_morning()
	if gs.data.clock.phase != Enums.Phase.MORNING or gs.data.clock.weekday != Enums.Weekday.TUE:
		push_error("boot actions: Sleep did not reach Tuesday Morning")
		fails += 1
	var packed: PackedScene = load("res://scenes/boot/boot.tscn")
	if packed == null:
		push_error("boot actions: boot.tscn failed to load")
		fails += 1
	else:
		var boot: Node = packed.instantiate()
		root.add_child(boot)
		if boot.get_node_or_null("HUD/Actions/NextPhase") == null:
			push_error("boot actions: Next Phase button missing")
			fails += 1
		if boot.get_node_or_null("Camera3D") == null:
			push_error("boot actions: camera missing")
			fails += 1
		boot.queue_free()
	if fails == 0:
		print("test_boot_actions: ok")
	return fails
