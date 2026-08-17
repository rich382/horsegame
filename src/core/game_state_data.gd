class_name GameStateData
extends Resource
## Live session. Never ResourceSaver this; JSON via to_dict / from_dict.

const SAVE_VERSION := 1
const CalendarScript := preload("res://src/core/calendar.gd")
const PlayerStateScript := preload("res://src/core/player_state.gd")

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
		"horses": horses.duplicate(true),
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
	data.horses = d.get("horses", [])
	data.farm = d.get("farm", {})
	data.quests = d.get("quests", {"active": [], "done": []})
	data.ledger = d.get("ledger", [])
	data.in_progress_show = d.get("in_progress_show", null)
	return data
