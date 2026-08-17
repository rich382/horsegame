class_name FarmYard
extends Node3D
## Starter yard: painted Imagine sprites on a textured grass/arena floor.

const TEX_GRASS := preload("res://assets/textures/tex_grass.jpg")
const TEX_FOOTING := preload("res://assets/textures/tex_footing.jpg")
const SPR_BARN := preload("res://assets/sprites/barn.png")
const SPR_JUMP := preload("res://assets/sprites/jump.png")
const SPR_FENCE := preload("res://assets/sprites/fence.png")
const SPR_TREE := preload("res://assets/sprites/tree_oak.png")


func build() -> void:
	for c in get_children():
		c.queue_free()
	_add_ground()
	_add_arena()
	_add_sprite(SPR_BARN, Vector3(-8.5, 0, -6.0), 7.4)
	_add_sprite(SPR_JUMP, Vector3(6.5, 0, -2.4), 1.7)
	_add_sprite(SPR_JUMP, Vector3(7.4, 0, 6.2), 1.55)
	for i in 5:
		_add_sprite(SPR_FENCE, Vector3(-14.0 + float(i) * 3.1, 0, 6.8), 1.25)
	_add_sprite(SPR_TREE, Vector3(-17.0, 0, -9.0), 8.5)
	_add_sprite(SPR_TREE, Vector3(17.5, 0, -7.0), 7.6)
	_add_sprite(SPR_TREE, Vector3(-16.0, 0, 10.0), 7.2)
	_add_sprite(SPR_TREE, Vector3(15.0, 0, 12.0), 6.8)


func _mat(tex: Texture2D, uv: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = uv
	m.roughness = 0.92
	return m


func _add_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(48, 48)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _mat(TEX_GRASS, Vector3(12, 12, 1))
	add_child(inst)


func _add_arena() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(14, 20)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = Vector3(6.5, 0.03, 2.0)
	inst.material_override = _mat(TEX_FOOTING, Vector3(4, 6, 1))
	add_child(inst)


func _add_sprite(tex: Texture2D, origin: Vector3, height_m: float) -> void:
	var s := SpriteProp.make(tex, height_m)
	s.position.x = origin.x
	s.position.z = origin.z
	add_child(s)
