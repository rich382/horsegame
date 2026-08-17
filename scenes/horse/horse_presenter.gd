extends Node3D
## Quaternius 3D horse, planted on the grass. Coat tints the body mesh.

const Enums := preload("res://src/core/enums.gd")
const HORSE_FBX := "res://assets/models/horse/Horse.fbx"
const HORSE_OBJ := "res://assets/models/horse/Horse.obj"
const TARGET_HEIGHT := 2.05

var _body: Node3D
var _anim: AnimationPlayer


func setup(horse) -> void:
	for c in get_children():
		c.queue_free()
	_body = _instance_model()
	if _body == null:
		return
	add_child(_body)
	_normalize_and_plant(_body)
	_ensure_pick()
	_anim = _find_anim(_body)
	_play_idle()
	if horse != null:
		apply_coat(int(horse.coat))


func apply_coat(coat: int) -> void:
	if _body == null:
		return
	var body_color := _coat_color(coat)
	var mane := Color(0.07, 0.06, 0.05)
	if coat == Enums.CoatColor.GREY:
		mane = Color(0.78, 0.78, 0.80)
	elif coat == Enums.CoatColor.CHESTNUT:
		mane = Color(0.22, 0.10, 0.05)
	for mi in _meshes(_body):
		var count := mi.get_surface_override_material_count()
		if count == 0 and mi.mesh:
			count = mi.mesh.get_surface_count()
		for i in count:
			var src: Material = mi.get_active_material(i)
			var mat := StandardMaterial3D.new()
			if src is StandardMaterial3D:
				mat = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			var base := mat.albedo_color
			var lum := (base.r + base.g + base.b) / 3.0
			mat.albedo_color = mane if lum < 0.12 else body_color
			mi.set_surface_override_material(i, mat)


func _coat_color(coat: int) -> Color:
	match coat:
		Enums.CoatColor.CHESTNUT:
			return Color(0.58, 0.24, 0.10)
		Enums.CoatColor.GREY:
			return Color(0.68, 0.68, 0.70)
		Enums.CoatColor.BLACK:
			return Color(0.07, 0.07, 0.08)
		_:
			return Color(0.34, 0.17, 0.08)


func _instance_model() -> Node3D:
	for path in [HORSE_FBX, HORSE_OBJ]:
		if ResourceLoader.exists(path):
			var packed = load(path)
			if packed is PackedScene:
				var n = packed.instantiate()
				if n is Node3D:
					return n
	return null


func _ensure_pick() -> void:
	if get_node_or_null("Pick") != null:
		return
	var body := StaticBody3D.new()
	body.name = "Pick"
	body.collision_layer = 1
	body.input_ray_pickable = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 2.0, 2.2)
	shape.shape = box
	shape.position = Vector3(0, 1.0, 0)
	body.add_child(shape)
	add_child(body)


func _normalize_and_plant(root: Node3D) -> void:
	var aabb := _world_aabb(root)
	if aabb.size.y < 0.01:
		return
	var s := TARGET_HEIGHT / aabb.size.y
	root.scale *= s
	aabb = _world_aabb(root)
	root.position.y -= aabb.position.y


func _world_aabb(root: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for mi in _meshes(root):
		var local := mi.get_aabb()
		var xf := mi.global_transform if mi.is_inside_tree() else root.transform * mi.transform
		var world := xf * local
		if first:
			aabb = world
			first = false
		else:
			aabb = aabb.merge(world)
	return aabb


func _play_idle() -> void:
	if _anim == null:
		return
	for name in _anim.get_animation_list():
		var l := String(name).to_lower()
		if "idle" in l or "stand" in l:
			_anim.play(name)
			if _anim.has_animation(name):
				_anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR
			return
	if _anim.get_animation_list().size() > 0:
		var first: String = _anim.get_animation_list()[0]
		_anim.play(first)


func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_anim(c)
		if found:
			return found
	return null


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out
