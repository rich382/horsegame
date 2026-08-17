extends Node3D
## Imagine-painted horse cutout. Coat swaps the texture.

const Enums := preload("res://src/core/enums.gd")

const SPRITES := {
	Enums.CoatColor.BAY: preload("res://assets/sprites/horse_bay.png"),
	Enums.CoatColor.CHESTNUT: preload("res://assets/sprites/horse_chestnut.png"),
	Enums.CoatColor.GREY: preload("res://assets/sprites/horse_grey.png"),
	Enums.CoatColor.BLACK: preload("res://assets/sprites/horse_black.png"),
}

var _sprite: Sprite3D


func setup(horse) -> void:
	for c in get_children():
		c.queue_free()
	var coat := Enums.CoatColor.BAY
	if horse != null:
		coat = int(horse.coat)
	apply_coat(coat)


func apply_coat(coat: int) -> void:
	var tex: Texture2D = SPRITES.get(coat, SPRITES[Enums.CoatColor.BAY])
	if _sprite and is_instance_valid(_sprite):
		_sprite.queue_free()
	_sprite = SpriteProp.make(tex, 2.15)
	add_child(_sprite)
