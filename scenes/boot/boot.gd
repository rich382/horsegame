extends Node3D
## Playable boot yard: orbit camera, visible clock, on-screen actions.
## Esc is eaten by the Godot editor (stops Play). Use on-screen buttons or P.

const Care := preload("res://src/care/care_system.gd")
const Training := preload("res://src/training/training_system.gd")
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
@onready var _school: CanvasLayer = $School
@onready var _school_work: HBoxContainer = $HUD/SchoolWork

var _session := false


func _ready() -> void:
	if _yard.has_method("build"):
		_yard.build()
	_spawn_horse()
	var bus := get_node("/root/EventBus")
	if not bus.toast.is_connected(_on_toast):
		bus.toast.connect(_on_toast)
	if not bus.clock_changed.is_connected(_refresh_clock):
		bus.clock_changed.connect(_refresh_clock)
	_new_game.confirmed.connect(_on_identity)
	_new_game.coat_previewed.connect(_on_coat_preview)
	_school.picked.connect(_on_school_picked)
	if _school.has_signal("closed"):
		_school.closed.connect(_hide_school_choices)
	if _school_work:
		_school_work.visible = false
	if _cam.has_signal("yard_clicked"):
		_cam.yard_clicked.connect(_on_yard_clicked)
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
	if gs.data.horses.size() > 0:
		horse_name = String(gs.data.horses[0].name)
	var farm: Dictionary = gs.data.farm
	_status_label.text = "%s   ·   $%d   ·   Hay %dd   ·   Grain %dd" % [
		horse_name,
		int(gs.data.player.cash),
		int(farm.get("hay_days", 0)),
		int(farm.get("grain_days", 0)),
	]
	_refresh_sheet()
	_place_horse()


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
	if gs.data == null or gs.data.horses.is_empty():
		return null
	return gs.data.horses[0]


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
		_horse.position = PADDOCK_POS
		_horse.rotation.y = -0.4
	else:
		_horse.position = STALL_POS
		_horse.rotation.y = 0.2


func _on_feed() -> void:
	_send_to_chore(_beside_horse(), func() -> void:
		var gs := get_node("/root/GameState")
		_on_toast(Care.feed(gs.data, _horse_state()))
		_refresh_clock()
	)


func _on_pick() -> void:
	_send_to_chore(STALL_POS + Vector3(1.4, 0, 0.8), func() -> void:
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
	_hide_school_choices()
	var gs := get_node("/root/GameState")
	var why := Training.block_reason(_horse_state(), gs.data)
	if why != "":
		_on_toast(why)
		return
	if _session:
		_on_toast("Still in the ring.")
		return
	_session = true
	_on_toast("Taking %s to the ring for %s." % [_horse_state().name, Training.kind_label(kind)])
	_lead_to_arena(func() -> void:
		var horse = _horse_state()
		if horse:
			horse.at_arena = true
			horse.turned_out = false
		_on_toast("Working %s with %s." % [Training.kind_label(kind), horse.name if horse else "them"])
		_run_school_path(_school_steps(kind), 0, func() -> void:
			_on_toast(Training.apply_session(_horse_state(), kind, gs.data))
			_session = false
			_refresh_clock()
		)
	)


func _lead_to_arena(done: Callable) -> void:
	var finish := func() -> void:
		if done.is_valid():
			done.call()
	if _player == null or not _player.has_method("walk_to"):
		if _horse.has_method("walk_to"):
			_horse.walk_to(ARENA_HORSE, finish)
		else:
			_horse.position = ARENA_HORSE
			finish.call()
		return
	if _player.is_busy():
		if _horse.has_method("walk_to"):
			_horse.walk_to(ARENA_HORSE, finish)
		else:
			finish.call()
		return
	_player.walk_to(_beside_horse(), func() -> void:
		if _horse.has_method("walk_to"):
			_horse.walk_to(ARENA_HORSE)
		else:
			_horse.position = ARENA_HORSE
		_player.walk_to(ARENA_HORSE + Vector3(1.5, 0.0, 0.5), finish)
	)


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
		if not _horse.walk_to(dest, next):
			next.call()
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
