extends Control
## Процедурный фон главного меню.

const BACKGROUND_TEXTURE := preload("res://art/battle/background_battlefield.png")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	_draw_background()
	_draw_atmosphere()

	var portrait := size.x < size.y * 0.9
	if portrait:
		_draw_castle_scene(size.x * 0.32, size.x * 0.72, size.y * 0.48, size.y * 0.25)
	else:
		_draw_castle_scene(size.x * 0.64, size.x * 0.86, size.y * 0.84, size.y * 0.47)


func _draw_background() -> void:
	var texture_size := BACKGROUND_TEXTURE.get_size()
	var cover_scale := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var source_size := size / cover_scale
	var source_position := (texture_size - source_size) * 0.5
	draw_texture_rect_region(
		BACKGROUND_TEXTURE, Rect2(Vector2.ZERO, size), Rect2(source_position, source_size)
	)

	var zenith := Color(0.01, 0.02, 0.06, 0.34)
	var horizon := Color(0.28, 0.11, 0.12, 0.22)
	var band_count := 28
	for index in range(band_count):
		var t := float(index) / float(band_count - 1)
		var eased := t * t
		var color := zenith.lerp(horizon, eased)
		var band_height := size.y / float(band_count) + 1.0
		draw_rect(Rect2(0.0, index * band_height, size.x, band_height), color)

	var glow_center := Vector2(size.x * 0.76, size.y * 0.33)
	var glow_radius := minf(size.x, size.y) * 0.11
	for ring in range(8, 0, -1):
		var alpha := 0.012 * float(9 - ring)
		draw_circle(glow_center, glow_radius * float(ring) / 3.0, Color(0.98, 0.54, 0.24, alpha))
	draw_circle(glow_center, glow_radius, Color("#e9a45f"))
	draw_circle(glow_center, glow_radius * 0.82, Color("#ffd08a"))


func _draw_atmosphere() -> void:
	var stars: Array[Vector2] = [
		Vector2(0.08, 0.10),
		Vector2(0.17, 0.22),
		Vector2(0.31, 0.09),
		Vector2(0.43, 0.19),
		Vector2(0.55, 0.08),
		Vector2(0.70, 0.14),
		Vector2(0.88, 0.10),
		Vector2(0.94, 0.26),
	]
	for star in stars:
		draw_circle(Vector2(size.x * star.x, size.y * star.y), 1.5, Color(1.0, 0.87, 0.64, 0.55))

	var ridge := PackedVector2Array(
		[
			Vector2(0.0, size.y * 0.72),
			Vector2(size.x * 0.14, size.y * 0.60),
			Vector2(size.x * 0.27, size.y * 0.68),
			Vector2(size.x * 0.45, size.y * 0.54),
			Vector2(size.x * 0.62, size.y * 0.66),
			Vector2(size.x * 0.80, size.y * 0.56),
			Vector2(size.x, size.y * 0.70),
			Vector2(size.x, size.y),
			Vector2(0.0, size.y),
		]
	)
	draw_colored_polygon(ridge, Color("#111426"))
	draw_rect(Rect2(0.0, size.y * 0.82, size.x, size.y * 0.18), Color("#090c16"))


func _draw_castle_scene(left_x: float, right_x: float, ground_y: float, max_height: float) -> void:
	var span := absf(right_x - left_x)
	var wall_top := ground_y - max_height * 0.28
	_draw_wall(Rect2(left_x, wall_top, span, ground_y - wall_top))
	_draw_tower(left_x, ground_y, max_height, max_height * 0.30, Color("#263247"), false)
	_draw_tower(right_x, ground_y, max_height * 0.82, max_height * 0.28, Color("#33283d"), true)

	draw_line(
		Vector2(left_x, ground_y + 2.0),
		Vector2(right_x, ground_y + 2.0),
		Color(0.91, 0.57, 0.27, 0.38),
		2.0,
		true
	)


func _draw_wall(rect: Rect2) -> void:
	draw_rect(rect, Color("#1b2233"))
	draw_line(
		rect.position, rect.position + Vector2(rect.size.x, 0.0), Color(0.55, 0.49, 0.48, 0.32), 2.0
	)
	var block_width := maxf(18.0, rect.size.x / 7.0)
	var rows := 3
	for row in range(rows):
		var y := rect.position.y + rect.size.y * float(row + 1) / float(rows + 1)
		draw_line(
			Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.03, 0.04, 0.08, 0.42), 1.0
		)
		var offset := block_width * 0.5 if row % 2 == 1 else 0.0
		var x := rect.position.x + offset
		while x < rect.end.x:
			draw_line(
				Vector2(x, y - rect.size.y / float(rows + 1)),
				Vector2(x, y),
				Color(0.03, 0.04, 0.08, 0.35),
				1.0
			)
			x += block_width


func _draw_tower(
	center_x: float, ground_y: float, height: float, width: float, color: Color, faces_left: bool
) -> void:
	var body_width := width * 0.66
	var body_x := center_x - body_width * 0.5
	var body_top := ground_y - height
	var body := Rect2(body_x, body_top, body_width, height)
	draw_rect(body, color)

	var shade := Color(color.r * 0.68, color.g * 0.68, color.b * 0.72, 1.0)
	var shaded_width := body_width * 0.30
	var shade_x := body_x if faces_left else body.end.x - shaded_width
	draw_rect(Rect2(shade_x, body_top, shaded_width, height), shade)

	var battlement_height := maxf(10.0, height * 0.08)
	var battlement_width := body_width / 5.0
	for index in range(5):
		if index % 2 == 0:
			draw_rect(
				Rect2(
					body_x + battlement_width * index,
					body_top - battlement_height,
					battlement_width,
					battlement_height
				),
				color
			)

	for row in range(3):
		var window_y := body_top + height * (0.24 + 0.22 * row)
		var window_rect := Rect2(center_x - width * 0.045, window_y, width * 0.09, height * 0.08)
		draw_rect(window_rect, Color("#0b101c"))
		draw_rect(window_rect.grow(-2.0), Color(0.96, 0.63, 0.26, 0.76))

	var gate_width := body_width * 0.30
	draw_rect(
		Rect2(center_x - gate_width * 0.5, ground_y - height * 0.14, gate_width, height * 0.14),
		Color("#0a0d16")
	)
	draw_rect(
		Rect2(
			body_x - width * 0.08,
			ground_y - height * 0.05,
			body_width + width * 0.16,
			height * 0.05
		),
		shade
	)
