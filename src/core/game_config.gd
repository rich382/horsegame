class_name GameConfig
extends Resource
## Authored playtest flags. Live game state is never saved through this resource.

const Enums := preload("res://src/core/enums.gd")

@export var use_os_seed: bool = true
@export var debug_seed: int = 0
@export var debug_log: bool = false
@export var debug_reveal_stats: bool = false
@export var discipline_hunter_enabled: bool = false
@export var construction_enabled: bool = false
@export var breeding_enabled: bool = false

## Coats offered on the new-game picker (PR 3). Other CoatColor values stay authored-only.
const NEW_GAME_COATS: Array[int] = [
	Enums.CoatColor.BAY,
	Enums.CoatColor.CHESTNUT,
	Enums.CoatColor.GREY,
	Enums.CoatColor.BLACK,
]
