class_name HorseGenome
extends Resource

const KEYS: Array[StringName] = [
	&"scope", &"carefulness", &"style", &"rideability", &"bravery",
	&"speed", &"stride", &"lead_changes", &"movement", &"conformation",
]

@export var pairs: Dictionary = {}
@export var coat: int = 0
@export var color_alleles: Dictionary = {}


static func from_pair_table(table: Dictionary, coat_value: int) -> HorseGenome:
	var g := HorseGenome.new()
	g.coat = coat_value
	for k in KEYS:
		var pair := GenePair.new()
		var ab: Array = table.get(String(k), [50.0, 50.0])
		pair.allele_a = float(ab[0])
		pair.allele_b = float(ab[1])
		g.pairs[k] = pair
	return g
