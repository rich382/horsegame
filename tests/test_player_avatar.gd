extends RefCounted


static func run() -> int:
	var fails := 0
	if not ResourceLoader.exists("res://assets/models/player/characters/Ranger.glb"):
		push_error("player: Ranger.glb missing")
		fails += 1
	var packed := load("res://scenes/player/player_avatar.tscn") as PackedScene
	if packed == null:
		push_error("player: avatar scene missing")
		fails += 1
	else:
		var n: Node = packed.instantiate()
		Engine.get_main_loop().root.add_child(n)
		if n.has_method("walk_to") and n.has_method("is_busy"):
			if bool(n.is_busy()):
				push_error("player: should not start busy")
				fails += 1
		else:
			push_error("player: missing walk API")
			fails += 1
		n.queue_free()
	if fails == 0:
		print("test_player_avatar: ok")
	return fails
