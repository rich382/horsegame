extends Node3D
## Playable boot yard: orbit camera, visible clock, on-screen actions.
## Esc is eaten by the Godot editor (stops Play). Use on-screen buttons or P.

@onready var _pause: CanvasLayer = $PauseMenu
@onready var _clock_label: Label = $HUD/Clock
@onready var _toast_label: Label = $HUD/Toast
@onready var _status_label: Label = $HUD/Status
@onready var _yard: Node3D = $Yard


func _ready() -> void:
	_build_yard()
	var bus := get_node("/root/EventBus")
	if not bus.toast.is_connected(_on_toast):
		bus.toast.connect(_on_toast)
	if not bus.clock_changed.is_connected(_refresh_clock):
		bus.clock_changed.connect(_refresh_clock)
	_refresh_clock()
	_on_toast("Left-drag to look around. Buttons below change the day.")


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
	_status_label.text = "Cash $%d   ·   Click Next Phase or Sleep to play the clock." % int(gs.data.player.cash)


func _build_yard() -> void:
	for child in _yard.get_children():
		child.queue_free()
	_add_box(_yard, Vector3(28, 0.16, 28), Vector3(0, -0.08, 0), Color(0.38, 0.50, 0.32))
	_add_box(_yard, Vector3(10, 3.2, 4.2), Vector3(-6.5, 1.6, -4.5), Color(0.45, 0.32, 0.22))
	_add_box(_yard, Vector3(10.4, 0.25, 4.6), Vector3(-6.5, 3.3, -4.5), Color(0.35, 0.22, 0.16))
	_add_box(_yard, Vector3(12, 0.08, 18), Vector3(5.5, 0.04, 2.0), Color(0.62, 0.58, 0.42))
	_add_box(_yard, Vector3(0.18, 1.1, 0.18), Vector3(1.2, 0.55, -4.5), Color(0.82, 0.74, 0.52))
	_add_box(_yard, Vector3(0.18, 1.1, 0.18), Vector3(9.8, 0.55, -4.5), Color(0.82, 0.74, 0.52))
	_add_box(_yard, Vector3(8.8, 0.12, 0.12), Vector3(5.5, 1.05, -4.5), Color(0.72, 0.58, 0.32))
	_add_box(_yard, Vector3(8.8, 0.12, 0.12), Vector3(5.5, 0.72, -4.5), Color(0.72, 0.58, 0.32))


func _add_box(parent: Node3D, size: Vector3, origin: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = origin
	parent.add_child(inst)
