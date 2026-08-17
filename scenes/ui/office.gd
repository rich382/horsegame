extends CanvasLayer
## Boarders, haul-for-hire, circuit, buy/sell horses, help.

const Barn := preload("res://src/barn/barn_system.gd")
const Circuit := preload("res://src/show/circuit.gd")

signal ashford_done(payload)

@onready var _body: Label = $Center/Card/Margin/VBox/Body
@onready var _jobs: VBoxContainer = $Center/Card/Margin/VBox/Scroll/Jobs


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	var gs := get_node("/root/GameState")
	if gs.data == null:
		_body.text = ""
		return
	var farm: Dictionary = gs.data.farm
	var horse = _horse()
	var abs_d: int = gs.data.clock.abs_day()
	var due: int = Barn.due_board(farm, abs_d)
	var hname := String(horse.name) if horse else "—"
	var lines: PackedStringArray = [
		"Working: %s" % hname,
		"Cash $%d   ·   Own horses %d   ·   Boarders %d" % [
			int(gs.data.player.cash),
			gs.data.horses.size(),
			farm.get("boarders", []).size(),
		],
		"Board due $%d   ·   Help: %s" % [due, "working student" if bool(farm.get("has_help", false)) else "just you"],
		"Rig: %s%s" % [
			"truck + trailer" if Barn.has_rig(farm) else "shipper",
			(" · loaded %s" % farm.get("loaded_for", "")) if String(farm.get("loaded_for", "")) != "" else "",
		],
	]
	_body.text = "\n".join(lines)
	_rebuild_jobs()


func _rebuild_jobs() -> void:
	for c in _jobs.get_children():
		c.queue_free()
	_add_btn("Take a boarder", _on_boarder)
	_add_btn("Collect board", _on_collect)
	_add_btn("Buy a prospect  —  $3,200", _on_prospect)
	_add_btn("Sell the selected horse", _on_sell)
	_add_btn("Hire a working student  —  $90/wk", _on_help)
	for job in Barn.HAUL_JOBS:
		var jid := String(job["id"])
		_add_btn("%s  —  $%d" % [job["label"], int(job["pay"])], func() -> void: _on_haul(jid))
	for show in Circuit.SHOWS:
		var sid := String(show["id"])
		_add_btn("Load trailer — %s" % show["name"], func() -> void: _on_load(sid))
		_add_btn("%s · %s" % [show["name"], show["class_label"]], func() -> void: _on_show(sid))


func _add_btn(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 36)
	b.text = text
	b.pressed.connect(cb)
	_jobs.add_child(b)


func _on_boarder() -> void:
	_toast(get_node("/root/Economy").take_boarder())
	_refresh()


func _on_collect() -> void:
	_toast(get_node("/root/Economy").collect_board())
	_refresh()


func _on_prospect() -> void:
	_toast(get_node("/root/Economy").buy_prospect())
	_refresh()


func _on_sell() -> void:
	_toast(get_node("/root/Economy").sell_selected())
	_refresh()


func _on_help() -> void:
	_toast(get_node("/root/Economy").hire_help())
	_refresh()


func _on_haul(job_id: String) -> void:
	_toast(get_node("/root/Economy").do_haul(job_id))
	_refresh()


func _on_load(show_id: String) -> void:
	_toast(get_node("/root/Economy").load_trailer(show_id))
	_refresh()


func _on_show(show_id: String) -> void:
	var out: Dictionary = get_node("/root/Economy").enter_show(show_id)
	_toast(String(out.get("msg", "Show.")))
	_refresh()
	if bool(out.get("ok", false)):
		visible = false
		ashford_done.emit(out)


func _on_close() -> void:
	visible = false


func _toast(msg: String) -> void:
	get_node("/root/EventBus").toast.emit(msg)


func _horse():
	var gs := get_node("/root/GameState")
	if gs.has_method("selected_horse"):
		return gs.selected_horse()
	if gs.data == null or gs.data.horses.is_empty():
		return null
	return gs.data.horses[0]
