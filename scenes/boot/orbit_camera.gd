extends Camera3D
## Left-drag orbits. Wheel zooms. Always looks at the farm yard.

var _yaw := 0.55
var _pitch := -0.48
var _dist := 20.0
var _dragging := false
var target := Vector3(0.0, 0.6, 0.0)


func _ready() -> void:
	current = true
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = maxf(8.0, _dist - 1.6)
			_apply()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = minf(42.0, _dist + 1.6)
			_apply()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * 0.006
		_pitch = clampf(_pitch - mm.relative.y * 0.006, -1.15, -0.12)
		_apply()
		get_viewport().set_input_as_handled()


func _apply() -> void:
	var offset := Vector3(
		_dist * cos(_pitch) * sin(_yaw),
		_dist * -sin(_pitch),
		_dist * cos(_pitch) * cos(_yaw)
	)
	global_position = target + offset
	look_at(target, Vector3.UP)
