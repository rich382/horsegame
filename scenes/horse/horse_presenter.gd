extends Node3D
## Instances the Quaternius CC0 horse and tints the body for the chosen coat.

const HORSE_FBX := "res://assets/models/horse/Horse.fbx"
const HORSE_OBJ := "res://assets/models/horse/Horse.obj"
const Enums := preload("res://src/core/enums.gd")

var _body: Node3D


func setup(horse) -> void:
	for c in get_children():
		c.queue_free()
	_body = _instance_model()
	if _body == null:
		_body = _fallback_capsule()
		add_child(_body)
	else:
		add_child(_body)
		_normalize_height(_body, 2.05)
		_try_play_idle(_body)
	if horse != null:
		apply_coat(int(horse.coat))


func apply_coat(coat: int) -> void:
	var body_color := _coat_color(coat)
	var mane := Color(0.07, 0.06, 0.05)
	if coat == Enums.CoatColor.GREY:
		mane = Color(0.78, 0.78, 0.80)
	elif coat == Enums.CoatColor.CHESTNUT:
		mane = Color(0.18, 0.08, 0.04)
	_tint_meshes(self, body_color, mane)


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
			elif packed is Mesh:
				var inst := MeshInstance3D.new()
				inst.mesh = packed
				return inst
	return null


func _fallback_capsule() -> Node3D:
	var root := Node3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.6
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.rotation.x = PI * 0.5
	inst.position.y = 0.7
	root.add_child(inst)
	return root


func _normalize_height(root: Node3D, target_y: float) -> void:
	var aabb := AABB()
	var first := true
	for mi in _meshes(root):
		var local := mi.get_aabb()
		var world := mi.global_transform * local
		if first:
			aabb = world
			first = false
		else:
			aabb = aabb.merge(world)
	if first or aabb.size.y < 0.01:
		return
	var s := target_y / aabb.size.y
	root.scale = root.scale * s
	root.position.y -= aabb.position.y * s


func _try_play_idle(root: Node) -> void:
	var ap := _find_anim(root)
	if ap == null:
		return
	for name in ap.get_animation_list():
		var l := String(name).to_lower()
		if "idle" in l or "stand" in l:
			ap.play(name)
			return
	if ap.get_animation_list().size() > 0:
		ap.play(ap.get_animation_list()[0])


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


func _tint_meshes(n: Node, body_color: Color, mane_color: Color) -> void:
	for mi in _meshes(n):
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
			mat.albedo_color = mane_color if lum < 0.12 else body_color
			mi.set_surface_override_material(i, mat)
