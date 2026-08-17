extends CanvasLayer
## Afternoon school picker. Flat, poles, or a small gymnastic.

const Enums := preload("res://src/core/enums.gd")

signal picked(kind: int)

@onready var _hint: Label = $Panel/Hint


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	visible = true
	_refresh_hint()


func _refresh_hint() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.clock == null:
		_hint.text = ""
		return
	if int(gs.data.clock.phase) != Enums.Phase.AFTERNOON:
		_hint.text = "Schooling is an afternoon job."
		return
	if gs.data.horses.is_empty():
		_hint.text = "No horse."
		return
	var h = gs.data.horses[0]
	if bool(h.schooled_today):
		_hint.text = "%s already worked today." % h.name
	else:
		_hint.text = "They're in the ring. One trip — don't drill them."


func _pick(kind: int) -> void:
	visible = false
	picked.emit(kind)


func _on_flat() -> void:
	_pick(Enums.TrainingKind.FLAT)


func _on_poles() -> void:
	_pick(Enums.TrainingKind.POLES)


func _on_gymnastic() -> void:
	_pick(Enums.TrainingKind.GYMNASTIC)


func _on_close() -> void:
	visible = false
