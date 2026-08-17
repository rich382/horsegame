extends CanvasLayer
## Feed, farrier, tack, and the arena footing upgrade. Economy.post is the till.

@onready var _stock: Label = $Panel/Stock


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null or gs.data.player == null:
		_stock.text = ""
		return
	var farm: Dictionary = gs.data.farm
	_stock.text = "Cash $%d\nHay %d days   ·   Grain %d days\nArena footing %d" % [
		int(gs.data.player.cash),
		int(farm.get("hay_days", 0)),
		int(farm.get("grain_days", 0)),
		int(farm.get("footing_quality", 40)),
	]


func _buy(msg: String) -> void:
	get_node("/root/EventBus").toast.emit(msg)
	_refresh()


func _on_hay() -> void:
	_buy(get_node("/root/Economy").buy_hay())


func _on_grain() -> void:
	_buy(get_node("/root/Economy").buy_grain())


func _on_farrier() -> void:
	var gs := get_node("/root/GameState")
	var horse = null
	if gs.data and not gs.data.horses.is_empty():
		horse = gs.data.horses[0]
	_buy(get_node("/root/Economy").buy_farrier(horse))


func _on_boots() -> void:
	_buy(get_node("/root/Economy").buy_boots())


func _on_martingale() -> void:
	_buy(get_node("/root/Economy").buy_martingale())


func _on_footing() -> void:
	_buy(get_node("/root/Economy").buy_footing())


func _on_close() -> void:
	visible = false
