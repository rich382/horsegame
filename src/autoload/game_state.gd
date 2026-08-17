extends Node
## Autoload. Holds GameStateData. Do not cache this Resource elsewhere.

const GameConfigScript := preload("res://src/core/game_config.gd")
const GameStateDataScript := preload("res://src/core/game_state_data.gd")
const RngScript := preload("res://src/core/rng.gd")
const HorseFactoryScript := preload("res://src/horse/horse_factory.gd")

var data
var sim_rng


func _bus() -> Node:
	return Engine.get_main_loop().root.get_node("EventBus")


func _ready() -> void:
	if data == null:
		new_game(GameConfigScript.new())


func new_game(config) -> void:
	data = GameStateDataScript.new()
	if config.use_os_seed:
		data.seed = RandomNumberGenerator.new().randi()
	else:
		data.seed = config.debug_seed
	data.rng_call_count = 0
	sim_rng = RngScript.new()
	sim_rng.reset(data.seed, 0)
	var horse = HorseFactoryScript.instantiate(HorseFactoryScript.starter_def(), sim_rng)
	data.horses = [horse]
	horse.tack = {"saddle_uid": "t_saddle", "bridle_uid": "t_bridle"}
	data.farm = _fill_farm({
		"care_quality": 0.50,
		"footing_quality": 40,
		"training_efficiency": 0.15,
		"hay_days": 14,
		"grain_days": 14,
		"tack_owned": [
			{"uid": "t_saddle", "def_id": "cc_saddle", "condition": 70},
			{"uid": "t_bridle", "def_id": "snaffle", "condition": 70},
		],
		"stalls": [
			{"id": "stall_0", "dirt": 15.0, "occupant_uid": horse.uid},
			{"id": "stall_1", "dirt": 0.0, "occupant_uid": ""},
			{"id": "stall_2", "dirt": 0.0, "occupant_uid": ""},
			{"id": "stall_3", "dirt": 0.0, "occupant_uid": ""},
		],
	})
	data.farm["selected_uid"] = String(horse.uid)
	_bus().clock_changed.emit()


func selected_horse():
	if data == null or data.horses.is_empty():
		return null
	var uid := String(data.farm.get("selected_uid", ""))
	for h in data.horses:
		if h != null and String(h.uid) == uid:
			return h
	return data.horses[0]


func select_next(step: int = 1):
	if data == null or data.horses.is_empty():
		return
	var i := 0
	var cur = selected_horse()
	for n in data.horses.size():
		if data.horses[n] == cur:
			i = n
			break
	i = (i + step) % data.horses.size()
	if i < 0:
		i += data.horses.size()
	data.farm["selected_uid"] = String(data.horses[i].uid)
	_bus().clock_changed.emit()


func replace_data(d) -> void:
	data = d
	if data:
		data.farm = _fill_farm(data.farm if data.farm else {})
	sim_rng = RngScript.new()
	sim_rng.reset(d.seed, d.rng_call_count)
	_bus().clock_changed.emit()


func _fill_farm(farm: Dictionary) -> Dictionary:
	if not farm.has("hay_days"):
		farm["hay_days"] = 14
	if not farm.has("grain_days"):
		farm["grain_days"] = 14
	if not farm.has("training_efficiency"):
		farm["training_efficiency"] = 0.15
	if not farm.has("footing_quality"):
		farm["footing_quality"] = 40
	if not farm.has("care_quality"):
		farm["care_quality"] = 0.50
	if not farm.has("tack_owned"):
		farm["tack_owned"] = []
	if not farm.has("stalls"):
		farm["stalls"] = []
	if not farm.has("barn_tier"):
		farm["barn_tier"] = 1
	if not farm.has("has_truck"):
		farm["has_truck"] = false
	if not farm.has("has_trailer"):
		farm["has_trailer"] = false
	if not farm.has("trailer_capacity"):
		farm["trailer_capacity"] = 0
	if not farm.has("has_drag"):
		farm["has_drag"] = false
	if not farm.has("has_indoor"):
		farm["has_indoor"] = false
	if not farm.has("jump_sets"):
		farm["jump_sets"] = 1
	if not farm.has("boarders"):
		farm["boarders"] = []
	if not farm.has("last_haul_abs_day"):
		farm["last_haul_abs_day"] = -99
	if not farm.has("has_help"):
		farm["has_help"] = false
	if not farm.has("help_paid_abs"):
		farm["help_paid_abs"] = 0
	if not farm.has("loaded_for"):
		farm["loaded_for"] = ""
	if not farm.has("selected_uid"):
		farm["selected_uid"] = ""
	return farm
