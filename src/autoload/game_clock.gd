extends Node
## Phase calendar. Always reads/writes GameState.data — never a cached alias.

const Enums := preload("res://src/core/enums.gd")
const CareSystemScript := preload("res://src/care/care_system.gd")
const TrainingSystemScript := preload("res://src/training/training_system.gd")


func _gs() -> Node:
	return Engine.get_main_loop().root.get_node("GameState")


func _bus() -> Node:
	return Engine.get_main_loop().root.get_node("EventBus")


func advance_phase() -> void:
	var clock = _gs().data.clock
	_bus().phase_ended.emit(clock.phase)
	CareSystemScript.apply_phase_decay(_gs().data, clock.phase)
	if clock.phase == Enums.Phase.EVENING:
		_run_night_bundle()
		var season_changed: bool = clock.advance_to_next_morning()
		if season_changed:
			for h in _gs().data.horses:
				if h is Dictionary and h.has("age_months"):
					h["age_months"] = int(h["age_months"]) + 3
				elif h != null and "age_months" in h:
					h.age_months += 3
			_bus().season_started.emit(clock.season)
		_collect_board()
		_bus().day_started.emit(clock)
		_bus().phase_started.emit(Enums.Phase.MORNING)
	else:
		clock.phase = (int(clock.phase) + 1) as Enums.Phase
		_bus().phase_started.emit(clock.phase)
	var rng = _gs().sim_rng
	if rng:
		_gs().data.rng_call_count = rng.call_count
	_bus().clock_changed.emit()


func sleep_until_morning() -> void:
	## Advance to the *next* morning. A no-op-if-already-Morning loop
	## would leave pause-menu Sleep and the 112-day wrap test stuck on day 0.
	if _gs().data.clock.phase == Enums.Phase.MORNING:
		advance_phase()
	while _gs().data.clock.phase != Enums.Phase.MORNING:
		advance_phase()


func _collect_board() -> void:
	var econ = Engine.get_main_loop().root.get_node_or_null("Economy")
	if econ and econ.has_method("collect_board"):
		var msg: String = String(econ.collect_board())
		if msg.begins_with("Board checks"):
			_bus().toast.emit(msg)


func _run_night_bundle() -> void:
	for h in _gs().data.horses:
		TrainingSystemScript.rest(h)
	CareSystemScript.apply_night(_gs().data)
