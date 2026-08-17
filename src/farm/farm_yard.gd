class_name FarmYard
extends Node3D
## 3D Blender barn / jump / fence + Kenney trees on a wide lot.
## Arena sits east of the barn. Drive and rig sit on a west entrance.

const TEX_GRASS := preload("res://assets/textures/tex_grass.jpg")
const TEX_FOOTING := preload("res://assets/textures/tex_footing.jpg")
const BARN := "res://assets/models/farm/barn.glb"
const JUMP := "res://assets/models/farm/jump.glb"
const FENCE := "res://assets/models/farm/fence.glb"
const TREE_OAK := "res://assets/models/nature/tree_oak.glb"
const TREE_TALL := "res://assets/models/nature/tree_tall.glb"
const TREE_DEFAULT := "res://assets/models/nature/tree_default.glb"
const BUSH := "res://assets/models/nature/plant_bushLarge.glb"

const LOT := 160.0
const ARENA_AT := Vector3(6.5, 0.03, 2.0)
const BARN_AT := Vector3(-8.5, 0, -6.2)
const WING_AT := Vector3(-14.8, 0, -6.2)
const DRIVE_AT := Vector3(-42.0, 0.05, 2.0)
const LANE_AT := Vector3(-27.0, 0.05, -5.6)
const TRUCK_AT := Vector3(-42.0, 0.0, -1.2)
const TRAILER_AT := Vector3(-42.0, 0.0, 5.2)


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
	_sig = ""
	var old: Array = get_children()
	for c in old:
		remove_child(c)
		c.free()
	_sig = sig
	_add_ground()
	_add_arena(bool(farm.get("has_indoor", false)))
	## Aisle faces the yard (+Z). Exporter maps Blender +Y → Godot −Z, so yaw 180°.
	_add_model(BARN, BARN_AT, PI)
	if int(farm.get("barn_tier", 1)) >= 2:
		_add_model(BARN, WING_AT, PI, 1.0)
	_add_model(JUMP, Vector3(6.2, 0, -2.2), 0.15)
	_add_model(JUMP, Vector3(7.6, 0, 6.4), -0.35, 0.95)
	if int(farm.get("jump_sets", 1)) >= 2:
		_add_model(JUMP, Vector3(4.4, 0, 2.0), 1.2, 0.9)
		_add_model(JUMP, Vector3(9.4, 0, 2.2), -1.4, 0.9)
	## South paddock rail, kept east of the west drive.
	for i in 8:
		_add_model(FENCE, Vector3(-18.0 + float(i) * 3.0, 0, 12.0), 0.0)
	## West paddock rail so turnout stays off the gravel lane.
	for i in 5:
		_add_model(FENCE, Vector3(-20.0, 0, -2.0 + float(i) * 3.0), PI * 0.5)
	if int(farm.get("barn_tier", 1)) >= 2:
		for i in 4:
			_add_model(FENCE, Vector3(-22.0, 0, -10.0 + float(i) * 3.0), PI * 0.5)
	_add_trees()
	if bool(farm.get("has_truck", false)) or bool(farm.get("has_trailer", false)):
		_add_drive()
	if bool(farm.get("has_truck", false)):
		_add_truck(TRUCK_AT)
	if bool(farm.get("has_trailer", false)):
		_add_trailer(TRAILER_AT)


func _mat(tex: Texture2D, uv: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = uv
	m.roughness = 0.92
	return m


func _add_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(LOT, LOT)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _mat(TEX_GRASS, Vector3(40, 40, 1))
	add_child(inst)
	var body := StaticBody3D.new()
	body.name = "GroundPick"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(LOT, 0.2, LOT)
	col.shape = box
	col.position.y = -0.1
	body.add_child(col)
	add_child(body)


func _add_arena(indoor: bool) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(14, 20)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = ARENA_AT
	inst.material_override = _mat(TEX_FOOTING, Vector3(4, 6, 1))
	add_child(inst)
	if indoor:
		var roof := BoxMesh.new()
		roof.size = Vector3(16, 0.12, 22)
		var cover := MeshInstance3D.new()
		cover.mesh = roof
		cover.position = Vector3(ARENA_AT.x, 4.2, ARENA_AT.z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.32, 0.28)
		mat.roughness = 0.9
		cover.material_override = mat
		add_child(cover)


func _add_drive() -> void:
	## Parking apron west of the barn. Arena left edge is x ≈ -0.5; this pad
	## ends near x = -35 so the rig never sits on the ring.
	_gravel("Drive", DRIVE_AT, Vector2(14.0, 26.0))
	_gravel("DriveLane", LANE_AT, Vector2(26.0, 5.0))


func _gravel(node_name: String, at: Vector3, size: Vector2) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.56, 0.42)
	mat.roughness = 0.95
	inst.material_override = mat
	add_child(inst)


func _add_trees() -> void:
	var spots: Array = [
		[TREE_OAK, Vector3(-62.0, 0, -28.0), 0.4, 1.25],
		[TREE_TALL, Vector3(58.0, 0, -32.0), -0.2, 1.2],
		[TREE_DEFAULT, Vector3(-56.0, 0, 36.0), 1.1, 1.15],
		[TREE_OAK, Vector3(54.0, 0, 42.0), 0.7, 1.1],
		[TREE_TALL, Vector3(-68.0, 0, 8.0), 0.3, 1.05],
		[TREE_DEFAULT, Vector3(66.0, 0, 10.0), -0.8, 1.1],
		[TREE_OAK, Vector3(8.0, 0, -58.0), 1.4, 1.0],
		[TREE_TALL, Vector3(-12.0, 0, 58.0), 0.15, 1.1],
		[TREE_DEFAULT, Vector3(-48.0, 0, -48.0), 0.9, 1.05],
		[TREE_OAK, Vector3(48.0, 0, -50.0), -0.5, 1.15],
		[TREE_TALL, Vector3(-50.0, 0, 22.0), 0.6, 1.0],
		[BUSH, Vector3(-12.0, 0, 13.5), 0.2, 1.1],
		[BUSH, Vector3(22.0, 0, -22.0), 0.8, 1.0],
		[BUSH, Vector3(-24.0, 0, -14.0), 0.5, 1.15],
		[BUSH, Vector3(-36.0, 0, 14.0), 1.2, 1.05],
	]
	for s in spots:
		_add_model(s[0], s[1], s[2], s[3])


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
	var paint := Color(0.85, 0.16, 0.10)
	var dark := Color(0.12, 0.12, 0.13)
	_box("TruckBed", origin + Vector3(0, 0.95, 0.75), Vector3(2.6, 0.7, 3.1), paint)
	_box("TruckCab", origin + Vector3(0, 1.4, -1.45), Vector3(2.55, 1.5, 1.7), paint)
	_box("TruckHood", origin + Vector3(0, 0.95, -2.55), Vector3(2.4, 0.7, 0.9), paint)
	_box("TruckGlass", origin + Vector3(0, 1.65, -2.05), Vector3(2.2, 0.55, 0.14), Color(0.55, 0.72, 0.82))
	_box("TruckBumper", origin + Vector3(0, 0.45, -3.05), Vector3(2.55, 0.28, 0.2), dark)
	_wheel(origin + Vector3(-1.35, 0.42, 1.45))
	_wheel(origin + Vector3(1.35, 0.42, 1.45))
	_wheel(origin + Vector3(-1.35, 0.42, -1.85))
	_wheel(origin + Vector3(1.35, 0.42, -1.85))


func _add_trailer(origin: Vector3) -> void:
	var shell := Color(0.93, 0.90, 0.82)
	var dark := Color(0.12, 0.12, 0.13)
	_box("TrailerBox", origin + Vector3(0, 1.45, 0.25), Vector3(2.7, 2.3, 4.2), shell)
	_box("TrailerWindow", origin + Vector3(0, 1.95, -1.8), Vector3(1.8, 0.55, 0.1), Color(0.35, 0.38, 0.40))
	_box("TrailerHitch", origin + Vector3(0, 0.62, -2.35), Vector3(0.22, 0.22, 1.1), dark)
	_box("TrailerRamp", origin + Vector3(0, 0.48, 2.5), Vector3(2.1, 0.1, 0.85), Color(0.35, 0.32, 0.28))
	_wheel(origin + Vector3(-1.4, 0.42, 0.9))
	_wheel(origin + Vector3(1.4, 0.42, 0.9))
	_wheel(origin + Vector3(-1.4, 0.42, -0.7))
	_wheel(origin + Vector3(1.4, 0.42, -0.7))


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
