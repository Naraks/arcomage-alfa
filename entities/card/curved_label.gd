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

@export_range(8, 64, 1) var minimum_font_size: int = 16
@export_range(0.0, 32.0, 1.0) var horizontal_padding: float = 8.0
@export var allow_two_lines: bool = true

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

var _curve_cache_key: Array = []
var _curve_cache_placements: Array[Dictionary] = []
var _curve_cache_jitter: Array[Dictionary] = []


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


static func compute_fitted_font_size(
	measured_width: float, available_width: float, preferred_size: int, minimum_size: int
) -> int:
	if measured_width <= 0.0 or available_width <= 0.0:
		return preferred_size
	var scaled_size := floori(preferred_size * available_width / measured_width)
	return clampi(scaled_size, minimum_size, preferred_size)


func _process(delta: float) -> void:
	if float_amplitude <= 0.0:
		return
	_float_time += delta
	queue_redraw()


func _draw() -> void:
	if text.is_empty() or not font:
		return

	var available_width := maxf(0.0, size.x - horizontal_padding * 2.0)
	var fitted_size := _fit_single_line_font_size(text, available_width)
	if _measure_text(text, fitted_size) <= available_width:
		_draw_curved_line(text, fitted_size, size.y / 2.0)
		return

	if allow_two_lines:
		var lines := _split_into_two_lines(text)
		if lines.size() == 2:
			var two_line_size := _fit_two_line_font_size(lines, available_width)
			_draw_flat_line(lines[0], two_line_size, size.y * 0.34)
			_draw_flat_line(lines[1], two_line_size, size.y * 0.72)
			return

	_draw_curved_line(text, minimum_font_size, size.y / 2.0)


func _fit_single_line_font_size(line: String, available_width: float) -> int:
	var measured_width := _measure_text(line, font_size)
	var fitted_size := compute_fitted_font_size(
		measured_width, available_width, font_size, minimum_font_size
	)
	while fitted_size > minimum_font_size and _measure_text(line, fitted_size) > available_width:
		fitted_size -= 1
	return fitted_size


func _fit_two_line_font_size(lines: Array[String], available_width: float) -> int:
	var fitted_size := font_size
	for line in lines:
		fitted_size = mini(fitted_size, _fit_single_line_font_size(line, available_width))
	return maxi(minimum_font_size, fitted_size)


func _split_into_two_lines(value: String) -> Array[String]:
	var words := value.split(" ", false)
	if words.size() < 2:
		return []

	var best_lines: Array[String] = []
	var best_width := INF
	for split_index in range(1, words.size()):
		var first := " ".join(words.slice(0, split_index))
		var second := " ".join(words.slice(split_index))
		var widest := maxf(
			_measure_text(first, minimum_font_size), _measure_text(second, minimum_font_size)
		)
		if widest < best_width:
			best_width = widest
			best_lines = [first, second]
	return best_lines


func _measure_text(value: String, draw_font_size: int) -> float:
	var total_width := 0.0
	for i in value.length():
		total_width += font.get_char_size(value.unicode_at(i), draw_font_size).x
	return total_width


func _draw_flat_line(value: String, draw_font_size: int, center_y: float) -> void:
	var line_width := _measure_text(value, draw_font_size)
	var cursor := (size.x - line_width) / 2.0
	var baseline_y := center_y + font.get_ascent(draw_font_size) * 0.35
	var jitter := compute_jitter(
		value.length(), jitter_position * 0.35, jitter_rotation_degrees * 0.35, jitter_seed
	)
	for i in value.length():
		var w: float = font.get_char_size(value.unicode_at(i), draw_font_size).x
		var pos := Vector2(cursor + w / 2.0 + jitter[i]["dx"], baseline_y + jitter[i]["dy"])
		draw_set_transform(pos, jitter[i]["drot"], Vector2.ONE)
		_draw_character(value.unicode_at(i), w, draw_font_size)
		cursor += w
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_curved_line(value: String, draw_font_size: int, center_y: float) -> void:
	var cache_key := [
		value,
		font,
		draw_font_size,
		size.x,
		center_y,
		arc_angle_degrees,
		jitter_position,
		jitter_rotation_degrees,
		jitter_seed,
	]
	if cache_key != _curve_cache_key:
		_curve_cache_key = cache_key
		_rebuild_curve_cache(value, draw_font_size, center_y)

	if _curve_cache_placements.is_empty():
		return

	for i in value.length():
		var placement: Dictionary = _curve_cache_placements[i]
		var theta: float = placement["theta"] + _curve_cache_jitter[i]["drot"]
		var float_dy := compute_float_offset(i, _float_time, float_amplitude, float_speed)
		var pos: Vector2 = (
			placement["pos"]
			+ Vector2(_curve_cache_jitter[i]["dx"], _curve_cache_jitter[i]["dy"] + float_dy)
		)
		var w: float = placement["width"]

		draw_set_transform(pos, theta, Vector2.ONE)
		_draw_character(value.unicode_at(i), w, draw_font_size)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Пересчитывает placements/jitter для _draw_curved_line — зависят только от
## текста/шрифта/геометрии/seed, а не от времени, поэтому кэшируются между
## кадрами анимации "плавания" и пересчитываются только когда меняется
## cache_key.
func _rebuild_curve_cache(value: String, draw_font_size: int, center_y: float) -> void:
	var widths: Array[float] = []
	var total_width := 0.0
	for i in value.length():
		var w: float = font.get_char_size(value.unicode_at(i), draw_font_size).x
		widths.append(w)
		total_width += w

	if total_width <= 0.0:
		_curve_cache_placements = []
		_curve_cache_jitter = []
		return

	var baseline_y := center_y + font.get_ascent(draw_font_size) * 0.35
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

	_curve_cache_placements = placements
	_curve_cache_jitter = compute_jitter(
		value.length(), jitter_position, jitter_rotation_degrees, jitter_seed
	)


func _draw_character(character: int, width: float, draw_font_size: int) -> void:
	var local_pos := Vector2(-width / 2.0, 0.0)
	if outline_size > 0 and font_outline_color.a > 0.0:
		font.draw_char_outline(
			get_canvas_item(),
			local_pos,
			character,
			draw_font_size,
			outline_size,
			font_outline_color
		)
	font.draw_char(get_canvas_item(), local_pos, character, draw_font_size, font_color)
