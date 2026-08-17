extends Resource

const Enums := preload("res://src/core/enums.gd")

@export var id: StringName = &""
@export var kind: int = Enums.FenceKind.VERTICAL
@export var height_m: float = 0.80
@export var width_m: float = 0.0
@export var spook: float = 0.0
@export var related_distance_m: float = 0.0
@export var is_natural: bool = false
@export var bending: bool = false


static func make(p_id: String, p_height: float, p_width: float = 0.0, p_spook: float = 0.0, p_related: float = 0.0):
	var f = new()
	f.id = StringName(p_id)
	f.height_m = p_height
	f.width_m = p_width
	f.spook = p_spook
	f.related_distance_m = p_related
	if p_width > 0.01:
		f.kind = Enums.FenceKind.OXER
	return f
