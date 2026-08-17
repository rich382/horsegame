extends SceneTree
## godot --headless --path . --script res://tests/run_tests.gd
## Exit 1 on first failing suite. Runs on the first frame so /root autoloads exist.

const TestCalendarWrap := preload("res://tests/test_calendar_wrap.gd")
const TestSaveMigrate := preload("res://tests/test_save_migrate.gd")
const TestBootActions := preload("res://tests/test_boot_actions.gd")
const TestHorseFactory := preload("res://tests/test_horse_factory.gd")
const TestCareSystem := preload("res://tests/test_care_system.gd")
const TestPlayerAvatar := preload("res://tests/test_player_avatar.gd")
const TestEconomy := preload("res://tests/test_economy.gd")
const TestTrainingSystem := preload("res://tests/test_training_system.gd")
const TestHorsePresenter := preload("res://tests/test_horse_presenter.gd")
const TestJumperJudge := preload("res://tests/test_jumper_judge.gd")
const TestBarnBusiness := preload("res://tests/test_barn_business.gd")

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
	fails += TestHorseFactory.run()
	fails += TestCareSystem.run()
	fails += TestPlayerAvatar.run()
	fails += TestEconomy.run()
	fails += TestTrainingSystem.run()
	fails += TestHorsePresenter.run()
	fails += TestJumperJudge.run()
	fails += TestBarnBusiness.run()
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
	_add_autoload("Economy", "res://src/autoload/economy.gd")


func _add_autoload(node_name: String, path: String) -> void:
	if root.get_node_or_null(node_name) != null:
		return
	var node: Node = load(path).new()
	node.name = node_name
	root.add_child(node)
