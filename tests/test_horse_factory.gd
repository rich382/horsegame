extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")
const HorseFactory := preload("res://src/horse/horse_factory.gd")


static func run() -> int:
	var fails := 0
	var gs: Node = Engine.get_main_loop().root.get_node("GameState")
	var clock: Node = Engine.get_main_loop().root.get_node("GameClock")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 9
	gs.new_game(cfg)
	if gs.data.horses.size() != 1:
		push_error("horse factory: expected one starter horse")
		fails += 1
		return fails
	var h = gs.data.horses[0]
	if abs(float(h.scope) - 56.0) > 0.01:
		push_error("horse factory: Bayberry scope=%s want 56" % str(h.scope))
		fails += 1
	if int(h.age_months) != 120:
		push_error("horse factory: age_months=%s want 120" % str(h.age_months))
		fails += 1
	HorseFactory.apply_player_identity(h, "  Maple  ", Enums.CoatColor.CHESTNUT)
	if h.name != "Maple" or h.coat != Enums.CoatColor.CHESTNUT:
		push_error("horse factory: identity apply failed name=%s coat=%s" % [h.name, str(h.coat)])
		fails += 1
	for _i in 112:
		clock.sleep_until_morning()
	if int(h.age_months) != 132:
		push_error("horse factory: after 112 sleeps age_months=%s want 132" % str(h.age_months))
		fails += 1
	var packed = load("res://assets/models/horse/horse_rigged.glb")
	if packed == null:
		push_error("horse factory: horse_rigged.glb failed to load")
		fails += 1
	else:
		var inst: Node = packed.instantiate()
		var ap := _find_anim(inst)
		if ap == null or not ap.has_animation("idle") or not ap.has_animation("walk"):
			push_error("horse factory: rig missing idle/walk")
			fails += 1
		inst.free()
	if fails == 0:
		print("test_horse_factory: ok")
	return fails


static func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_anim(c)
		if found:
			return found
	return null
