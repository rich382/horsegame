extends SceneTree


func _initialize() -> void:
	var packed = load("res://assets/models/horse/horse_rigged.glb")
	if packed == null:
		push_error("failed to load horse_rigged.glb")
		quit(1)
		return
	var n: Node = packed.instantiate()
	_walk(n, "")
	quit(0)


func _walk(n: Node, indent: String) -> void:
	print("%s%s (%s)" % [indent, n.name, n.get_class()])
	if n is AnimationPlayer:
		print("%s  clips: %s" % [indent, str(n.get_animation_list())])
	if n is MeshInstance3D:
		print("%s  mesh=%s" % [indent, str((n as MeshInstance3D).mesh)])
	for c in n.get_children():
		_walk(c, indent + "  ")
