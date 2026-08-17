extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")
const Breeding := preload("res://src/horse/breeding_system.gd")


static func run() -> int:
	var fails := 0
	var gs: Node = Engine.get_main_loop().root.get_node("GameState")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 33
	gs.new_game(cfg)
	var mare = gs.data.horses[0]
	mare.sex = Enums.Sex.MARE
	var sire = gs.data.horses[0]
	if Breeding.can_breed(mare, sire) == "":
		push_error("breed: same horse should refuse")
		fails += 1
	var stallion = load("res://src/horse/horse_factory.gd").make_prospect(gs.sim_rng)
	stallion.sex = Enums.Sex.STALLION
	var why := Breeding.can_breed(mare, stallion)
	if why != "":
		push_error("breed: should allow mare x stallion (%s)" % why)
		fails += 1
	var msg := Breeding.cover(mare, stallion, 0)
	if not bool(mare.in_foal):
		push_error("breed: cover failed (%s)" % msg)
		fails += 1
	mare.foal_due_abs = 0
	var n0: int = gs.data.horses.size()
	var notes := Breeding.tick(gs.data, gs.sim_rng)
	if gs.data.horses.size() != n0 + 1:
		push_error("breed: foal not added (%s)" % ",".join(notes))
		fails += 1
	if fails == 0:
		print("test_breeding: ok")
	return fails
