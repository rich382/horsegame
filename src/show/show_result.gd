extends Resource

@export var horse_uid: String = ""
@export var class_id: StringName = &""
@export var faults: int = 0
@export var time_sec: float = 0.0
@export var score: float = -1.0
@export var eliminated: bool = false
@export var placing: int = 0
@export var prize: int = 0
@export var comment: String = ""
@export var jo_faults: int = -1
@export var jo_time_sec: float = -1.0
@export var events: Array = []


func recap_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for e in events:
		if e == null:
			continue
		if e.finish_leg:
			continue
		lines.append(e.line())
	if eliminated:
		lines.append("Eliminated.")
	else:
		lines.append("%d faults." % faults)
	if comment != "":
		lines.append(comment)
	return lines
