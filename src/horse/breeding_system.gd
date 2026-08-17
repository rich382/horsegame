extends RefCounted
## Two-allele pick. Gestation is 21 game days.

const Enums := preload("res://src/core/enums.gd")
const HorseFactoryScript := preload("res://src/horse/horse_factory.gd")
const HorseGenomeScript := preload("res://src/horse/horse_genome.gd")
const GenePairScript := preload("res://src/horse/gene_pair.gd")

const GESTATION := 21
const STUD_FEE := 250
const FOAL_NAMES := ["Pippin", "Lark", "Bracken", "Soot", "Quill", "Moth", "Ada"]


static func can_breed(dam, sire) -> String:
	if dam == null or sire == null:
		return "Need two horses."
	if dam == sire:
		return "That's the same horse."
	if int(dam.sex) != Enums.Sex.MARE:
		return "The dam has to be a mare."
	if int(sire.sex) != Enums.Sex.STALLION:
		return "The sire has to be a stallion."
	if bool(dam.in_foal):
		return "%s is already in foal." % dam.name
	if int(dam.age_months) < 48:
		return "She's too young."
	return ""


static func cover(dam, sire, abs_d: int) -> String:
	var why := can_breed(dam, sire)
	if why != "":
		return why
	dam.in_foal = true
	dam.foal_due_abs = abs_d + GESTATION
	dam.sire_name = String(sire.name)
	dam.pending_sire_coat = int(sire.coat)
	dam.pending_sire_pairs = {}
	if sire.genome:
		for k in HorseGenomeScript.KEYS:
			var p = sire.genome.pairs.get(k, null)
			if p:
				dam.pending_sire_pairs[String(k)] = [float(p.allele_a), float(p.allele_b)]
	return "%s is in foal to %s. Due in %d days." % [dam.name, sire.name, GESTATION]


static func tick(data, rng) -> PackedStringArray:
	var notes := PackedStringArray()
	if data == null:
		return notes
	var abs_d: int = data.clock.abs_day()
	var born: Array = []
	for h in data.horses:
		if h == null or not bool(h.in_foal):
			continue
		if abs_d < int(h.foal_due_abs):
			continue
		var foal = drop_foal(h, rng)
		if foal:
			born.append({"dam": h, "foal": foal})
	for row in born:
		var dam = row["dam"]
		var foal = row["foal"]
		dam.in_foal = false
		dam.foal_due_abs = -1
		var stall_id := _free_stall(data)
		if stall_id == "":
			notes.append("%s foaled, but there's no stall. Sold the weanling on." % dam.name)
			continue
		foal.stall_id = StringName(stall_id)
		_occupy(data, stall_id, foal.uid)
		data.horses.append(foal)
		notes.append("%s foaled. %s is on the ground." % [dam.name, foal.name])
	return notes


static func drop_foal(dam, rng):
	var h = HorseFactoryScript.make_prospect(rng)
	h.age_months = 0
	h.def_id = &"homebred"
	h.jumper_schooling = 8.0
	h.hunter_schooling = 8.0
	h.gymnastics = 12.0
	h.flatwork = 18.0
	h.schooled_height_m = 0.50
	h.fitness = 40.0
	h.energy = 90.0
	h.hunger = 80.0
	if rng:
		h.name = FOAL_NAMES[rng.randi_range(0, FOAL_NAMES.size() - 1)]
		h.sex = Enums.Sex.MARE if rng.randf() < 0.5 else Enums.Sex.STALLION
	h.barn_name = h.name.substr(0, mini(8, h.name.length()))
	var sire_g = _sire_genome(dam)
	if dam.genome:
		h.genome = _mix(dam.genome, sire_g, rng)
		if h.genome:
			h.coat = h.genome.coat
			for k in HorseGenomeScript.KEYS:
				if h.genome.pairs.has(k):
					var pair = h.genome.pairs[k]
					var noise := 0.0
					if rng:
						noise = rng.randfn(0.0, 2.0)
					h.set(String(k), clampf(pair.mid() + noise, 0.0, 100.0))
	dam.pending_sire_pairs = {}
	return h


static func _sire_genome(dam):
	if dam.pending_sire_pairs.is_empty():
		return dam.genome
	var g = HorseGenomeScript.new()
	g.coat = int(dam.pending_sire_coat)
	for k in HorseGenomeScript.KEYS:
		var pair = GenePairScript.new()
		var ab: Array = dam.pending_sire_pairs.get(String(k), [50.0, 50.0])
		pair.allele_a = float(ab[0])
		pair.allele_b = float(ab[1])
		g.pairs[k] = pair
	return g


static func _mix(dam_g, sire_g, rng):
	var g = HorseGenomeScript.new()
	g.coat = dam_g.coat
	if rng and rng.randf() < 0.5 and sire_g:
		g.coat = sire_g.coat
	for k in HorseGenomeScript.KEYS:
		var pair = GenePairScript.new()
		var dp = dam_g.pairs.get(k, null)
		var sp = sire_g.pairs.get(k, dp) if sire_g else dp
		pair.allele_a = _pick(dp, rng)
		pair.allele_b = _pick(sp, rng)
		g.pairs[k] = pair
	return g


static func _pick(pair, rng) -> float:
	if pair == null:
		return 50.0
	if rng and rng.randf() < 0.5:
		return float(pair.allele_b)
	return float(pair.allele_a)


static func _free_stall(data) -> String:
	for s in data.farm.get("stalls", []):
		if String(s.get("occupant_uid", "")) == "" and String(s.get("boarder", "")) == "":
			return String(s.get("id", ""))
	return ""


static func _occupy(data, stall_id: String, uid: String) -> void:
	for s in data.farm.get("stalls", []):
		if String(s.get("id", "")) == stall_id:
			s["occupant_uid"] = uid
			return
