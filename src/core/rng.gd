class_name Rng
extends RefCounted
## Single sim stream. Presenters, HUD, and F3 must never call this.

var _rng: RandomNumberGenerator
var seed: int
var call_count: int = 0


func reset(p_seed: int, p_calls: int) -> void:
	seed = p_seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = p_seed
	call_count = 0
	for _i in p_calls:
		_rng.randf()
		call_count += 1


func randf() -> float:
	call_count += 1
	return _rng.randf()


func randfn(mean: float, sigma: float) -> float:
	call_count += 1
	return _rng.randfn(mean, sigma)


func randf_range(from: float, to: float) -> float:
	call_count += 1
	return _rng.randf_range(from, to)


func randi_range(from: int, to: int) -> int:
	call_count += 1
	return _rng.randi_range(from, to)
