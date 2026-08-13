extends Control
## Иллюстрация случайного события.

const EVENT_ART_PATHS := {
	"EVENT_ABANDONED_WAREHOUSE_TITLE": "res://assets/events/abandoned_warehouse.png",
	"EVENT_ANCIENT_ALTAR_TITLE": "res://assets/events/ancient_altar.png",
	"EVENT_BEAST_AUCTION_TITLE": "res://assets/events/beast_auction.png",
	"EVENT_BEAST_DEN_TITLE": "res://assets/events/beast_den.png",
	"EVENT_COLLAPSED_MINE_TITLE": "res://assets/events/collapsed_mine.png",
	"EVENT_DICE_GAME_TITLE": "res://assets/events/dice_game.png",
	"EVENT_DWARVEN_CARAVAN_TITLE": "res://assets/events/dwarf_caravan.png",
	"EVENT_GARGOYLE_RIDDLE_TITLE": "res://assets/events/gargoyle_riddle.png",
	"EVENT_HERMIT_TRAINING_TITLE": "res://assets/events/hermit_training.png",
	"EVENT_MAGIC_STORM_TITLE": "res://assets/events/magic_storm.png",
	"EVENT_MOON_WELL_TITLE": "res://assets/events/moon_well.png",
	"EVENT_RUINED_WORKSHOP_TITLE": "res://assets/events/ruined_workshop.png",
	"EVENT_RUNIC_MASON_TITLE": "res://assets/events/runic_mason.png",
	"EVENT_WANDERING_MERCHANT_TITLE": "res://assets/events/cardsharp.png",
	"EVENT_WOUNDED_TRAVELER_TITLE": "res://assets/events/wounded_traveler.png",
}

var _event_title_key := "EVENT_MOON_WELL_TITLE"
var _art_texture: Texture2D


func configure(event_title_key: String) -> void:
	_event_title_key = event_title_key
	_art_texture = null
	var art_path := _art_path_for_title(event_title_key)
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		_art_texture = load(art_path) as Texture2D
	queue_redraw()


func _art_path_for_title(event_title_key: String) -> String:
	return String(EVENT_ART_PATHS.get(event_title_key, ""))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(280, 190)
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	if _art_texture != null:
		_draw_art_contain(bounds, _art_texture)
		draw_rect(bounds, Color(0.82, 0.62, 0.28, 0.74), false, 2.0)
		return

	var seed_value: int = absi(_event_title_key.hash())
	var hue := float(seed_value % 1000) / 1000.0
	var sky_top := Color.from_hsv(hue, 0.42, 0.22)
	var sky_bottom := Color.from_hsv(fmod(hue + 0.08, 1.0), 0.48, 0.08)
	var bands := 18
	for i in range(bands):
		var ratio := float(i) / float(bands - 1)
		var band_rect := Rect2(0, bounds.size.y * ratio, bounds.size.x, bounds.size.y / bands + 1)
		draw_rect(band_rect, sky_top.lerp(sky_bottom, ratio))

	var moon_position := Vector2(bounds.size.x * 0.76, bounds.size.y * 0.28)
	draw_circle(
		moon_position, minf(bounds.size.x, bounds.size.y) * 0.085, Color(0.96, 0.82, 0.53, 0.82)
	)

	var ground_y := bounds.size.y * 0.72
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(0, ground_y),
				Vector2(bounds.size.x * 0.32, ground_y - 28),
				Vector2(bounds.size.x * 0.62, ground_y + 4),
				Vector2(bounds.size.x, ground_y - 18),
				Vector2(bounds.size.x, bounds.size.y),
				Vector2(0, bounds.size.y),
			]
		),
		Color(0.035, 0.03, 0.025, 1)
	)

	_draw_tower(Vector2(bounds.size.x * 0.18, ground_y), bounds.size.y * 0.34)
	_draw_tower(Vector2(bounds.size.x * 0.83, ground_y - 8), bounds.size.y * 0.25)
	var road := PackedVector2Array(
		[
			Vector2(bounds.size.x * 0.47, bounds.size.y),
			Vector2(bounds.size.x * 0.58, bounds.size.y),
			Vector2(bounds.size.x * 0.55, ground_y - 4),
			Vector2(bounds.size.x * 0.51, ground_y - 4),
		]
	)
	draw_colored_polygon(road, Color(0.38, 0.29, 0.18, 0.72))

	for i in range(11):
		var x := float((seed_value + i * 79) % 997) / 997.0 * bounds.size.x
		var y := float((seed_value + i * 131) % 991) / 991.0 * ground_y
		var radius := 1.5 + float(i % 3)
		draw_circle(Vector2(x, y), radius, Color(0.96, 0.72, 0.28, 0.64))

	draw_rect(bounds, Color(0.82, 0.62, 0.28, 0.74), false, 2.0)


func _draw_art_contain(bounds: Rect2, texture: Texture2D) -> void:
	draw_rect(bounds, Color(0.012, 0.014, 0.02, 1.0))
	var art_rect := _contain_rect(bounds, texture.get_size())
	if art_rect.size.x <= 0.0 or art_rect.size.y <= 0.0:
		return
	draw_texture_rect(texture, art_rect, false)


func _contain_rect(bounds: Rect2, texture_size: Vector2) -> Rect2:
	if (
		texture_size.x <= 0.0
		or texture_size.y <= 0.0
		or bounds.size.x <= 0.0
		or bounds.size.y <= 0.0
	):
		return Rect2()
	var scale_factor := minf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var render_size := texture_size * scale_factor
	return Rect2(bounds.position + (bounds.size - render_size) / 2.0, render_size)


func _draw_tower(base: Vector2, tower_height: float) -> void:
	var tower_width := maxf(24.0, size.x * 0.075)
	var tower_rect := Rect2(
		base - Vector2(tower_width / 2.0, tower_height), Vector2(tower_width, tower_height)
	)
	draw_rect(tower_rect, Color(0.055, 0.045, 0.038, 1))
	var roof := PackedVector2Array(
		[
			Vector2(base.x - tower_width * 0.75, tower_rect.position.y),
			Vector2(base.x, tower_rect.position.y - tower_width * 0.65),
			Vector2(base.x + tower_width * 0.75, tower_rect.position.y),
		]
	)
	draw_colored_polygon(roof, Color(0.045, 0.036, 0.03, 1))
	draw_rect(
		Rect2(base.x - 3, tower_rect.position.y + tower_height * 0.35, 6, 11),
		Color(0.94, 0.62, 0.2, 0.82)
	)
