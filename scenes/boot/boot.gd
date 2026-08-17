extends Node3D
## Playable boot yard: orbit camera, visible clock, on-screen actions.
## Esc is eaten by the Godot editor (stops Play). Use on-screen buttons or P.

const Care := preload("res://src/care/care_system.gd")
const Training := preload("res://src/training/training_system.gd")
const ShowResolver := preload("res://src/show/show_resolver.gd")
const CourseDefScript := preload("res://src/show/course_def.gd")
const ClassDefScript := preload("res://src/show/class_def.gd")
const Circuit := preload("res://src/show/circuit.gd")
const JumperJudge := preload("res://src/show/jumper_judge.gd")
const HunterJudge := preload("res://src/show/hunter_judge.gd")
const Quests := preload("res://src/quest/quest_system.gd")
const STALL_POS := Vector3(-8.2, 0.0, -4.0)
const PADDOCK_POS := Vector3(-10.5, 0.0, 3.6)
const ARENA_POS := Vector3(6.5, 0.0, 2.0)
const ARENA_HORSE := Vector3(5.4, 0.0, 1.6)
const SHOP_POS := Vector3(-6.6, 0.0, -3.4)
const Enums := preload("res://src/core/enums.gd")

@onready var _pause: CanvasLayer = $PauseMenu
@onready var _clock_label: Label = $HUD/Clock
@onready var _toast_label: Label = $HUD/Toast
@onready var _status_label: Label = $HUD/Status
@onready var _yard: Node3D = $Yard
@onready var _horse: Node3D = $HorsePresenter
@onready var _new_game: CanvasLayer = $NewGame
@onready var _sheet = $HUD/HorseSheet
@onready var _cam: Camera3D = $Camera3D
@onready var _player: Node3D = $PlayerAvatar
@onready var _shop: CanvasLayer = $Shop
@onready var _office: CanvasLayer = $Office
@onready var _school: CanvasLayer = $School
@onready var _school_work: HBoxContainer = $HUD/SchoolWork
@onready var _recap: CanvasLayer = $Recap
@onready var _theater: CanvasLayer = $Theater
@onready var _quest_label: Label = $HUD/Quest
@onready var _string_root: Node3D = $StringHorses

var _session := false
var _pending_recap = null
var _choice := 0
var _got_choice := false
var _skip_show := false


func _ready() -> void:
	if _yard.has_method("build"):
		var farm: Dictionary = {}
		var gs0 := get_node_or_null("/root/GameState")
		if gs0 and gs0.data:
			farm = gs0.data.farm
		_yard.build(farm)
	_spawn_horse()
	var bus := get_node("/root/EventBus")
	if not bus.toast.is_connected(_on_toast):
		bus.toast.connect(_on_toast)
	if not bus.clock_changed.is_connected(_refresh_clock):
		bus.clock_changed.connect(_refresh_clock)
	_new_game.confirmed.connect(_on_identity)
	_new_game.coat_previewed.connect(_on_coat_preview)
	_school.picked.connect(_on_school_picked)
	if _office and _office.has_signal("ashford_done"):
		_office.ashford_done.connect(_on_ashford_done)
	if _office and _office.has_signal("watch_show"):
		_office.watch_show.connect(_on_watch_show)
	if _theater:
		_theater.decided.connect(_on_theater_decided)
		_theater.skipped.connect(_on_theater_skip)
	if _school.has_signal("closed"):
		_school.closed.connect(_hide_school_choices)
	if _school_work:
		_school_work.visible = false
	if _cam.has_signal("yard_clicked"):
		_cam.yard_clicked.connect(_on_yard_clicked)
	var prev_b := get_node_or_null("HUD/HorseSwitch/Prev")
	var next_b := get_node_or_null("HUD/HorseSwitch/Next")
	if prev_b and not prev_b.pressed.is_connected(_on_prev_horse):
		prev_b.pressed.connect(_on_prev_horse)
	if next_b and not next_b.pressed.is_connected(_on_next_horse):
		next_b.pressed.connect(_on_next_horse)
	_refresh_clock()
	_on_toast("Name your horse. Feed, school in the afternoon, shop when the loft runs low.")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_N:
			_on_next_phase()
			get_viewport().set_input_as_handled()
		KEY_M:
			_on_sleep()
			get_viewport().set_input_as_handled()
		KEY_F5:
			_on_save()
			get_viewport().set_input_as_handled()
		KEY_BRACKETLEFT, KEY_COMMA:
			_on_prev_horse()
			get_viewport().set_input_as_handled()
		KEY_BRACKETRIGHT, KEY_PERIOD:
			_on_next_horse()
			get_viewport().set_input_as_handled()


func _on_next_phase() -> void:
	get_node("/root/GameClock").advance_phase()
	_on_toast("Advanced one phase.")


func _on_sleep() -> void:
	get_node("/root/GameClock").sleep_until_morning()
	get_node("/root/SaveService").autosave()
	_on_toast("Slept until morning. Autosaved.")


func _on_save() -> void:
	var err: Error = get_node("/root/SaveService").save_slot(1)
	if err == OK:
		_on_toast("Saved to slot 1.")
		get_node("/root/EventBus").toast.emit("Saved.")
	else:
		_on_toast("Save failed: %s" % error_string(err))


func _on_pause_pressed() -> void:
	_pause.toggle()


func _on_toast(text: String) -> void:
	_toast_label.text = text


func _refresh_clock() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.clock == null:
		_clock_label.text = ""
		_status_label.text = ""
		return
	var clock = gs.data.clock
	_clock_label.text = clock.hud_text()
	var horse_name := "—"
	var sel = _horse_state()
	if sel:
		horse_name = String(sel.name)
	var name_l := get_node_or_null("HUD/HorseSwitch/Name")
	if name_l:
		name_l.text = horse_name
	var farm: Dictionary = gs.data.farm
	_status_label.text = "%s   ·   $%d   ·   Hay %dd   ·   Grain %dd   ·   Board %d" % [
		horse_name,
		int(gs.data.player.cash),
		int(farm.get("hay_days", 0)),
		int(farm.get("grain_days", 0)),
		farm.get("boarders", []).size(),
	]
	if _quest_label:
		_quest_label.text = Quests.hud_line(gs.data)
	_refresh_sheet()
	_place_horse()
	_sync_string()
	if _yard.has_method("build"):
		_yard.build(farm)


func _spawn_horse() -> void:
	var gs := get_node("/root/GameState")
	var horse = null
	if gs.data and gs.data.horses.size() > 0:
		horse = gs.data.horses[0]
	if _horse.has_method("setup"):
		_horse.setup(horse)
	_place_horse()


func _on_coat_preview(coat: int) -> void:
	if _horse.has_method("apply_coat"):
		_horse.apply_coat(coat)


func _on_identity(horse_name: String, coat: int) -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.horses.is_empty():
		return
	var HorseFactoryScript = load("res://src/horse/horse_factory.gd")
	HorseFactoryScript.apply_player_identity(gs.data.horses[0], horse_name, coat)
	if _horse.has_method("setup"):
		_horse.setup(gs.data.horses[0])
	_refresh_clock()
	_on_toast("%s is on the farm. Start with feed." % gs.data.horses[0].name)


func _horse_state():
	var gs := get_node("/root/GameState")
	if gs.has_method("selected_horse"):
		return gs.selected_horse()
	if gs.data == null or gs.data.horses.is_empty():
		return null
	return gs.data.horses[0]


func _on_next_horse() -> void:
	_cycle_horse(1)


func _on_prev_horse() -> void:
	_cycle_horse(-1)


func _cycle_horse(step: int) -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.horses.size() < 2:
		_on_toast("Only one on the card. Buy a prospect in the Office.")
		return
	if gs.has_method("select_next"):
		gs.select_next(step)
	var h = _horse_state()
	if h and _horse.has_method("setup"):
		_horse.setup(h)
	_refresh_clock()
	if h:
		_on_toast("Working %s." % h.name)
		var name_l := get_node_or_null("HUD/HorseSwitch/Name")
		if name_l:
			name_l.text = String(h.name)


func _refresh_sheet() -> void:
	if _sheet and _sheet.has_method("refresh"):
		_sheet.refresh(get_node("/root/GameState").data, _horse_state())


func _place_horse() -> void:
	var h = _horse_state()
	if h == null:
		return
	if _horse.has_method("is_busy") and _horse.is_busy():
		return
	if bool(h.at_arena):
		_horse.position = ARENA_HORSE
		_horse.rotation.y = 0.0
	elif bool(h.turned_out):
		_horse.position = PADDOCK_POS + Vector3(float(_horse_index()) * 1.6, 0, 0)
		_horse.rotation.y = -0.4
	else:
		_horse.position = _stall_pos(h)
		_horse.rotation.y = 0.2


func _stall_pos(h) -> Vector3:
	var n := 0
	var sid := String(h.stall_id) if h else "stall_0"
	if sid.begins_with("stall_"):
		n = int(sid.substr(6))
	return Vector3(-8.2 + float(n % 4) * 1.8, 0.0, -4.0 - float(int(n / 4)) * 2.4)


func _horse_index() -> int:
	var gs := get_node("/root/GameState")
	var cur = _horse_state()
	if gs.data == null:
		return 0
	for i in gs.data.horses.size():
		if gs.data.horses[i] == cur:
			return i
	return 0


func _on_feed() -> void:
	_send_to_chore(_beside_horse(), func() -> void:
		var gs := get_node("/root/GameState")
		var msg := Care.feed(gs.data, _horse_state())
		_on_toast(msg)
		if "tucks" in msg:
			Quests.note_feed(gs.data, _horse_state())
		_refresh_clock()
	)


func _on_feed_all() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null:
		return
	var last := ""
	for h in gs.data.horses:
		last = Care.feed(gs.data, h)
	_on_toast("Fed the string. %s" % last)
	_refresh_clock()


func _on_pick() -> void:
	var dest := _stall_pos(_horse_state()) + Vector3(1.4, 0, 0.8)
	_send_to_chore(dest, func() -> void:
		var gs := get_node("/root/GameState")
		_on_toast(Care.pick_stall(gs.data, _horse_state()))
		_refresh_clock()
	)


func _on_turnout() -> void:
	_send_to_chore(_beside_horse(), func() -> void:
		_on_toast(Care.toggle_turnout(_horse_state()))
		_refresh_clock()
	)


func _on_groom() -> void:
	_send_to_chore(_beside_horse(), func() -> void:
		_on_toast(Care.groom(_horse_state()))
		_refresh_clock()
	)


func _on_shop() -> void:
	_walk_then(SHOP_POS, func() -> void:
		_shop.open()
	)


func _on_office() -> void:
	_walk_then(SHOP_POS, func() -> void:
		_office.open()
	)


func _on_ashford_done(payload: Dictionary) -> void:
	if _recap and _recap.has_method("open_result"):
		_recap.open_result(payload.get("result", null), String(payload.get("title", "Show")))
	var h = _horse_state()
	if h and _horse.has_method("setup"):
		_horse.setup(h)
	_refresh_clock()


func _on_school() -> void:
	if _session:
		_on_toast("Still in the ring.")
		return
	var h = _horse_state()
	if h and bool(h.schooled_today):
		_on_toast("%s already worked today." % h.name)
		return
	_show_school_choices()
	_on_toast("Pick a trip — Flat, Poles, or Gymnastic.")


func _show_school_choices() -> void:
	if _school_work:
		_school_work.visible = true
	_school.open()


func _hide_school_choices() -> void:
	if _school_work:
		_school_work.visible = false
	if _school and _school.visible:
		_school.visible = false


func _on_flat_school() -> void:
	_on_school_picked(Enums.TrainingKind.FLAT)


func _on_poles_school() -> void:
	_on_school_picked(Enums.TrainingKind.POLES)


func _on_gym_school() -> void:
	_on_school_picked(Enums.TrainingKind.GYMNASTIC)


func _on_school_picked(kind: int) -> void:
	if _session:
		_on_toast("Still in the ring.")
		return
	var gs := get_node("/root/GameState")
	if gs.data and gs.data.clock and int(gs.data.clock.phase) == Enums.Phase.MORNING:
		get_node("/root/GameClock").advance_phase()
		_on_toast("Afternoon. Going to the ring.")
	var why := Training.block_reason(_horse_state(), gs.data)
	if why != "":
		_on_toast(why)
		if _school:
			_school.open()
		if _school_work:
			_school_work.visible = true
		return
	_hide_school_choices()
	_pending_recap = null
	if kind == Enums.TrainingKind.GYMNASTIC:
		_pending_recap = _resolve_home_gym(gs)
	var msg := Training.apply_session(_horse_state(), kind, gs.data)
	if _pending_recap:
		msg = _gym_toast(_pending_recap, _horse_state())
	_on_toast(msg)
	_refresh_sheet()
	_session = true
	_run_school_path(_school_steps(kind), 0, func() -> void:
		_session = false
		_refresh_clock()
		if _pending_recap and _recap and _recap.has_method("open_result"):
			_recap.open_result(_pending_recap)
		_pending_recap = null
	)


func _resolve_home_gym(gs):
	if gs == null or gs.sim_rng == null:
		return null
	var rider := 35.0
	if gs.data and gs.data.player:
		rider = float(gs.data.player.rider_skill)
	var footing := 40.0
	if gs.data:
		footing = float(gs.data.farm.get("footing_quality", 40))
	return ShowResolver.resolve_trip(
		_horse_state(),
		rider,
		CourseDefScript.home_gym_080(),
		ClassDefScript.home_gym(),
		[],
		footing,
		gs.sim_rng
	)


func _gym_toast(result, horse) -> String:
	var name := String(horse.name) if horse else "They"
	if result == null:
		return "Worked gymnastic."
	if bool(result.eliminated):
		return "%s had a stop they couldn't get past." % name
	if int(result.faults) == 0:
		return "Clean gymnastic. %s stayed in front of you." % name
	return "Gymnastic: %d faults. Check the recap." % int(result.faults)


func _school_steps(kind: int) -> Array:
	var c := ARENA_POS
	if kind == Enums.TrainingKind.GYMNASTIC:
		return [
			{"pos": Vector3(6.2, 0.0, 1.4)},
			{"pos": Vector3(6.2, 0.0, -4.0), "jump": true},
			{"pos": Vector3(7.6, 0.0, 3.2)},
			{"pos": Vector3(7.6, 0.0, 8.4), "jump": true},
			{"pos": ARENA_HORSE},
		]
	if kind == Enums.TrainingKind.POLES:
		return [
			{"pos": c + Vector3(-4.0, 0.0, -5.5)},
			{"pos": c + Vector3(-4.0, 0.0, 5.5)},
			{"pos": c + Vector3(3.2, 0.0, 5.5)},
			{"pos": ARENA_HORSE},
		]
	return [
		{"pos": c + Vector3(-3.6, 0.0, -5.0)},
		{"pos": c + Vector3(3.6, 0.0, -5.0)},
		{"pos": c + Vector3(3.6, 0.0, 5.0)},
		{"pos": c + Vector3(-3.6, 0.0, 5.0)},
		{"pos": ARENA_HORSE},
	]


func _run_school_path(steps: Array, i: int, done: Callable) -> void:
	if i >= steps.size():
		done.call()
		return
	var step: Dictionary = steps[i]
	var dest: Vector3 = step["pos"]
	var next := func() -> void:
		_run_school_path(steps, i + 1, done)
	var rider := dest + Vector3(1.7, 0.0, 0.35)
	if _player and _player.has_method("walk_to"):
		_player.walk_to(rider)
	if bool(step.get("jump", false)) and _horse.has_method("jump_to"):
		if not _horse.jump_to(dest, next):
			next.call()
		return
	if _horse.has_method("walk_to"):
		if _horse.walk_to(dest, next):
			return
	_horse.position = dest
	next.call()


func _beside_horse() -> Vector3:
	return _horse.global_position + Vector3(1.3, 0, 0.4)


func _walk_then(dest: Vector3, done: Callable) -> void:
	if _session:
		_on_toast("Still in the ring.")
		return
	if _player == null or not _player.has_method("walk_to"):
		done.call()
		return
	if _player.is_busy():
		_on_toast("Still working.")
		return
	if not _player.walk_to(dest, done):
		_on_toast("Still walking.")


func _send_to_chore(dest: Vector3, done: Callable) -> void:
	if _session:
		_on_toast("Still in the ring.")
		return
	if _player == null or not _player.has_method("walk_and_do"):
		done.call()
		return
	if _player.is_busy():
		_on_toast("Still working.")
		return
	if _horse.has_method("is_busy") and _horse.is_busy():
		_on_toast("Horse is still moving.")
		return
	var clip := ""
	if _player.has_method("pick_action_clip"):
		clip = String(_player.pick_action_clip())
	if not _player.walk_and_do(dest, clip, done):
		_on_toast("Still walking.")


func _on_yard_clicked(screen_pos: Vector2) -> void:
	if _session:
		return
	var from := _cam.project_ray_origin(screen_pos)
	var to := from + _cam.project_ray_normal(screen_pos) * 80.0
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var n: Node = hit.get("collider")
	if n and _horse.is_ancestor_of(n):
		get_node("/root/EventBus").horse_selected.emit(String(_horse_state().uid) if _horse_state() else "")
		_refresh_sheet()
		_on_toast("That's %s." % _horse_state().name)
		if _player and _player.has_method("walk_to"):
			_player.walk_to(_beside_horse())
		return
	var at: Vector3 = hit.get("position", Vector3.ZERO)
	if _player and _player.has_method("walk_to"):
		_player.walk_to(at)


func _sync_string() -> void:
	if _string_root == null:
		return
	if _horse.has_method("is_busy") and _horse.is_busy():
		return
	for c in _string_root.get_children():
		c.queue_free()
	var gs := get_node("/root/GameState")
	if gs.data == null:
		return
	var packed := load("res://scenes/horse/horse_presenter.tscn")
	if packed == null:
		return
	var sel = _horse_state()
	for h in gs.data.horses:
		if h == null or h == sel:
			continue
		var n: Node3D = packed.instantiate()
		_string_root.add_child(n)
		if n.has_method("setup"):
			n.setup(h)
		if bool(h.turned_out):
			n.position = PADDOCK_POS + Vector3(1.8, 0, 1.2)
		else:
			n.position = _stall_pos(h)


func _on_theater_decided(kind: int) -> void:
	_choice = kind
	_got_choice = true


func _on_theater_skip() -> void:
	_skip_show = true
	_choice = Enums.Approach.STAY
	_got_choice = true


func _on_watch_show(show_id: String) -> void:
	if _session:
		_on_toast("Still in the ring.")
		return
	_run_watch_show(show_id)


func _run_watch_show(show_id: String) -> void:
	var econ := get_node("/root/Economy")
	var paid: Dictionary = econ.pay_show_entry(show_id)
	if not bool(paid.get("ok", false)):
		_on_toast(String(paid.get("msg", "Can't go in.")))
		if _office:
			_office.open()
		return
	var show: Dictionary = paid.get("show", {})
	var gs := get_node("/root/GameState")
	var horse = _horse_state()
	var course = CourseDefScript.ashford_080()
	var cls = ClassDefScript.ashford_080()
	cls.height_m = float(show.get("height_m", 0.80))
	var hunter := bool(show.get("hunter", false))
	if hunter:
		cls.discipline = Enums.Discipline.HUNTER
	if cls.height_m > 0.85:
		for f in course.fences:
			f.height_m = cls.height_m
	_session = true
	_skip_show = false
	var events: Array = []
	var prev = null
	var i := 0
	var n: int = course.fences.size()
	var disob := 0
	var spots := [
		Vector3(6.2, 0.0, 1.4),
		Vector3(6.2, 0.0, -4.0),
		Vector3(7.6, 0.0, 3.2),
		Vector3(7.6, 0.0, 8.4),
		Vector3(4.4, 0.0, 2.0),
		Vector3(9.4, 0.0, 2.2),
	]
	_theater.open_card(String(show.get("name", "Show")), "Walk in. Stay, wait, or leave at each fence.")
	while i < n:
		var dest: Vector3 = spots[i % spots.size()]
		if _horse.has_method("walk_to"):
			_horse.walk_to(dest)
		_theater.open_card("Fence %d" % (i + 1), "Stay · Wait · Leave")
		var dec := Enums.Approach.STAY
		if not _skip_show:
			dec = await _wait_choice()
		if _skip_show:
			dec = Enums.Approach.STAY
		var ev = ShowResolver.resolve_fence(
			horse, float(gs.data.player.rider_skill), course.fences[i], i, prev, dec,
			cls, course, float(show.get("footing", 45.0)), gs.sim_rng
		)
		events.append(ev)
		_theater.show_event(ev.line())
		if bool(ev.jump_to) if false else true:
			if _horse.has_method("jump_to") and not bool(ev.refusal) and not bool(ev.runout):
				_horse.jump_to(dest + Vector3(0, 0, -2.2))
		if bool(ev.fall):
			break
		if bool(ev.refusal) or bool(ev.runout):
			disob += 1
			if disob >= int(cls.refusal_elim_after):
				break
			prev = ev
			continue
		prev = ev
		i += 1
	if not (disob >= int(cls.refusal_elim_after)):
		var fin = ShowResolver.resolve_fence(
			horse, float(gs.data.player.rider_skill), null, n, prev, Enums.Approach.STAY,
			cls, course, float(show.get("footing", 45.0)), gs.sim_rng
		)
		events.append(fin)
	var result
	if hunter:
		result = HunterJudge.finalize(horse, cls, course, events, gs.sim_rng)
	else:
		result = JumperJudge.finalize(horse, cls, course, events)
	var field: Array = [result]
	for ni in 7:
		field.append(Circuit._one_trip(Circuit._npc(horse, ni), 32.0 + float(ni), course, cls, float(show.get("footing", 45.0)), gs.sim_rng, hunter))
	if hunter:
		field.sort_custom(func(a, b): return float(a.score) > float(b.score) if not bool(a.eliminated) else false)
	else:
		field.sort_custom(func(a, b): return int(a.faults) < int(b.faults) if not bool(a.eliminated) else not bool(a.eliminated))
	var placing := 1
	for fi in field.size():
		if field[fi] == result:
			placing = fi + 1
			break
	var prize := 0
	if placing >= 1 and placing <= Circuit.PRIZES.size():
		prize = int(Circuit.PRIZES[placing - 1])
	result.placing = placing
	result.prize = prize
	econ.pay_prize(String(show.get("name", "Show")), prize, String(show.get("id", "")), placing)
	_theater.close()
	_session = false
	if _recap:
		_recap.open_result(result, "%s · %s" % [show.get("name", ""), show.get("class_label", "")])
	_on_toast("Placed %d. %s" % [placing, ("+$%d" % prize) if prize > 0 else "No check."])
	_refresh_clock()


func _wait_choice() -> int:
	_got_choice = false
	while not _got_choice:
		await get_tree().process_frame
	return _choice
