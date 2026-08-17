extends Node3D
## Blender-rigged Imagine horse card. Coat swaps the albedo. Idle loops.

const Enums := preload("res://src/core/enums.gd")
const RIGGED := "res://assets/models/horse/horse_rigged.glb"

const SPRITES := {
	Enums.CoatColor.BAY: preload("res://assets/sprites/horse_bay.png"),
	Enums.CoatColor.CHESTNUT: preload("res://assets/sprites/horse_chestnut.png"),
	Enums.CoatColor.GREY: preload("res://assets/sprites/horse_grey.png"),
	Enums.CoatColor.BLACK: preload("res://assets/sprites/horse_black.png"),
}

var _rig: Node
var _mesh: MeshInstance3D
var _anim: AnimationPlayer


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var here := global_position
	var look := cam.global_position
	look.y = here.y
	if look.distance_to(here) > 0.05:
		look_at(look, Vector3.UP)


func setup(horse) -> void:
	_ensure_rig()
	var coat := Enums.CoatColor.BAY
	if horse != null:
		coat = int(horse.coat)
	apply_coat(coat)
	_play("idle")


func apply_coat(coat: int) -> void:
	_ensure_rig()
	if _mesh == null:
		return
	var tex: Texture2D = SPRITES.get(coat, SPRITES[Enums.CoatColor.BAY])
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.42
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.85
	_mesh.set_surface_override_material(0, mat)


func play_walk() -> void:
	_play("walk")


func play_idle() -> void:
	_play("idle")


func _ensure_rig() -> void:
	if _rig and is_instance_valid(_rig):
		return
	for c in get_children():
		c.queue_free()
	if not ResourceLoader.exists(RIGGED):
		return
	var packed = load(RIGGED)
	if packed == null:
		return
	_rig = packed.instantiate()
	add_child(_rig)
	_mesh = _find_mesh(_rig)
	_anim = _find_anim(_rig)


func _play(clip: String) -> void:
	if _anim == null:
		return
	if _anim.has_animation(clip):
		_anim.play(clip)
		_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR


func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var found := _find_mesh(c)
		if found:
			return found
	return null


func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_anim(c)
		if found:
			return found
	return null
