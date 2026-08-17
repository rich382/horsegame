extends RefCounted

const Enums := preload("res://src/core/enums.gd")

var fence_index: int = 0
var decision: int = Enums.Approach.STAY
var spot: float = 0.0
var rail: bool = false
var refusal: bool = false
var runout: bool = false
var rub: bool = false
var swap: bool = false
var break_gait: bool = false
var fall: bool = false
var time_delta: float = 0.0
var planned_leg: float = 0.0
var actual_leg: float = 0.0
var p_disob: float = 0.0
var p_rail: float = 0.0
var p_refuse: float = 0.0
var scope_margin: float = 0.0
var finish_leg: bool = false


func line() -> String:
	if finish_leg:
		return "Home — through the timers."
	var n := fence_index + 1
	if fall:
		return "Fence %d — fall. That's the whistle." % n
	if refusal:
		return "Fence %d — refusal." % n
	if runout:
		return "Fence %d — runout." % n
	if rail:
		return "Fence %d — rail." % n
	if rub:
		return "Fence %d — rub, stays up." % n
	return "Fence %d — clear." % n


func to_dict() -> Dictionary:
	return {
		"fence_index": fence_index,
		"decision": decision,
		"spot": spot,
		"rail": rail,
		"refusal": refusal,
		"runout": runout,
		"rub": rub,
		"swap": swap,
		"break_gait": break_gait,
		"fall": fall,
		"time_delta": time_delta,
		"planned_leg": planned_leg,
		"actual_leg": actual_leg,
		"p_disob": p_disob,
		"p_rail": p_rail,
	}
