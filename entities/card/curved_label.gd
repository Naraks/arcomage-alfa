extends Control
class_name CurvedLabel
## ARC-091 (docs/art_prompts.md §5): имя карты рисуется посимвольно (не
## обычный Label) — изначально ради изгиба по дуге под форму ленты-баннера,
## затем (после отказа от ленты — см. docs/dev_plan_tickets.md) ради
## "дрожащего" почерка, будто имя написано чернилами прямо на пергаменте, и
## теперь ещё ради лёгкой анимации — буквы могут "плавать" по отдельности
## (compute_float_offset + _process()). Обычный Label ничего из этого не
## умеет — поэтому строка рисуется вручную посимвольно в _draw() с
## трансформацией (позиция + поворот на каждый символ).
##
## arc_angle_degrees, jitter_position/jitter_rotation_degrees и
## float_amplitude/float_speed независимы и складываются — можно сочетать
## дугу, дрожание почерка и анимацию плавания в любой комбинации, включая
## "ничего из этого" (обычная неподвижная прямая центрированная строка).
## jitter_seed фиксирует "почерк" детерминированно: одна и та же строка при
## каждой перерисовке (queue_redraw()) выглядит одинаково, а не дёргается —
## анимация плавания это не нарушает, она смещение поверх, не замена.
##
## Заменяет собой Label только там, где явно нужен изгиб/почерк (сейчас —
## NameLabel в entities/card/card.tscn); card.gd работает с ним так же, как
## раньше с Label — через свойство text (сеттер сам вызывает queue_redraw()).
##
## Не проверено вживую в редакторе/игре (в песочнице агента нет Godot-биналя,
## см. CLAUDE.md) — если эффект выглядит слишком сильным/слабым или текст
## сидит не по центру, крутить экспортированные параметры узла в .tscn, менять
## код для этого не нужно.

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

## Суммарный угол дуги на всю строку (градусы). 0 — прямая строка без изгиба
## (тогда рисуется как обычный центрированный однострочный текст).
@export_range(0.0, 60.0, 0.5) var arc_angle_degrees: float = 22.0

## "Дрожащий" почерк — максимальное случайное смещение каждого символа по
## X/Y (пиксели) и поворот (градусы) от его "правильной" позиции на строке/
## дуге. 0/0 — идеально ровный машинный текст. Оба применяются независимо от
## arc_angle_degrees (можно сочетать изгиб и дрожание, или использовать
## только одно из двух).
@export_range(0.0, 6.0, 0.25) var jitter_position: float = 0.0
@export_range(0.0, 15.0, 0.5) var jitter_rotation_degrees: float = 0.0
@export var jitter_seed: int = 12345

## "Плавающие" буквы — каждая идёт по своей синусоиде вверх-вниз (у каждой
## своя фаза по индексу, поэтому строка не подпрыгивает целиком синхронно, а
## буквы будто плывут порознь). amplitude=0 — анимация выключена (и
## _process() тогда не дёргает queue_redraw() каждый кадр зря). Складывается
## с дугой/дрожанием почерка так же независимо, как они между собой.
@export_range(0.0, 6.0, 0.25) var float_amplitude: float = 0.0
@export_range(0.1, 5.0, 0.1) var float_speed: float = 1.2

var _float_time: float = 0.0


## Радиус дуги из желаемого угла (градусы) и суммарной ширины строки (длина
## дуги по окружности ≈ ширина текста). Вынесено отдельной чистой функцией —
## тестируется в tests/test_curved_label.gd без реального Font/рендера.
static func compute_radius(total_width: float, arc_angle_degrees: float) -> float:
	var arc_rad := deg_to_rad(arc_angle_degrees)
	if arc_rad < 0.001 or total_width <= 0.0:
		return 0.0
	return total_width / arc_rad


## Раскладка символов по дуге: для каждого символа (по его ширине и позиции
## накопленного курсора) считает угол theta от вершины дуги и точку на
## окружности, где должен сидеть символ. circle_center — центр окружности
## (ниже текста, так как символы сидят на ВЕРХНЕЙ дуге — "улыбка", как
## выгнута лента). Чистая математика, без Font/CanvasItem — тестируется
## отдельно от реальной отрисовки.
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


## "Дрожащий" почерк — детерминированный набор смещений/поворотов, по одному
## на символ. Тот же seed => тот же результат при каждой перерисовке (иначе
## буквы дёргались бы между вызовами _draw(), а не просто выглядели
## "неровно от руки" один раз). Чистая функция без Font/CanvasItem — тестами
## накрыта отдельно от самой отрисовки, как и compute_radius/
## compute_char_placements выше.
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


## Вертикальное смещение одной буквы в момент времени time — своя фаза на
## символ (index * 0.9, произвольный несинхронизирующийся сдвиг), поэтому
## соседние буквы не совпадают по фазе даже при близких индексах. Чистая
## функция (без CanvasItem/времени движка) — тестируется отдельно, как и
## compute_radius/compute_char_placements/compute_jitter выше.
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

	# Первый проход — только измеряем ширину каждого символа (нужно знать
	# total_width ДО отрисовки, чтобы посчитать радиус дуги и центрировать
	# строку). font.get_char_size() не рисует, в отличие от draw_char().
	var widths: Array[float] = []
	var total_width := 0.0
	for i in text.length():
		var w: float = font.get_char_size(text.unicode_at(i), font_size).x
		widths.append(w)
		total_width += w
	if total_width <= 0.0:
		return

	# Условная "средняя линия" узла по вертикали для базовой линии шрифта.
	var baseline_y := size.y / 2.0 + font.get_ascent(font_size) * 0.35
	var radius := compute_radius(total_width, arc_angle_degrees)

	# Раскладка по дуге ИЛИ по прямой — дальше оба случая рисуются одним и
	# тем же кодом ниже (через draw_set_transform на каждый символ), чтобы
	# "дрожащий" почерк работал одинаково что с изгибом, что без него.
	var placements: Array[Dictionary] = []
	if radius > 0.0:
		var circle_center := Vector2(size.x / 2.0, baseline_y + radius)
		placements = compute_char_placements(widths, radius, circle_center)
	else:
		var cursor := 0.0
		var x0 := (size.x - total_width) / 2.0
		for w in widths:
			placements.append({"theta": 0.0, "pos": Vector2(x0 + cursor + w / 2.0, baseline_y), "width": w})
			cursor += w

	var jitter := compute_jitter(text.length(), jitter_position, jitter_rotation_degrees, jitter_seed)

	for i in text.length():
		var placement: Dictionary = placements[i]
		var theta: float = placement["theta"] + jitter[i]["drot"]
		var float_dy := compute_float_offset(i, _float_time, float_amplitude, float_speed)
		var pos: Vector2 = placement["pos"] + Vector2(jitter[i]["dx"], jitter[i]["dy"] + float_dy)
		var w: float = placement["width"]

		# draw_set_transform сдвигает локальные координаты отрисовки в pos и
		# поворачивает на theta — символ рисуется "лёжа" на касательной к дуге
		# в этой точке (плюс дрожание почерка), а не просто сдвинутым по
		# вертикали.
		draw_set_transform(pos, theta, Vector2.ONE)
		var local_pos := Vector2(-w / 2.0, 0.0)
		if outline_size > 0 and font_outline_color.a > 0.0:
			font.draw_char_outline(get_canvas_item(), local_pos, text.unicode_at(i), font_size, outline_size, font_outline_color)
		font.draw_char(get_canvas_item(), local_pos, text.unicode_at(i), font_size, font_color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
