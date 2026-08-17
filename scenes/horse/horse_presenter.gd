extends Node3D
## Textured free horse (static mesh) with Quaternius FBX as animated fallback.

const Enums := preload("res://src/core/enums.gd")
const HORSE_GLB := "res://assets/models/horse/free_horse.glb"
const HORSE_FBX := "res://assets/models/horse/Horse.fbx"
const HORSE_OBJ := "res://assets/models/horse/Horse.obj"
const TARGET_HEIGHT := 2.05
const WALK_MPS := 3.0
const ARRIVE := 0.5
const JUMP_HEIGHT := 1.05

var _body: Node3D
var _anim: AnimationPlayer
var _goal: Vector3
var _has_goal := false
var _pending: Callable
var _jumping := false
var _jump_from: Vector3
var _jump_to: Vector3
var _jump_t := 0.0
var _jump_dur := 0.8
var _plant_y := 0.0
var _bob_t := 0.0


func is_busy() -> bool:
	return _has_goal or _jumping


func walk_to(world: Vector3, then: Callable = Callable()) -> bool:
	if _jumping:
		return false
	_goal = Vector3(world.x, global_position.y, world.z)
	_has_goal = true
	_pending = then
	set_process(true)
	return true


func jump_to(world: Vector3, then: Callable = Callable()) -> bool:
	if _jumping:
		return false
	_has_goal = false
	_jump_from = global_position
	_jump_to = Vector3(world.x, global_position.y, world.z)
	_jump_t = 0.0
	_jump_dur = _play_named("jump", false)
	if _jump_dur < 0.35:
		_jump_dur = 0.8
	_pending = then
	_jumping = true
	set_process(true)
	return true


func setup(horse) -> void:
	for c in get_children():
		c.queue_free()
	_body = _instance_model()
	if _body == null:
		return
	add_child(_body)
	_normalize_and_plant(_body)
	_plant_y = _body.position.y
	_ensure_pick()
	_anim = _find_anim(_body)
	_play_locomotion(false)
	set_process(true)
	if horse != null:
		apply_coat(int(horse.coat))


func apply_coat(coat: int) -> void:
	if _body == null:
		return
	var tint := _coat_tint(coat)
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
			mat.emission_enabled = false
			if mat.albedo_texture != null:
				mat.albedo_color = tint
			else:
				var base := mat.albedo_color
				var lum := (base.r + base.g + base.b) / 3.0
				mat.albedo_color = mane if lum < 0.12 else tint
			mi.set_surface_override_material(i, mat)


func _coat_tint(coat: int) -> Color:
	match coat:
		Enums.CoatColor.CHESTNUT:
			return Color(0.95, 0.52, 0.32)
		Enums.CoatColor.GREY:
			return Color(0.80, 0.80, 0.84)
		Enums.CoatColor.BLACK:
			return Color(0.18, 0.16, 0.16)
		_:
			return Color(1.0, 1.0, 1.0)


func _instance_model() -> Node3D:
	for path in [HORSE_GLB, HORSE_FBX, HORSE_OBJ]:
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


func _process(dt: float) -> void:
	if _jumping:
		_tick_jump(dt)
		return
	if not _has_goal:
		return
	var here := global_position
	var delta := _goal - here
	delta.y = 0.0
	var dist := delta.length()
	if dist > ARRIVE:
		var step := minf(dist, WALK_MPS * dt)
		global_position = here + delta.normalized() * step
		_face(delta)
		_play_locomotion(true)
		_bob(dt, true)
	else:
		_has_goal = false
		_play_locomotion(false)
		_bob(dt, false)
		_finish()


func _tick_jump(dt: float) -> void:
	_jump_t += dt
	var a := clampf(_jump_t / _jump_dur, 0.0, 1.0)
	var p := _jump_from.lerp(_jump_to, a)
	p.y = _jump_from.y + JUMP_HEIGHT * sin(PI * a)
	global_position = p
	_face(_jump_to - _jump_from)
	if a >= 1.0:
		_jumping = false
		global_position = _jump_to
		_play_locomotion(false)
		_finish()


func _finish() -> void:
	var then := _pending
	_pending = Callable()
	if then.is_valid():
		then.call()


func _bob(dt: float, walking: bool) -> void:
	if _body == null:
		return
	if walking and _anim == null:
		_bob_t += dt
		_body.position.y = _plant_y + 0.045 * sin(_bob_t * 10.0)
	else:
		_bob_t = 0.0
		_body.position.y = _plant_y


func _face(delta: Vector3) -> void:
	delta.y = 0.0
	if delta.length() < 0.05:
		return
	rotation.y = atan2(delta.x, delta.z)


func _play_locomotion(walking: bool) -> void:
	_play_named("walk" if walking else "idle", true)


func _play_named(want: String, loop: bool) -> float:
	if _anim == null:
		return 0.0
	var clip := _find_clip(want)
	if clip == "":
		return 0.0
	if _anim.has_animation(clip):
		var a := _anim.get_animation(clip)
		a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
		if _anim.current_animation != clip:
			_anim.play(clip, 0.12)
		_anim.speed_scale = 1.15 if want == "walk" else 1.0
		return a.length
	return 0.0


func _find_clip(want: String) -> String:
	if _anim == null:
		return ""
	var fallback := ""
	for name in _anim.get_animation_list():
		var l := String(name).to_lower()
		if want == "walk":
			if "walkslow" in l:
				continue
			if "walk" in l:
				return name
		elif want == "jump":
			if "jump" in l:
				return name
		elif want == "idle":
			if "idle" in l or "stand" in l:
				return name
		if fallback == "" and _anim.get_animation_list().size() > 0:
			fallback = name
	return fallback


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
