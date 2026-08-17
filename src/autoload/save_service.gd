extends Node

const CURRENT_VERSION := 1
const SLOT_PATH := "user://saves/slot_%d.json"
const AUTOSAVE_PATH := "user://saves/autosave.json"
const AUTOSAVE_BAK_PATH := "user://saves/autosave.bak.json"


const GameStateDataScript := preload("res://src/core/game_state_data.gd")
const CalendarScript := preload("res://src/core/calendar.gd")
const PlayerStateScript := preload("res://src/core/player_state.gd")


func _gs() -> Node:
	return Engine.get_main_loop().root.get_node("GameState")


func _bus() -> Node:
	return Engine.get_main_loop().root.get_node("EventBus")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	_bus().day_started.connect(_on_day_started)


func _on_day_started(_cal) -> void:
	autosave()


func save_slot(slot: int) -> Error:
	return _write_json(SLOT_PATH % slot, _gs().data.to_dict())


func load_slot(slot: int) -> Error:
	return _load_path(SLOT_PATH % slot)


func autosave() -> Error:
	if FileAccess.file_exists(AUTOSAVE_PATH):
		var prev := FileAccess.get_file_as_string(AUTOSAVE_PATH)
		var bak := FileAccess.open(AUTOSAVE_BAK_PATH, FileAccess.WRITE)
		if bak:
			bak.store_string(prev)
			bak.close()
	return _write_json(AUTOSAVE_PATH, _gs().data.to_dict())


func load_autosave() -> Error:
	return _load_path(AUTOSAVE_PATH)


func migrate(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var v := int(out.get("version", 0))
	while v < CURRENT_VERSION:
		v += 1
		out = _migrate_step(out, v)
	out["version"] = CURRENT_VERSION
	return out


func _migrate_step(d: Dictionary, to_version: int) -> Dictionary:
	match to_version:
		1:
			if not d.has("clock"):
				d["clock"] = CalendarScript.new().to_dict()
			if not d.has("player"):
				d["player"] = PlayerStateScript.new().to_dict()
			if not d.has("horses"):
				d["horses"] = []
			if not d.has("farm"):
				d["farm"] = {}
			if not d.has("quests"):
				d["quests"] = {"active": [], "done": []}
			if not d.has("ledger"):
				d["ledger"] = []
			return d
		_:
			return d


func _write_json(path: String, payload: Dictionary) -> Error:
	var dir := path.get_base_dir()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var rng = _gs().sim_rng
	if rng:
		payload["rng_call_count"] = rng.call_count
		_gs().data.rng_call_count = rng.call_count
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	return OK


func _load_path(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA
	var migrated := migrate(parsed)
	_gs().replace_data(GameStateDataScript.from_dict(migrated))
	return OK
