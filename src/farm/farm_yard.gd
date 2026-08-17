class_name FarmYard
extends Node3D
## Builds the starter 4-stall yard from Kenney CC0 props + painted textures.

const TEX_GRASS := preload("res://assets/textures/tex_grass.jpg")
const TEX_FOOTING := preload("res://assets/textures/tex_footing.jpg")
const TEX_WOOD := preload("res://assets/textures/tex_barn_wood.jpg")
const TEX_ROOF := preload("res://assets/textures/tex_barn_roof.jpg")

const TREE_OAK := "res://assets/models/nature/tree_oak.glb"
const TREE_DEFAULT := "res://assets/models/nature/tree_default.glb"
const TREE_TALL := "res://assets/models/nature/tree_tall.glb"
const TREE_SMALL := "res://assets/models/nature/tree_small.glb"
const BUSH := "res://assets/models/nature/plant_bush.glb"
const BUSH_LARGE := "res://assets/models/nature/plant_bushLarge.glb"
const FENCE := "res://assets/models/nature/fence_simple.glb"
const FENCE_GATE := "res://assets/models/nature/fence_gate.glb"
const FLOWER_Y := "res://assets/models/nature/flower_yellowA.glb"
const GRASS_TUFT := "res://assets/models/nature/grass_large.glb"
const ROCK := "res://assets/models/nature/rock_smallA.glb"


func build() -> void:
	for c in get_children():
		c.queue_free()
	_add_ground()
	_add_barn()
	_add_arena()
	_add_jumps()
	_scatter_nature()
	_add_fence_ring()


func _mat(tex: Texture2D, uv: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = uv
	m.roughness = 0.92
	return m


func _box(size: Vector3, origin: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = origin
	add_child(inst)
	return inst


func _add_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(48, 48)
	mesh.subdivide_width = 4
	mesh.subdivide_depth = 4
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = Vector3(0, 0, 0)
	inst.material_override = _mat(TEX_GRASS, Vector3(12, 12, 1))
	add_child(inst)


func _add_barn() -> void:
	var wood := _mat(TEX_WOOD, Vector3(2.2, 1.4, 1))
	var roof := _mat(TEX_ROOF, Vector3(3.0, 2.0, 1))
	_box(Vector3(10.0, 3.4, 5.2), Vector3(-8.5, 1.7, -6.0), wood)
	_box(Vector3(10.6, 0.18, 6.0), Vector3(-8.5, 3.55, -6.0), roof)
	## Aisle lean-to
	_box(Vector3(3.2, 2.2, 4.4), Vector3(-3.2, 1.1, -6.0), wood)


func _add_arena() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(14, 20)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = Vector3(6.5, 0.03, 2.0)
	inst.material_override = _mat(TEX_FOOTING, Vector3(4, 6, 1))
	add_child(inst)
	## Rail boards
	var rail := StandardMaterial3D.new()
	rail.albedo_color = Color(0.78, 0.66, 0.42)
	_box(Vector3(14.2, 0.08, 0.08), Vector3(6.5, 0.95, -8.0), rail)
	_box(Vector3(14.2, 0.08, 0.08), Vector3(6.5, 0.95, 12.0), rail)
	_box(Vector3(0.08, 0.08, 20.2), Vector3(-0.5, 0.95, 2.0), rail)
	_box(Vector3(0.08, 0.08, 20.2), Vector3(13.5, 0.95, 2.0), rail)


func _add_jumps() -> void:
	var pole := StandardMaterial3D.new()
	pole.albedo_color = Color(0.85, 0.78, 0.55)
	var std := StandardMaterial3D.new()
	std.albedo_color = Color(0.78, 0.72, 0.48)
	_box(Vector3(0.16, 1.15, 0.16), Vector3(3.4, 0.58, -3.2), std)
	_box(Vector3(0.16, 1.15, 0.16), Vector3(9.6, 0.58, -3.2), std)
	_box(Vector3(6.3, 0.1, 0.1), Vector3(6.5, 0.72, -3.2), pole)
	_box(Vector3(6.3, 0.1, 0.1), Vector3(6.5, 1.02, -3.2), pole)


func _scatter_nature() -> void:
	_prop(TREE_OAK, Vector3(-16, 0, -10), 1.15, 0.4)
	_prop(TREE_TALL, Vector3(-18, 0, 4), 1.0, 1.1)
	_prop(TREE_DEFAULT, Vector3(18, 0, -8), 1.05, -0.3)
	_prop(TREE_SMALL, Vector3(16, 0, 10), 0.95, 0.8)
	_prop(TREE_OAK, Vector3(4, 0, -16), 0.9, 2.0)
	_prop(BUSH_LARGE, Vector3(-12, 0, 8), 1.0, 0.2)
	_prop(BUSH, Vector3(-4, 0, 12), 1.1, 1.4)
	_prop(BUSH, Vector3(14, 0, -12), 1.0, 0.6)
	_prop(GRASS_TUFT, Vector3(-2, 0, 8), 1.2, 0.0)
	_prop(GRASS_TUFT, Vector3(2, 0, -10), 1.0, 0.7)
	_prop(FLOWER_Y, Vector3(-10, 0, 2), 1.0, 0.0)
	_prop(FLOWER_Y, Vector3(-11, 0, 3.2), 1.0, 1.2)
	_prop(ROCK, Vector3(12, 0, 14), 1.0, 0.3)


func _add_fence_ring() -> void:
	## Paddock left of the arena
	for i in 6:
		_prop(FENCE, Vector3(-16.0 + i * 2.2, 0, 6.5), 1.0, 0.0)
	_prop(FENCE_GATE, Vector3(-3.0, 0, 6.5), 1.0, 0.0)


func _prop(path: String, origin: Vector3, scale: float, yaw: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var packed = load(path)
	if packed == null:
		return
	var node: Node = packed.instantiate()
	if node is Node3D:
		var n3 := node as Node3D
		n3.position = origin
		n3.scale = Vector3.ONE * scale
		n3.rotation.y = yaw
	add_child(node)
