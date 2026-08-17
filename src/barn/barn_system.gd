extends RefCounted
## Boarders, empty stalls, and haul-for-hire. Real barn-people work.

const BOARDER_RATE := 160
const BOARDER_NAMES := [
	{"name": "Pip", "owner": "Chen"},
	{"name": "Moose", "owner": "Hale"},
	{"name": "Clover", "owner": "Diaz"},
	{"name": "Juniper", "owner": "Walsh"},
	{"name": "Nudge", "owner": "Patel"},
	{"name": "Biscuit", "owner": "Nguyen"},
	{"name": "Maple", "owner": "Brooks"},
]

const HAUL_JOBS := [
	{"id": "vet_run", "label": "Vet run — neighbor's pony", "pay": 95},
	{"id": "lesson_drop", "label": "Pony-club drop-off", "pay": 80},
	{"id": "clinic_haul", "label": "Clinic haul, two horses", "pay": 160},
	{"id": "local_show", "label": "Local schooling — one in, one home", "pay": 130},
]


static func empty_stalls(farm: Dictionary) -> Array:
	var out: Array = []
	for s in farm.get("stalls", []):
		if String(s.get("occupant_uid", "")) == "" and String(s.get("boarder", "")) == "":
			out.append(s)
	return out


static func boarder_count(farm: Dictionary) -> int:
	return farm.get("boarders", []).size()


static func stall_count(farm: Dictionary) -> int:
	return farm.get("stalls", []).size()


static func has_rig(farm: Dictionary) -> bool:
	return bool(farm.get("has_truck", false)) and bool(farm.get("has_trailer", false))


static func take_boarder(data) -> String:
	if data == null:
		return "No farm."
	var farm: Dictionary = data.farm
	var free: Array = empty_stalls(farm)
	if free.is_empty():
		return "No empty stall. Build the next barn wing."
	var taken: Dictionary = {}
	for b in farm.get("boarders", []):
		taken[String(b.get("name", ""))] = true
	var pick = null
	for row in BOARDER_NAMES:
		if not taken.has(String(row["name"])):
			pick = row
			break
	if pick == null:
		return "The waiting list is empty this week."
	var stall: Dictionary = free[0]
	var abs_d: int = data.clock.abs_day()
	var boarder := {
		"name": pick["name"],
		"owner": pick["owner"],
		"stall_id": String(stall.get("id", "")),
		"rate": BOARDER_RATE,
		"arrived_abs": abs_d,
		"last_paid_abs": abs_d,
	}
	stall["boarder"] = pick["name"]
	var list: Array = farm.get("boarders", [])
	list.append(boarder)
	farm["boarders"] = list
	return "%s is in %s. %s pays $%d a week." % [pick["name"], stall["id"], pick["owner"], BOARDER_RATE]


static func due_board(farm: Dictionary, abs_d: int) -> int:
	var total := 0
	for b in farm.get("boarders", []):
		if abs_d - int(b.get("last_paid_abs", 0)) >= 7:
			total += int(b.get("rate", BOARDER_RATE))
	return total


static func mark_board_paid(farm: Dictionary, abs_d: int) -> int:
	var total := 0
	for b in farm.get("boarders", []):
		if abs_d - int(b.get("last_paid_abs", 0)) >= 7:
			total += int(b.get("rate", BOARDER_RATE))
			b["last_paid_abs"] = abs_d
	return total


static func haul_blocked(data) -> String:
	if data == null or data.farm == null:
		return "No farm."
	if not has_rig(data.farm):
		return "Need a truck and a trailer first."
	var abs_d: int = data.clock.abs_day()
	if abs_d == int(data.farm.get("last_haul_abs_day", -99)):
		return "Already hauled today. Don't cook the diesel."
	return ""


static func job_by_id(job_id: String) -> Dictionary:
	for j in HAUL_JOBS:
		if String(j["id"]) == job_id:
			return j
	return {}
