extends RefCounted


static func run() -> int:
	var fails := 0
	if not ResourceLoader.exists("res://assets/models/horse/free_horse.glb"):
		push_error("horse presenter: free_horse.glb missing")
		fails += 1
	if not ResourceLoader.exists("res://assets/models/horse/Horse.fbx"):
		push_error("horse presenter: Horse.fbx missing")
		fails += 1
	var packed := load("res://scenes/horse/horse_presenter.tscn") as PackedScene
	if packed == null:
		push_error("horse presenter: scene missing")
		fails += 1
		return fails
	var n: Node = packed.instantiate()
	Engine.get_main_loop().root.add_child(n)
	if n.has_method("setup"):
		n.setup(null)
	if not n.has_method("walk_to") or not n.has_method("jump_to") or not n.has_method("is_busy"):
		push_error("horse presenter: missing walk/jump API")
		fails += 1
	elif bool(n.is_busy()):
		push_error("horse presenter: should not start busy")
		fails += 1
	else:
		var here: Vector3 = n.global_position
		if not n.walk_to(here + Vector3(3, 0, 0)):
			push_error("horse presenter: walk_to refused")
			fails += 1
		elif not bool(n.is_busy()):
			push_error("horse presenter: walk_to should be busy")
			fails += 1
	var glb = load("res://assets/models/horse/free_horse.glb")
	if glb:
		var inst: Node = glb.instantiate()
		var ap := _find_anim(inst)
		if ap == null:
			push_error("horse presenter: free_horse.glb has no AnimationPlayer")
			fails += 1
		else:
			var names := ",".join(ap.get_animation_list()).to_lower()
			if "walk" not in names or "idle" not in names or "jump" not in names:
				push_error("horse presenter: free_horse missing walk/idle/jump (%s)" % names)
				fails += 1
		inst.free()
	var fbx = load("res://assets/models/horse/Horse.fbx")
	if fbx:
		var inst: Node = fbx.instantiate()
		var ap := _find_anim(inst)
		if ap == null:
			push_error("horse presenter: FBX has no AnimationPlayer")
			fails += 1
		else:
			var names := ",".join(ap.get_animation_list()).to_lower()
			if "walk" not in names or "idle" not in names or "jump" not in names:
				push_error("horse presenter: FBX missing walk/idle/jump (%s)" % names)
				fails += 1
		inst.free()
	n.queue_free()
	if fails == 0:
		print("test_horse_presenter: ok")
	return fails


static func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_anim(c)
		if found:
			return found
	return null
