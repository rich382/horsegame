extends CanvasLayer
## Name + four-coat picker. Confirm writes identity onto the starter horse.

const Enums := preload("res://src/core/enums.gd")

signal confirmed(horse_name: String, coat: int)

var _coat: int = Enums.CoatColor.BAY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/NameEdit.placeholder_text = "Bayberry"
	_highlight()


func _on_bay() -> void:
	_coat = Enums.CoatColor.BAY
	_highlight()


func _on_chestnut() -> void:
	_coat = Enums.CoatColor.CHESTNUT
	_highlight()


func _on_grey() -> void:
	_coat = Enums.CoatColor.GREY
	_highlight()


func _on_black() -> void:
	_coat = Enums.CoatColor.BLACK
	_highlight()


func _on_start() -> void:
	var n := String($Panel/NameEdit.text)
	confirmed.emit(n, _coat)
	visible = false


func _highlight() -> void:
	$Panel/Coats/Bay.modulate = Color(1, 1, 1, 1 if _coat == Enums.CoatColor.BAY else 0.55)
	$Panel/Coats/Chestnut.modulate = Color(1, 1, 1, 1 if _coat == Enums.CoatColor.CHESTNUT else 0.55)
	$Panel/Coats/Grey.modulate = Color(1, 1, 1, 1 if _coat == Enums.CoatColor.GREY else 0.55)
	$Panel/Coats/Black.modulate = Color(1, 1, 1, 1 if _coat == Enums.CoatColor.BLACK else 0.55)
