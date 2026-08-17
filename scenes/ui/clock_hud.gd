extends CanvasLayer


func _ready() -> void:
	get_node("/root/EventBus").clock_changed.connect(_refresh)
	get_node("/root/EventBus").phase_started.connect(_on_phase)
	_refresh()


func _on_phase(_phase) -> void:
	_refresh()


func _refresh() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.clock == null:
		$Label.text = ""
		return
	$Label.text = gs.data.clock.hud_text()
