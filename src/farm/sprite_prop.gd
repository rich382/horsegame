class_name SpriteProp
extends RefCounted
## Imagine-painted cutouts as Y-billboard Sprite3Ds.


static func make(tex: Texture2D, height_m: float, sink: float = 0.0) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = height_m / float(tex.get_height())
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = true
	s.double_sided = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	s.alpha_scissor_threshold = 0.45
	## Centered sprite: lift by half height, then sink so painted floors/roots meet grass.
	s.position.y = height_m * 0.5 - sink
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return s
