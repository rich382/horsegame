class_name HorseFactory
extends RefCounted

const Enums := preload("res://src/core/enums.gd")

const STARTER_COATS: Array[int] = [
	Enums.CoatColor.BAY,
	Enums.CoatColor.CHESTNUT,
	Enums.CoatColor.GREY,
	Enums.CoatColor.BLACK,
]

const BAYBERRY_PAIRS := {
	"scope": [54.0, 58.0],
	"carefulness": [60.0, 64.0],
	"style": [56.0, 60.0],
	"rideability": [62.0, 66.0],
	"bravery": [52.0, 58.0],
	"speed": [46.0, 50.0],
	"stride": [50.0, 54.0],
	"lead_changes": [48.0, 52.0],
	"movement": [52.0, 56.0],
	"conformation": [58.0, 62.0],
}


static func starter_def() -> HorseDef:
	var def := HorseDef.new()
	def.genome = HorseGenome.from_pair_table(BAYBERRY_PAIRS, Enums.CoatColor.BAY)
	return def


static func instantiate(def: HorseDef, rng) -> HorseState:
	var h := HorseState.new()
	h.uid = Ids.uuid()
	h.def_id = def.id
	h.name = def.display_name
	h.barn_name = def.barn_name
	h.breed = def.breed
	h.sex = def.sex
	h.height_hands = def.height_hands
	h.age_months = def.age_years * 12
	h.coat = def.coat
	h.markings = def.markings.duplicate()
	h.papers = def.papers
	h.registry_flavor = def.registry_flavor
	h.temperament = def.temperament
	h.genome = def.genome.duplicate(true) if def.genome else HorseGenome.from_pair_table(BAYBERRY_PAIRS, def.coat)
	var sigma := def.express_sigma
	for k in HorseGenome.KEYS:
		var pair: GenePair = h.genome.pairs[k]
		var noise := 0.0
		if sigma > 0.0 and rng != null:
			noise = rng.randfn(0.0, sigma)
		h.set(String(k), clampf(pair.mid() + noise, 0.0, 100.0))
	h.fitness = def.start_fitness
	h.soundness = def.start_soundness
	h.flatwork = def.start_flatwork
	h.gymnastics = def.start_gymnastics
	h.hunter_schooling = def.start_hunter_schooling
	h.jumper_schooling = def.start_jumper_schooling
	h.schooled_height_m = def.start_schooled_height_m
	h.hunger = 85.0
	h.energy = 80.0
	h.hoof = 80.0
	h.happiness = 70.0
	h.cleanliness = 65.0
	h.turnout_score = 40.0
	h.weight = 5.2
	h.last_farrier_abs_day = -4
	h.stall_id = &"stall_0"
	return h


static func apply_player_identity(h: HorseState, horse_name: String, coat: int) -> void:
	var n := horse_name.strip_edges()
	h.name = n if not n.is_empty() else "Bayberry"
	h.barn_name = h.name.substr(0, mini(8, h.name.length()))
	if not STARTER_COATS.has(coat):
		coat = Enums.CoatColor.BAY
	h.coat = coat
	if h.genome:
		h.genome.coat = coat
	h.markings = PackedStringArray(["star"])
