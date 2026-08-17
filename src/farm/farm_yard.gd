class_name FarmYard
extends Node3D
## 3D Blender barn / jump / fence + Kenney trees on textured ground.

const TEX_GRASS := preload("res://assets/textures/tex_grass.jpg")
const TEX_FOOTING := preload("res://assets/textures/tex_footing.jpg")
const BARN := "res://assets/models/farm/barn.glb"
const JUMP := "res://assets/models/farm/jump.glb"
const FENCE := "res://assets/models/farm/fence.glb"
const TREE_OAK := "res://assets/models/nature/tree_oak.glb"
const TREE_TALL := "res://assets/models/nature/tree_tall.glb"
const TREE_DEFAULT := "res://assets/models/nature/tree_default.glb"
const BUSH := "res://assets/models/nature/plant_bushLarge.glb"


func build() -> void:
	for c in get_children():
		c.queue_free()
	_add_ground()
	_add_arena()
	## Aisle faces the yard (+Z). Exporter maps Blender +Y → Godot −Z, so yaw 180°.
	_add_model(BARN, Vector3(-8.5, 0, -6.2), PI)
	_add_model(JUMP, Vector3(6.2, 0, -2.2), 0.15)
	_add_model(JUMP, Vector3(7.6, 0, 6.4), -0.35, 0.95)
	for i in 5:
		_add_model(FENCE, Vector3(-14.0 + float(i) * 3.0, 0, 7.0), 0.0)
	_add_model(TREE_OAK, Vector3(-17.0, 0, -10.0), 0.4, 1.1)
	_add_model(TREE_TALL, Vector3(18.0, 0, -8.0), -0.2, 1.0)
	_add_model(TREE_DEFAULT, Vector3(-16.5, 0, 11.0), 1.1, 1.05)
	_add_model(TREE_OAK, Vector3(16.0, 0, 12.5), 0.7, 0.9)
	_add_model(BUSH, Vector3(-12.0, 0, 8.5), 0.2, 1.1)
	_add_model(BUSH, Vector3(13.5, 0, -11.0), 0.8, 1.0)


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


func _add_model(path: String, origin: Vector3, yaw: float = 0.0, scale: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		push_warning("FarmYard missing %s" % path)
		return
	var packed = load(path)
	if packed == null:
		return
	var node: Node = packed.instantiate()
	if node is Node3D:
		var n3 := node as Node3D
		n3.position = origin
		n3.rotation.y = yaw
		n3.scale = Vector3.ONE * scale
	add_child(node)
