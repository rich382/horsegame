class_name Ids
extends RefCounted

static var _n: int = 0


static func next(prefix: String) -> String:
	_n += 1
	return "%s_%d" % [prefix, _n]


static func reset_for_tests() -> void:
	_n = 0
