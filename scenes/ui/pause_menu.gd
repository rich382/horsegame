extends CanvasLayer

@onready var _panel: Control = $Panel


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			toggle()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_resume() -> void:
	close()


func _on_sleep() -> void:
	get_node("/root/GameClock").sleep_until_morning()
	get_node("/root/SaveService").autosave()


func _on_save() -> void:
	get_node("/root/SaveService").save_slot(1)
	get_node("/root/EventBus").toast.emit("Saved.")


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_load() -> void:
	var err: Error = get_node("/root/SaveService").load_slot(1)
	close()
	if err == OK:
		get_node("/root/EventBus").toast.emit("Loaded slot 1.")
		get_tree().reload_current_scene()
	else:
		get_node("/root/EventBus").toast.emit("No save in slot 1.")


func _on_new_game() -> void:
	var cfg = load("res://src/core/game_config.gd").new()
	get_node("/root/GameState").new_game(cfg)
	close()
	get_tree().reload_current_scene()
