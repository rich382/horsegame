extends CanvasLayer
## Trip recap after a home gymnastic or a show.

@onready var _body: Label = $Center/Card/Margin/VBox/Body


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open_result(result) -> void:
	if result == null:
		return
	var lines: PackedStringArray = ["Home gymnastic 0.80 m", ""]
	lines.append_array(result.recap_lines())
	_body.text = "\n".join(lines)
	visible = true


func _on_close() -> void:
	visible = false
