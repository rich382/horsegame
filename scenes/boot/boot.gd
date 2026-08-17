extends Node3D
## Playable boot yard: orbit camera, visible clock, on-screen actions.
## Esc is eaten by the Godot editor (stops Play). Use on-screen buttons or P.

const Care := preload("res://src/care/care_system.gd")
const STALL_POS := Vector3(-8.2, 0.0, -4.0)
const PADDOCK_POS := Vector3(-10.5, 0.0, 3.6)

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
	if _cam.has_signal("yard_clicked"):
		_cam.yard_clicked.connect(_on_yard_clicked)
	_refresh_clock()
	_on_toast("Name your horse. You walk over and do the chores.")


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
	_status_label.text = "%s   ·   Cash $%d" % [horse_name, int(gs.data.player.cash)]
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
	if bool(h.turned_out):
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


func _beside_horse() -> Vector3:
	return _horse.global_position + Vector3(1.3, 0, 0.4)


func _send_to_chore(dest: Vector3, done: Callable) -> void:
	if _player == null or not _player.has_method("walk_and_do"):
		done.call()
		return
	if _player.is_busy():
		_on_toast("Still working.")
		return
	var clip := ""
	if _player.has_method("pick_action_clip"):
		clip = String(_player.pick_action_clip())
	if not _player.walk_and_do(dest, clip, done):
		_on_toast("Still walking.")


func _on_yard_clicked(screen_pos: Vector2) -> void:
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
