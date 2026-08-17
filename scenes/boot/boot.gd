extends Node3D
## Playable boot yard: orbit camera, visible clock, on-screen actions.
## Esc is eaten by the Godot editor (stops Play). Use on-screen buttons or P.

@onready var _pause: CanvasLayer = $PauseMenu
@onready var _clock_label: Label = $HUD/Clock
@onready var _toast_label: Label = $HUD/Toast
@onready var _status_label: Label = $HUD/Status
@onready var _yard: Node3D = $Yard
@onready var _horse: Node3D = $HorsePresenter
@onready var _new_game: CanvasLayer = $NewGame


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
	_refresh_clock()
	_on_toast("Name your horse, pick a coat, then look around the yard.")


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
	_status_label.text = "%s   ·   Cash $%d   ·   Next Phase / Sleep still run the clock." % [
		horse_name, int(gs.data.player.cash)
	]


func _spawn_horse() -> void:
	var gs := get_node("/root/GameState")
	var horse = null
	if gs.data and gs.data.horses.size() > 0:
		horse = gs.data.horses[0]
	_horse.position = Vector3(-8.0, 0.0, 2.2)
	_horse.rotation.y = 0.5
	if _horse.has_method("setup"):
		_horse.setup(horse)


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
	_on_toast("%s is on the farm." % gs.data.horses[0].name)
