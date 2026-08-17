class_name HorseState
extends Resource

@export var uid: String = ""
@export var def_id: StringName = &""
@export var name: String = "Bayberry"
@export var barn_name: String = "Bay"
@export var breed: int = 1
@export var sex: int = 2
@export var height_hands: float = 16.2
@export var age_months: int = 120
@export var coat: int = 0
@export var markings: PackedStringArray = ["star"]
@export var papers: bool = true
@export var registry_flavor: String = ""
@export var scope: float = 56.0
@export var carefulness: float = 62.0
@export var style: float = 58.0
@export var rideability: float = 64.0
@export var bravery: float = 55.0
@export var speed: float = 48.0
@export var stride: float = 52.0
@export var lead_changes: float = 50.0
@export var movement: float = 54.0
@export var conformation: float = 60.0
@export var temperament: int = 0
@export var fitness: float = 62.0
@export var soundness: float = 88.0
@export var energy: float = 80.0
@export var hunger: float = 85.0
@export var happiness: float = 70.0
@export var cleanliness: float = 65.0
@export var weight: float = 5.2
@export var hoof: float = 80.0
@export var turnout_score: float = 40.0
@export var flatwork: float = 55.0
@export var gymnastics: float = 48.0
@export var hunter_schooling: float = 40.0
@export var jumper_schooling: float = 42.0
@export var schooled_height_m: float = 0.85
@export var shows_at_height_mm: Dictionary = {}
@export var overwork: float = 0.0
@export var phase_busy: bool = false
@export var fed_morning: bool = false
@export var fed_evening: bool = false
@export var picked_stall_today: bool = false
@export var turned_out: bool = false
@export var at_arena: bool = false
@export var schooled_today: bool = false
@export var last_farrier_abs_day: int = -4
@export var dull_mornings: int = 0
@export var stall_id: StringName = &"stall_0"
@export var tack: Dictionary = {}
@export var injuries: Array = []
@export var genome: HorseGenome
@export var records: Array = []
@export var in_foal: bool = false
@export var foal_due_abs: int = -1
@export var sire_name: String = ""
@export var pending_sire_pairs: Dictionary = {}
@export var pending_sire_coat: int = 0


func to_dict() -> Dictionary:
	return {
		"uid": uid,
		"def_id": String(def_id),
		"name": name,
		"barn_name": barn_name,
		"breed": breed,
		"sex": sex,
		"height_hands": height_hands,
		"age_months": age_months,
		"coat": coat,
		"markings": Array(markings),
		"papers": papers,
		"registry_flavor": registry_flavor,
		"scope": scope,
		"carefulness": carefulness,
		"style": style,
		"rideability": rideability,
		"bravery": bravery,
		"speed": speed,
		"stride": stride,
		"lead_changes": lead_changes,
		"movement": movement,
		"conformation": conformation,
		"temperament": temperament,
		"fitness": fitness,
		"soundness": soundness,
		"energy": energy,
		"hunger": hunger,
		"happiness": happiness,
		"cleanliness": cleanliness,
		"weight": weight,
		"hoof": hoof,
		"turnout_score": turnout_score,
		"flatwork": flatwork,
		"gymnastics": gymnastics,
		"hunter_schooling": hunter_schooling,
		"jumper_schooling": jumper_schooling,
		"schooled_height_m": schooled_height_m,
		"shows_at_height_mm": shows_at_height_mm.duplicate(true),
		"overwork": overwork,
		"phase_busy": phase_busy,
		"fed_morning": fed_morning,
		"fed_evening": fed_evening,
		"picked_stall_today": picked_stall_today,
		"turned_out": turned_out,
		"at_arena": at_arena,
		"schooled_today": schooled_today,
		"last_farrier_abs_day": last_farrier_abs_day,
		"dull_mornings": dull_mornings,
		"stall_id": String(stall_id),
		"tack": tack.duplicate(true),
		"injuries": injuries.duplicate(true),
		"genome": _genome_to_dict(),
		"records": records.duplicate(true),
		"in_foal": in_foal,
		"foal_due_abs": foal_due_abs,
		"sire_name": sire_name,
		"pending_sire_pairs": pending_sire_pairs.duplicate(true),
		"pending_sire_coat": pending_sire_coat,
	}


static func from_dict(d: Dictionary):
	var h := new()
	if d.is_empty():
		return h
	h.uid = String(d.get("uid", ""))
	h.def_id = StringName(String(d.get("def_id", "")))
	h.name = String(d.get("name", "Bayberry"))
	h.barn_name = String(d.get("barn_name", "Bay"))
	h.breed = int(d.get("breed", 1))
	h.sex = int(d.get("sex", 2))
	h.height_hands = float(d.get("height_hands", 16.2))
	h.age_months = int(d.get("age_months", 120))
	h.coat = int(d.get("coat", 0))
	var marks: Array = d.get("markings", ["star"])
	h.markings = PackedStringArray()
	for m in marks:
		h.markings.append(String(m))
	h.papers = bool(d.get("papers", true))
	h.registry_flavor = String(d.get("registry_flavor", ""))
	for key in [
		"scope", "carefulness", "style", "rideability", "bravery", "speed",
		"stride", "lead_changes", "movement", "conformation", "fitness",
		"soundness", "energy", "hunger", "happiness", "cleanliness", "weight",
		"hoof", "turnout_score", "flatwork", "gymnastics", "hunter_schooling",
		"jumper_schooling", "schooled_height_m", "overwork",
	]:
		if d.has(key):
			h.set(key, float(d[key]))
	h.temperament = int(d.get("temperament", 0))
	h.shows_at_height_mm = d.get("shows_at_height_mm", {})
	h.phase_busy = bool(d.get("phase_busy", false))
	h.fed_morning = bool(d.get("fed_morning", false))
	h.fed_evening = bool(d.get("fed_evening", false))
	h.picked_stall_today = bool(d.get("picked_stall_today", false))
	h.turned_out = bool(d.get("turned_out", false))
	h.at_arena = bool(d.get("at_arena", false))
	h.schooled_today = bool(d.get("schooled_today", false))
	h.last_farrier_abs_day = int(d.get("last_farrier_abs_day", -4))
	h.dull_mornings = int(d.get("dull_mornings", 0))
	h.stall_id = StringName(String(d.get("stall_id", "stall_0")))
	h.tack = d.get("tack", {})
	h.injuries = d.get("injuries", [])
	h.genome = _genome_from_dict(d.get("genome", {}))
	h.records = d.get("records", [])
	h.in_foal = bool(d.get("in_foal", false))
	h.foal_due_abs = int(d.get("foal_due_abs", -1))
	h.sire_name = String(d.get("sire_name", ""))
	h.pending_sire_pairs = d.get("pending_sire_pairs", {})
	h.pending_sire_coat = int(d.get("pending_sire_coat", 0))
	return h


func _genome_to_dict() -> Dictionary:
	if genome == null:
		return {}
	var pairs := {}
	for k in HorseGenome.KEYS:
		var p = genome.pairs.get(k)
		if p == null:
			continue
		pairs[String(k)] = [float(p.allele_a), float(p.allele_b)]
	return {
		"coat": genome.coat,
		"pairs": pairs,
		"color_alleles": genome.color_alleles.duplicate(true),
	}


static func _genome_from_dict(d: Dictionary):
	if d.is_empty():
		return null
	var table: Dictionary = {}
	var pairs: Dictionary = d.get("pairs", {})
	for k in pairs.keys():
		table[String(k)] = pairs[k]
	var g = HorseGenome.from_pair_table(table, int(d.get("coat", 0)))
	g.color_alleles = d.get("color_alleles", {})
	return g
