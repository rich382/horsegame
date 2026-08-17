extends CanvasLayer
## Feed, tack, equipment, barn, truck, trailer. Economy.post is the till.

const Catalog := preload("res://src/barn/shop_catalog.gd")

@onready var _stock: Label = $Center/Card/Margin/VBox/Stock
@onready var _list: VBoxContainer = $Center/Card/Margin/VBox/Scroll/List


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_list()


func open() -> void:
	visible = true
	_refresh()


func _build_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for section in Catalog.SECTIONS:
		var head := Label.new()
		head.text = String(section["title"])
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_theme_font_size_override("font_size", 18)
		head.add_theme_color_override("font_color", Color(0.95, 0.90, 0.76))
		_list.add_child(head)
		for item in section["items"]:
			var b := Button.new()
			b.custom_minimum_size = Vector2(0, 40)
			b.text = String(item["label"])
			var item_id := String(item["id"])
			b.pressed.connect(func() -> void: _on_buy(item_id))
			_list.add_child(b)


func _refresh() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		_stock.text = ""
		return
	var farm: Dictionary = gs.data.farm
	var rig := "none"
	if bool(farm.get("has_truck", false)) and bool(farm.get("has_trailer", false)):
		rig = "truck + two-horse"
	elif bool(farm.get("has_truck", false)):
		rig = "truck only"
	elif bool(farm.get("has_trailer", false)):
		rig = "trailer only"
	_stock.text = "Cash $%d   ·   Hay %dd   ·   Grain %dd\nBarn %d-stall   ·   Boarders %d   ·   Rig: %s" % [
		int(gs.data.player.cash),
		int(farm.get("hay_days", 0)),
		int(farm.get("grain_days", 0)),
		farm.get("stalls", []).size(),
		farm.get("boarders", []).size(),
		rig,
	]


func _on_buy(id: String) -> void:
	var msg: String = get_node("/root/Economy").buy(id)
	get_node("/root/EventBus").toast.emit(msg)
	_refresh()
	var boot := get_tree().current_scene
	if boot:
		var yard = boot.get_node_or_null("Yard")
		var gs := get_node("/root/GameState")
		if yard and yard.has_method("build") and gs and gs.data:
			yard.build(gs.data.farm)


func _on_close() -> void:
	visible = false
