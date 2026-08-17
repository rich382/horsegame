extends SceneTree
## godot --headless --path . --script res://tests/run_tests.gd
## Exit 1 on first failing suite. Runs on the first frame so /root autoloads exist.

const TestCalendarWrap := preload("res://tests/test_calendar_wrap.gd")
const TestSaveMigrate := preload("res://tests/test_save_migrate.gd")
const TestBootActions := preload("res://tests/test_boot_actions.gd")

var _ran := false


func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true
	_ensure_autoloads()
	var fails := 0
	fails += TestCalendarWrap.run()
	fails += TestSaveMigrate.run()
	fails += TestBootActions.run()
	if fails > 0:
		push_error("TESTS FAILED: %d assertion(s)" % fails)
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)
	return true


func _ensure_autoloads() -> void:
	_add_autoload("EventBus", "res://src/autoload/event_bus.gd")
	_add_autoload("GameState", "res://src/autoload/game_state.gd")
	_add_autoload("GameClock", "res://src/autoload/game_clock.gd")
	_add_autoload("SaveService", "res://src/autoload/save_service.gd")


func _add_autoload(node_name: String, path: String) -> void:
	if root.get_node_or_null(node_name) != null:
		return
	var node: Node = load(path).new()
	node.name = node_name
	root.add_child(node)
