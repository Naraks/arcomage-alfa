class_name CurvedLabel
extends Control
## Посимвольная отрисовка изогнутого текста.

@export var text: String = "":
	set(value):
		text = value
		queue_redraw()

@export var font: Font:
	set(value):
		font = value
		queue_redraw()

@export var font_size: int = 14:
	set(value):
		font_size = value
		queue_redraw()

@export var font_color: Color = Color.BLACK
@export var font_outline_color: Color = Color(0, 0, 0, 0)
@export var outline_size: int = 0

@export_range(0.0, 60.0, 0.5) var arc_angle_degrees: float = 22.0

@export_range(0.0, 6.0, 0.25) var jitter_position: float = 0.0
@export_range(0.0, 15.0, 0.5) var jitter_rotation_degrees: float = 0.0
@export var jitter_seed: int = 12345

@export_range(0.0, 6.0, 0.25) var float_amplitude: float = 0.0
@export_range(0.1, 5.0, 0.1) var float_speed: float = 1.2

var _float_time: float = 0.0


static func compute_radius(total_width: float, arc_angle_degrees: float) -> float:
	var arc_rad := deg_to_rad(arc_angle_degrees)
	if arc_rad < 0.001 or total_width <= 0.0:
		return 0.0
	return total_width / arc_rad


static func compute_char_placements(
	widths: Array[float], radius: float, circle_center: Vector2
) -> Array[Dictionary]:
	var total_width := 0.0
	for w in widths:
		total_width += w

	var placements: Array[Dictionary] = []
	var cursor := 0.0
	for w in widths:
		var char_mid := cursor + w / 2.0
		var theta := 0.0
		if radius > 0.0:
			theta = (char_mid - total_width / 2.0) / radius
		var pos := circle_center + radius * Vector2(sin(theta), -cos(theta))
		placements.append({"theta": theta, "pos": pos, "width": w})
		cursor += w
	return placements


static func compute_jitter(
	count: int, position_amount: float, rotation_degrees_amount: float, seed: int
) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var result: Array[Dictionary] = []
	for i in count:
		var dx := rng.randf_range(-position_amount, position_amount)
		var dy := rng.randf_range(-position_amount, position_amount)
		var drot := deg_to_rad(rng.randf_range(-rotation_degrees_amount, rotation_degrees_amount))
		result.append({"dx": dx, "dy": dy, "drot": drot})
	return result


static func compute_float_offset(index: int, time: float, amplitude: float, speed: float) -> float:
	if amplitude <= 0.0:
		return 0.0
	var phase := index * 0.9
	return amplitude * sin(time * speed + phase)


func _process(delta: float) -> void:
	if float_amplitude <= 0.0:
		return
	_float_time += delta
	queue_redraw()


func _draw() -> void:
	if text.is_empty() or not font:
		return

	var widths: Array[float] = []
	var total_width := 0.0
	for i in text.length():
		var w: float = font.get_char_size(text.unicode_at(i), font_size).x
		widths.append(w)
		total_width += w
	if total_width <= 0.0:
		return

	var baseline_y := size.y / 2.0 + font.get_ascent(font_size) * 0.35
	var radius := compute_radius(total_width, arc_angle_degrees)

	var placements: Array[Dictionary] = []
	if radius > 0.0:
		var circle_center := Vector2(size.x / 2.0, baseline_y + radius)
		placements = compute_char_placements(widths, radius, circle_center)
	else:
		var cursor := 0.0
		var x0 := (size.x - total_width) / 2.0
		for w in widths:
			placements.append(
				{"theta": 0.0, "pos": Vector2(x0 + cursor + w / 2.0, baseline_y), "width": w}
			)
			cursor += w

	var jitter := compute_jitter(
		text.length(), jitter_position, jitter_rotation_degrees, jitter_seed
	)

	for i in text.length():
		var placement: Dictionary = placements[i]
		var theta: float = placement["theta"] + jitter[i]["drot"]
		var float_dy := compute_float_offset(i, _float_time, float_amplitude, float_speed)
		var pos: Vector2 = placement["pos"] + Vector2(jitter[i]["dx"], jitter[i]["dy"] + float_dy)
		var w: float = placement["width"]

		draw_set_transform(pos, theta, Vector2.ONE)
		var local_pos := Vector2(-w / 2.0, 0.0)
		if outline_size > 0 and font_outline_color.a > 0.0:
			font.draw_char_outline(
				get_canvas_item(),
				local_pos,
				text.unicode_at(i),
				font_size,
				outline_size,
				font_outline_color
			)
		font.draw_char(get_canvas_item(), local_pos, text.unicode_at(i), font_size, font_color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
