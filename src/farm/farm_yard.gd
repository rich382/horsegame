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


var _sig := ""


func build(farm: Dictionary = {}) -> void:
	var sig := "%s-%s-%s-%s-%s" % [
		str(farm.get("barn_tier", 1)),
		str(farm.get("has_truck", false)),
		str(farm.get("has_trailer", false)),
		str(farm.get("has_indoor", false)),
		str(farm.get("jump_sets", 1)),
	]
	var truck_ok := (not bool(farm.get("has_truck", false))) or get_node_or_null("TruckCab") != null
	var trail_ok := (not bool(farm.get("has_trailer", false))) or get_node_or_null("TrailerBox") != null
	if sig == _sig and get_child_count() > 0 and truck_ok and trail_ok:
		return
	_sig = sig
	for c in get_children():
		c.queue_free()
	_add_ground()
	_add_arena(bool(farm.get("has_indoor", false)))
	## Aisle faces the yard (+Z). Exporter maps Blender +Y → Godot −Z, so yaw 180°.
	_add_model(BARN, Vector3(-8.5, 0, -6.2), PI)
	if int(farm.get("barn_tier", 1)) >= 2:
		_add_model(BARN, Vector3(-14.8, 0, -6.2), PI, 1.0)
	_add_model(JUMP, Vector3(6.2, 0, -2.2), 0.15)
	_add_model(JUMP, Vector3(7.6, 0, 6.4), -0.35, 0.95)
	if int(farm.get("jump_sets", 1)) >= 2:
		_add_model(JUMP, Vector3(4.4, 0, 2.0), 1.2, 0.9)
		_add_model(JUMP, Vector3(9.4, 0, 2.2), -1.4, 0.9)
	for i in 5:
		_add_model(FENCE, Vector3(-14.0 + float(i) * 3.0, 0, 7.0), 0.0)
	if int(farm.get("barn_tier", 1)) >= 2:
		for i in 3:
			_add_model(FENCE, Vector3(-18.0, 0, -4.0 + float(i) * 3.0), PI * 0.5)
	_add_model(TREE_OAK, Vector3(-17.0, 0, -10.0), 0.4, 1.1)
	_add_model(TREE_TALL, Vector3(18.0, 0, -8.0), -0.2, 1.0)
	_add_model(TREE_DEFAULT, Vector3(-16.5, 0, 11.0), 1.1, 1.05)
	_add_model(TREE_OAK, Vector3(16.0, 0, 12.5), 0.7, 0.9)
	_add_model(BUSH, Vector3(-12.0, 0, 8.5), 0.2, 1.1)
	_add_model(BUSH, Vector3(13.5, 0, -11.0), 0.8, 1.0)
	if bool(farm.get("has_truck", false)) or bool(farm.get("has_trailer", false)):
		_add_drive()
	if bool(farm.get("has_truck", false)):
		_add_truck(Vector3(-4.8, 0.0, 0.6))
	if bool(farm.get("has_trailer", false)):
		_add_trailer(Vector3(-4.8, 0.0, 4.4))


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
	var body := StaticBody3D.new()
	body.name = "GroundPick"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(48, 0.2, 48)
	col.shape = box
	col.position.y = -0.1
	body.add_child(col)
	add_child(body)


func _add_arena(indoor: bool) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(14, 20)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = Vector3(6.5, 0.03, 2.0)
	inst.material_override = _mat(TEX_FOOTING, Vector3(4, 6, 1))
	add_child(inst)
	if indoor:
		var roof := BoxMesh.new()
		roof.size = Vector3(16, 0.12, 22)
		var cover := MeshInstance3D.new()
		cover.mesh = roof
		cover.position = Vector3(6.5, 4.2, 2.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.32, 0.28)
		mat.roughness = 0.9
		cover.material_override = mat
		add_child(cover)


func _add_drive() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(5.5, 10.0)
	var inst := MeshInstance3D.new()
	inst.name = "Drive"
	inst.mesh = mesh
	inst.position = Vector3(-4.8, 0.04, 2.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.40, 0.36)
	mat.roughness = 0.95
	inst.material_override = mat
	add_child(inst)


func _box(name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.name = name
	inst.mesh = mesh
	inst.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	inst.material_override = mat
	add_child(inst)
	return inst


func _wheel(at: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.38
	mesh.bottom_radius = 0.38
	mesh.height = 0.28
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = at
	inst.rotation.z = PI * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.08)
	mat.roughness = 0.95
	inst.material_override = mat
	add_child(inst)


func _add_truck(origin: Vector3) -> void:
	var paint := Color(0.72, 0.22, 0.14)
	var dark := Color(0.12, 0.12, 0.13)
	_box("TruckBed", origin + Vector3(0, 0.72, 0.55), Vector3(2.05, 0.55, 2.4), paint)
	_box("TruckCab", origin + Vector3(0, 1.05, -1.15), Vector3(2.0, 1.15, 1.35), paint)
	_box("TruckHood", origin + Vector3(0, 0.72, -2.05), Vector3(1.9, 0.55, 0.7), paint)
	_box("TruckGlass", origin + Vector3(0, 1.25, -1.55), Vector3(1.7, 0.45, 0.12), Color(0.55, 0.72, 0.82))
	_box("TruckBumper", origin + Vector3(0, 0.38, -2.42), Vector3(2.0, 0.22, 0.16), dark)
	_wheel(origin + Vector3(-1.05, 0.38, 1.15))
	_wheel(origin + Vector3(1.05, 0.38, 1.15))
	_wheel(origin + Vector3(-1.05, 0.38, -1.55))
	_wheel(origin + Vector3(1.05, 0.38, -1.55))


func _add_trailer(origin: Vector3) -> void:
	var shell := Color(0.86, 0.84, 0.78)
	var dark := Color(0.12, 0.12, 0.13)
	_box("TrailerBox", origin + Vector3(0, 1.15, 0.2), Vector3(2.15, 1.85, 3.4), shell)
	_box("TrailerWindow", origin + Vector3(0, 1.55, -1.45), Vector3(1.4, 0.45, 0.08), Color(0.35, 0.38, 0.40))
	_box("TrailerHitch", origin + Vector3(0, 0.55, -1.85), Vector3(0.18, 0.18, 0.9), dark)
	_box("TrailerRamp", origin + Vector3(0, 0.42, 2.05), Vector3(1.7, 0.08, 0.7), Color(0.35, 0.32, 0.28))
	_wheel(origin + Vector3(-1.1, 0.38, 0.7))
	_wheel(origin + Vector3(1.1, 0.38, 0.7))
	_wheel(origin + Vector3(-1.1, 0.38, -0.5))
	_wheel(origin + Vector3(1.1, 0.38, -0.5))


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
