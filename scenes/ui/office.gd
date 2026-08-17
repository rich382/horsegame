extends CanvasLayer
## Boarders, haul-for-hire, Ashford Saturday.

const Barn := preload("res://src/barn/barn_system.gd")
const Ashford := preload("res://src/show/ashford.gd")

signal ashford_done(payload)

@onready var _body: Label = $Center/Card/Margin/VBox/Body
@onready var _jobs: VBoxContainer = $Center/Card/Margin/VBox/Jobs


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
	var abs_d: int = gs.data.clock.abs_day()
	var due: int = Barn.due_board(farm, abs_d)
	var haul_why := Barn.haul_blocked(gs.data)
	var show_why := Ashford.block_reason(gs.data, _horse())
	var lines: PackedStringArray = [
		"Cash $%d" % int(gs.data.player.cash),
		"Stalls %d   ·   Boarders %d   ·   Board due $%d" % [
			farm.get("stalls", []).size(),
			farm.get("boarders", []).size(),
			due,
		],
		"Rig: %s" % ("truck + trailer" if Barn.has_rig(farm) else "walk or pay a shipper"),
		"",
		("Haul: " + haul_why) if haul_why != "" else "Haul: ready.",
		("Ashford: " + show_why) if show_why != "" else "Ashford: in-gate is open.",
	]
	_body.text = "\n".join(lines)
	_rebuild_jobs()


func _rebuild_jobs() -> void:
	for c in _jobs.get_children():
		c.queue_free()
	_add_btn("Take a boarder", _on_boarder)
	_add_btn("Collect board", _on_collect)
	for job in Barn.HAUL_JOBS:
		var jid := String(job["id"])
		var label := "%s  —  $%d" % [job["label"], int(job["pay"])]
		_add_btn(label, func() -> void: _on_haul(jid))
	_add_btn("Ashford 0.80 m jumper", _on_ashford)


func _add_btn(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 40)
	b.text = text
	b.pressed.connect(cb)
	_jobs.add_child(b)


func _on_boarder() -> void:
	_toast(get_node("/root/Economy").take_boarder())
	_refresh()


func _on_collect() -> void:
	_toast(get_node("/root/Economy").collect_board())
	_refresh()


func _on_haul(job_id: String) -> void:
	_toast(get_node("/root/Economy").do_haul(job_id))
	_refresh()


func _on_ashford() -> void:
	var out: Dictionary = get_node("/root/Economy").enter_ashford()
	_toast(String(out.get("msg", "Ashford.")))
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
	if gs.data == null or gs.data.horses.is_empty():
		return null
	return gs.data.horses[0]
