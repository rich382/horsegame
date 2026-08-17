extends RefCounted

var scope_mod: float = 0.0
var care_mod: float = 0.0
var style_mod: float = 0.0
var speed_mod: float = 0.0


static func from_horse(horse):
	var m = new()
	if horse == null:
		return m
	var tack: Dictionary = horse.tack if horse.tack else {}
	m.scope_mod = float(tack.get("scope_mod", 0.0))
	m.care_mod = float(tack.get("care_mod", 0.0))
	m.style_mod = float(tack.get("style_mod", 0.0))
	m.speed_mod = float(tack.get("speed_mod", 0.0))
	return m
