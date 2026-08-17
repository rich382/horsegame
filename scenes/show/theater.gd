extends CanvasLayer
## Fence-by-fence approach. Stay / Wait / Leave, then the horse jumps.

const Enums := preload("res://src/core/enums.gd")

signal decided(kind: int)
signal skipped

@onready var _title: Label = $Bar/Title
@onready var _hint: Label = $Bar/Hint


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open_card(heading: String, hint: String) -> void:
	_title.text = heading
	_hint.text = hint
	visible = true


func show_event(line: String) -> void:
	_hint.text = line


func close() -> void:
	visible = false


func _on_stay() -> void:
	decided.emit(Enums.Approach.STAY)


func _on_wait() -> void:
	decided.emit(Enums.Approach.WAIT)


func _on_leave() -> void:
	decided.emit(Enums.Approach.LEAVE)


func _on_skip() -> void:
	skipped.emit()
