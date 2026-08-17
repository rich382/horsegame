class_name GameStateData
extends Resource
## Live session. Never ResourceSaver this; JSON via to_dict / from_dict.

const SAVE_VERSION := 1
const CalendarScript := preload("res://src/core/calendar.gd")
const PlayerStateScript := preload("res://src/core/player_state.gd")
const HorseStateScript := preload("res://src/horse/horse_state.gd")

@export var seed: int = 0
@export var rng_call_count: int = 0
@export var clock: Resource
@export var player: Resource
@export var horses: Array = []
@export var farm: Dictionary = {}
@export var quests: Dictionary = {"active": [], "done": []}
@export var ledger: Array = []
@export var in_progress_show: Variant = null ## Dictionary or null.


func _init() -> void:
	if clock == null:
		clock = CalendarScript.new()
	if player == null:
		player = PlayerStateScript.new()


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"seed": seed,
		"rng_call_count": rng_call_count,
		"clock": clock.to_dict() if clock else CalendarScript.new().to_dict(),
		"player": player.to_dict() if player else PlayerStateScript.new().to_dict(),
		"horses": _horses_to_dicts(),
		"farm": farm.duplicate(true),
		"quests": quests.duplicate(true),
		"ledger": ledger.duplicate(true),
		"in_progress_show": in_progress_show,
	}


static func from_dict(d: Dictionary):
	var data = new()
	data.seed = int(d.get("seed", 0))
	data.rng_call_count = int(d.get("rng_call_count", 0))
	data.clock = CalendarScript.from_dict(d.get("clock", {}))
	data.player = PlayerStateScript.from_dict(d.get("player", {}))
	data.horses = _horses_from_any(d.get("horses", []))
	data.farm = d.get("farm", {})
	if not data.farm.has("identity_set") and data.horses.size() > 0:
		data.farm["identity_set"] = true
	data.quests = d.get("quests", {"active": [], "done": []})
	data.ledger = d.get("ledger", [])
	data.in_progress_show = d.get("in_progress_show", null)
	return data


func _horses_to_dicts() -> Array:
	var out: Array = []
	for h in horses:
		if h != null and h.has_method("to_dict"):
			out.append(h.to_dict())
		elif typeof(h) == TYPE_DICTIONARY:
			out.append(h)
	return out


static func _horses_from_any(raw: Array) -> Array:
	var out: Array = []
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY:
			out.append(HorseStateScript.from_dict(item))
		elif item != null and item is Resource and item.has_method("to_dict"):
			out.append(item)
	return out
