extends RefCounted
## Scripted stream for resolver oracles. Not the sim Rng.

var fn_vals: Array = []
var f_vals: Array = []
var range_vals: Array = []
var fn_i: int = 0
var f_i: int = 0
var range_i: int = 0
var call_count: int = 0


func randfn(_mean: float, _sigma: float) -> float:
	call_count += 1
	if fn_i < fn_vals.size():
		var v: float = float(fn_vals[fn_i])
		fn_i += 1
		return v
	return 0.0


func randf() -> float:
	call_count += 1
	if f_i < f_vals.size():
		var v: float = float(f_vals[f_i])
		f_i += 1
		return v
	return 0.99


func randf_range(from: float, _to: float) -> float:
	call_count += 1
	if range_i < range_vals.size():
		var v: float = float(range_vals[range_i])
		range_i += 1
		return v
	return from
