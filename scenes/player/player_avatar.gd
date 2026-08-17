extends Node3D
## Owner-rider on the farm. Walks to a chore, plays a tool clip, then finishes.

const BODY := "res://assets/models/player/characters/Ranger.glb"
const ANIM_FILES := [
	"res://assets/models/player/anims/extra_Rig_Medium_General.glb",
	"res://assets/models/player/anims/extra_Rig_Medium_MovementBasic.glb",
	"res://assets/models/player/anims/extra_Rig_Medium_Tools.glb",
]
const LIB := "kk"
const WALK := "Walking_A"
const IDLE := "Idle_A"
const TARGET_HEIGHT := 1.72
const WALK_MPS := 3.2
const ARRIVE := 0.45

signal chore_arrived
signal chore_finished

var _anim: AnimationPlayer
var _goal: Vector3
var _has_goal := false
var _busy := false
var _pending: Callable
var _action_clip := ""


func _ready() -> void:
	_spawn()
	_goal = global_position
	set_process(true)


func is_busy() -> bool:
	return _busy


func walk_to(world: Vector3, then: Callable = Callable()) -> bool:
	if _busy:
		return false
	_goal = Vector3(world.x, global_position.y, world.z)
	_has_goal = true
	_pending = then
	_action_clip = ""
	return true


func walk_and_do(world: Vector3, action_clip: String, then: Callable) -> bool:
	if _busy:
		return false
	_goal = Vector3(world.x, global_position.y, world.z)
	_has_goal = true
	_pending = then
	_action_clip = action_clip
	return true


func _process(dt: float) -> void:
	if not _has_goal or _busy:
		return
	var here := global_position
	var delta := _goal - here
	delta.y = 0.0
	var dist := delta.length()
	if dist > ARRIVE:
		var step := mini(dist, WALK_MPS * dt)
		global_position = here + delta.normalized() * step
		if dist > 0.05:
			var look := global_position + delta
			look_at(look, Vector3.UP)
		_play_move(true)
	else:
		_has_goal = false
		_play_move(false)
		chore_arrived.emit()
		_finish_arrival()


func _finish_arrival() -> void:
	var then := _pending
	_pending = Callable()
	if _action_clip != "":
		_busy = true
		await _play_action(_action_clip)
		_action_clip = ""
		_busy = false
	if then.is_valid():
		then.call()
	chore_finished.emit()
	_play_move(false)


func _spawn() -> void:
	if not ResourceLoader.exists(BODY):
		_fallback()
		return
	var packed := load(BODY) as PackedScene
	if packed == null:
		_fallback()
		return
	var body := packed.instantiate() as Node3D
	add_child(body)
	_fit(body)
	body.rotation_degrees.y = 180.0
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	body.add_child(player)
	var lib := _build_lib()
	if lib:
		player.add_animation_library(LIB, lib)
		player.root_node = player.get_path_to(body)
	_anim = player
	_play_move(false)


func _build_lib() -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	var found := 0
	for path in ANIM_FILES:
		if not ResourceLoader.exists(path):
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var inst := packed.instantiate()
		var ap := _find_anim(inst)
		if ap:
			for clip_name in ap.get_animation_list():
				if lib.has_animation(clip_name):
					continue
				var a := ap.get_animation(clip_name)
				if a:
					lib.add_animation(clip_name, a)
					found += 1
		inst.free()
	return lib if found > 0 else null


func _play_move(walking: bool) -> void:
	if _anim == null:
		return
	var clip := WALK if walking else IDLE
	var full := "%s/%s" % [LIB, clip]
	if not _anim.has_animation(full):
		return
	if _anim.current_animation != full:
		_anim.play(full, 0.12)
	if walking:
		_anim.speed_scale = clampf(WALK_MPS / 0.56, 0.9, 2.4)
	else:
		_anim.speed_scale = 1.0


func _play_action(clip: String) -> void:
	if _anim == null:
		await get_tree().create_timer(0.6).timeout
		return
	var full := "%s/%s" % [LIB, clip]
	if not _anim.has_animation(full):
		await get_tree().create_timer(0.7).timeout
		return
	var a := _anim.get_animation(full)
	_anim.play(full, 0.1)
	_anim.speed_scale = 1.0
	await get_tree().create_timer(maxf(0.45, a.length)).timeout


func _fit(body: Node3D) -> void:
	var aabb := AABB()
	var first := true
	for mi in _meshes(body):
		var local := mi.get_aabb()
		var world := body.transform * mi.transform * local
		if first:
			aabb = world
			first = false
		else:
			aabb = aabb.merge(world)
	if first or aabb.size.y < 0.01:
		return
	var s := TARGET_HEIGHT / aabb.size.y
	body.scale *= s
	aabb = AABB(aabb.position * s, aabb.size * s)
	body.position.y -= aabb.position.y


func _fallback() -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.22
	mesh.height = 1.6
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position.y = 0.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.38, 0.30)
	inst.material_override = mat
	add_child(inst)


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


func pick_action_clip() -> String:
	if _anim == null:
		return ""
	for name in ["Interact", "Pickup", "Gathering", "Use_Item", "Digging"]:
		if _anim.has_animation("%s/%s" % [LIB, name]):
			return name
	return ""
