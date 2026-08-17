extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")
const Training := preload("res://src/training/training_system.gd")


static func run() -> int:
	var fails := 0
	var root: Window = Engine.get_main_loop().root
	var gs: Node = root.get_node("GameState")
	var clock: Node = root.get_node("GameClock")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 8
	gs.new_game(cfg)
	var h = gs.data.horses[0]
	var morning := Training.apply_session(h, Enums.TrainingKind.FLAT, gs.data)
	if not morning.contains("afternoon"):
		push_error("training: morning should refuse (%s)" % morning)
		fails += 1
	if bool(h.schooled_today):
		push_error("training: morning refuse set schooled_today")
		fails += 1

	clock.advance_phase()
	if int(gs.data.clock.phase) != Enums.Phase.AFTERNOON:
		push_error("training: expected afternoon")
		fails += 1
	var energy0 := float(h.energy)
	var flat0 := float(h.flatwork)
	var ok := Training.apply_session(h, Enums.TrainingKind.FLAT, gs.data)
	if not bool(h.schooled_today):
		push_error("training: flat did not set schooled_today (%s)" % ok)
		fails += 1
	if float(h.energy) >= energy0:
		push_error("training: energy did not drop")
		fails += 1
	if float(h.flatwork) <= flat0:
		push_error("training: flatwork did not rise")
		fails += 1
	if not bool(h.at_arena):
		push_error("training: school should put the horse in the arena")
		fails += 1

	var twice := Training.apply_session(h, Enums.TrainingKind.POLES, gs.data)
	if not twice.contains("already"):
		push_error("training: second school should refuse (%s)" % twice)
		fails += 1

	h.schooled_today = false
	h.energy = 20.0
	var tired := Training.apply_session(h, Enums.TrainingKind.POLES, gs.data)
	if not tired.contains("tired"):
		push_error("training: low energy should refuse (%s)" % tired)
		fails += 1

	h.energy = 80.0
	h.soundness = 40.0
	var lame := Training.apply_session(h, Enums.TrainingKind.GYMNASTIC, gs.data)
	if not lame.contains("sound"):
		push_error("training: low soundness should refuse (%s)" % lame)
		fails += 1

	h.soundness = 88.0
	var gym0 := float(h.gymnastics)
	var jump0 := float(h.jumper_schooling)
	var gym := Training.apply_session(h, Enums.TrainingKind.GYMNASTIC, gs.data)
	if float(h.jumper_schooling) <= jump0 or float(h.gymnastics) <= gym0:
		push_error("training: gymnastic skills did not rise (%s)" % gym)
		fails += 1

	if fails == 0:
		print("test_training_system: ok")
	return fails
