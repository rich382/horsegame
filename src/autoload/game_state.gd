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
	_bus().clock_changed.emit()


func replace_data(d) -> void:
	data = d
	sim_rng = RngScript.new()
	sim_rng.reset(d.seed, d.rng_call_count)
	_bus().clock_changed.emit()
