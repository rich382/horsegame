extends CanvasLayer
## Trip recap after a home gymnastic or a show.

@onready var _body: Label = $Center/Card/Margin/VBox/Body


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open_result(result, heading: String = "") -> void:
	if result == null:
		return
	var title := heading
	if title == "":
		title = "Home gymnastic 0.80 m"
		if result.class_id == &"ashford_080_jp":
			title = "Ashford 0.80 m jumper"
	var lines: PackedStringArray = [title, ""]
	if int(result.placing) > 0:
		lines.append("Placed %d%s" % [int(result.placing), ("  ·  $%d" % int(result.prize)) if int(result.prize) > 0 else ""])
		lines.append("")
	lines.append_array(result.recap_lines())
	_body.text = "\n".join(lines)
	visible = true


func _on_close() -> void:
	visible = false
