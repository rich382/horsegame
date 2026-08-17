class_name HorseDef
extends Resource

@export var id: StringName = &"starter_bayberry"
@export var display_name: String = "Bayberry"
@export var barn_name: String = "Bay"
@export var breed: int = 1
@export var sex: int = 2
@export var height_hands: float = 16.2
@export var age_years: int = 10
@export var coat: int = 0
@export var markings: PackedStringArray = ["star"]
@export var genome: HorseGenome
@export var express_sigma: float = 0.0
@export var temperament: int = 0
@export var papers: bool = true
@export var registry_flavor: String = "studbook papers (fictional)"
@export var start_fitness: float = 62.0
@export var start_soundness: float = 88.0
@export var start_flatwork: float = 55.0
@export var start_gymnastics: float = 48.0
@export var start_hunter_schooling: float = 40.0
@export var start_jumper_schooling: float = 42.0
@export var start_schooled_height_m: float = 0.85
