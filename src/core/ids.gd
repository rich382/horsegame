class_name Ids
extends RefCounted

static var _n: int = 0


static func next(prefix: String) -> String:
	_n += 1
	return "%s_%d" % [prefix, _n]


static func uuid() -> String:
	## OS entropy, not the sim rng.
	return "h_%s" % str(Time.get_unix_time_from_system()).sha256_text().substr(0, 10)


static func reset_for_tests() -> void:
	_n = 0
