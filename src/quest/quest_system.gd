extends RefCounted
## Slice quests. Kept tiny and readable on the HUD.

const GOALS := [
	{"id": "keep_fed", "title": "Keep them fed", "hint": "Feed three mornings."},
	{"id": "first_boarder", "title": "Fill a stall", "hint": "Take a boarder."},
	{"id": "schooling_saturday", "title": "Schooling Saturday", "hint": "Ribbon at Ashford 0.80 m."},
	{"id": "own_two", "title": "A string", "hint": "Own two horses."},
]


static func ensure(data) -> void:
	if data == null:
		return
	if not data.quests.has("fed_mornings"):
		data.quests["fed_mornings"] = 0
	if not data.quests.has("active"):
		data.quests["active"] = ["keep_fed", "first_boarder", "schooling_saturday"]
	if not data.quests.has("done"):
		data.quests["done"] = []


static func note_feed(data, horse) -> void:
	ensure(data)
	if horse and bool(horse.fed_morning):
		data.quests["fed_mornings"] = int(data.quests.get("fed_mornings", 0)) + 1
	if int(data.quests.get("fed_mornings", 0)) >= 3:
		_complete(data, "keep_fed")


static func note_boarder(data) -> void:
	ensure(data)
	if data.farm.get("boarders", []).size() > 0:
		_complete(data, "first_boarder")


static func note_ribbon(data, show_id: String, placing: int) -> void:
	ensure(data)
	if show_id == "ashford" and placing >= 1 and placing <= 6:
		_complete(data, "schooling_saturday")


static func note_string(data) -> void:
	ensure(data)
	if data.horses.size() >= 2:
		_complete(data, "own_two")


static func hud_line(data) -> String:
	ensure(data)
	var done: Array = data.quests.get("done", [])
	for g in GOALS:
		if not done.has(String(g["id"])):
			return "%s — %s" % [g["title"], g["hint"]]
	return "Slice complete. Keep building the program."


static func _complete(data, id: String) -> void:
	var done: Array = data.quests.get("done", [])
	if done.has(id):
		return
	done.append(id)
	data.quests["done"] = done
	var active: Array = data.quests.get("active", [])
	active.erase(id)
	data.quests["active"] = active
