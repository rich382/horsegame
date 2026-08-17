class_name PlayerState
extends Resource

@export var name: String = "Alex"
@export var cash: int = 10000
@export var rider_skill: float = 35.0 ## Frozen in v1.


func to_dict() -> Dictionary:
	return {"name": name, "cash": cash, "rider_skill": rider_skill}


static func from_dict(d: Dictionary) -> PlayerState:
	var p := PlayerState.new()
	p.name = String(d.get("name", "Alex"))
	p.cash = int(d.get("cash", 10000))
	p.rider_skill = float(d.get("rider_skill", 35.0))
	return p
