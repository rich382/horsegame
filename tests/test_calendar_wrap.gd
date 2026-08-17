extends RefCounted

const Enums := preload("res://src/core/enums.gd")
const GameConfig := preload("res://src/core/game_config.gd")


static func run() -> int:
	var fails := 0
	var gs: Node = Engine.get_main_loop().root.get_node("GameState")
	var clock: Node = Engine.get_main_loop().root.get_node("GameClock")
	var cfg = GameConfig.new()
	cfg.use_os_seed = false
	cfg.debug_seed = 1
	gs.new_game(cfg)
	var start = gs.data.clock
	if start.year != 1 or start.season != Enums.Season.SPRING or start.week != 1:
		push_error("calendar wrap: bad new_game clock")
		fails += 1
	if start.weekday != Enums.Weekday.MON or start.phase != Enums.Phase.MORNING:
		push_error("calendar wrap: new_game is not Monday Morning")
		fails += 1
	if start.abs_day() != 0:
		push_error("calendar wrap: new_game abs_day=%d want 0" % start.abs_day())
		fails += 1

	for _i in 112:
		clock.sleep_until_morning()

	var c = gs.data.clock
	if c.year != 2:
		push_error("calendar wrap: year=%d want 2" % c.year)
		fails += 1
	if c.season != Enums.Season.SPRING:
		push_error("calendar wrap: season=%d want SPRING" % int(c.season))
		fails += 1
	if c.week != 1:
		push_error("calendar wrap: week=%d want 1" % c.week)
		fails += 1
	if c.weekday != Enums.Weekday.MON:
		push_error("calendar wrap: weekday=%d want MON" % int(c.weekday))
		fails += 1
	if c.phase != Enums.Phase.MORNING:
		push_error("calendar wrap: phase=%d want MORNING" % int(c.phase))
		fails += 1
	if c.abs_day() != 112:
		push_error("calendar wrap: abs_day=%d want 112" % c.abs_day())
		fails += 1
	if fails == 0:
		print("test_calendar_wrap: ok")
	return fails
