class_name GenePair
extends Resource

@export var allele_a: float = 50.0
@export var allele_b: float = 50.0


func mid() -> float:
	return 0.5 * (allele_a + allele_b)
