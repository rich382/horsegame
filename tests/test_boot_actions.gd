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
		if boot.get_node_or_null("HUD/Care/Shop") == null:
			push_error("boot actions: Shop button missing")
			fails += 1
		if boot.get_node_or_null("HUD/Care/Office") == null:
			push_error("boot actions: Office button missing")
			fails += 1
		if boot.get_node_or_null("Office") == null:
			push_error("boot actions: Office panel missing")
			fails += 1
		if boot.get_node_or_null("Theater") == null:
			push_error("boot actions: Theater missing")
			fails += 1
		if boot.get_node_or_null("StringHorses") == null:
			push_error("boot actions: StringHorses missing")
			fails += 1
		if boot.get_node_or_null("HUD/Care/School") == null:
			push_error("boot actions: School button missing")
			fails += 1
		if boot.get_node_or_null("HUD/SchoolWork/Flat") == null:
			push_error("boot actions: Flat school button missing")
			fails += 1
		if boot.get_node_or_null("Shop") == null or boot.get_node_or_null("School") == null:
			push_error("boot actions: Shop/School panels missing")
			fails += 1
		if boot.get_node_or_null("Recap") == null:
			push_error("boot actions: Recap panel missing")
			fails += 1
		var school: Node = boot.get_node_or_null("School")
		if school and school.has_method("open"):
			school.open()
			if not bool(school.visible):
				push_error("boot actions: School.open did not show picker")
				fails += 1
			if school.get_node_or_null("Center/Card/Margin/VBox/Flat") == null:
				push_error("boot actions: school picker Flat missing")
				fails += 1
		if boot.has_method("_on_school_picked"):
			if gs.data.clock.phase != Enums.Phase.MORNING:
				push_error("boot actions: expected morning before school pick")
				fails += 1
			else:
				boot._on_school_picked(Enums.TrainingKind.FLAT)
				if gs.data.clock.phase != Enums.Phase.AFTERNOON:
					push_error("boot actions: morning school pick should become afternoon")
					fails += 1
				if gs.data.horses.size() > 0 and not bool(gs.data.horses[0].schooled_today):
					push_error("boot actions: school pick did not apply a session")
					fails += 1
		if boot.get_node_or_null("Camera3D") == null:
			push_error("boot actions: camera missing")
			fails += 1
		boot.queue_free()
	if fails == 0:
		print("test_boot_actions: ok")
	return fails
