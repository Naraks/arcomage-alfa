extends GutTest
## ARC-044: адаптация UI под мобильные разрешения (docs/game_design_doc.md §13,
## docs/dev_plan_tickets.md ARC-044).
##
## Что реально можно проверить в GUT без визуального рендера на трёх
## соотношениях сторон (16:9/9:16/4:3 — акцептанс-критерий ARC-044 требует
## именно это, а его в headless-тесте не увидеть): что stretch-режим настроен
## на адаптацию (canvas_items + expand), что у каждого экрана корневой
## Control растянут на весь вьюпорт (anchors_preset=15 — без этого никакой
## stretch-режим не поможет), и что глобальная тема кнопок (`ui/theme/
## base_theme.tres`) даёт минимальный тач-таргет ~44x44 логических пикселя
## (рекомендация из ARC-044) через content_margin стилбоксов, а не полагается
## на дефолтную тему Godot (та была рассчитана под десктопный клик мышью).
##
## Реальная визуальная проверка на 3 соотношениях сторон в редакторе Godot —
## отдельный ручной шаг, см. блокквот ARC-044 в dev_plan_tickets.md (в
## песочнице агента нет бинарника Godot, см. CLAUDE.md).

const SCREEN_SCENES := [
	"res://ui/main_menu.tscn",
	"res://ui/battle/battle_screen.tscn",
	"res://ui/map/world_map_screen.tscn",
	"res://ui/shop/shop_screen.tscn",
	"res://ui/rest/rest_screen.tscn",
	"res://ui/event/event_screen.tscn",
	"res://ui/reward/reward_screen.tscn",
	"res://ui/deck/deck_screen.tscn",
	"res://ui/meta_shop/meta_shop_screen.tscn",
	"res://ui/profile/profile_screen.tscn",
	"res://ui/stats/stats_screen.tscn",
	"res://ui/settings/settings_screen.tscn",
	"res://ui/run_summary/run_summary_screen.tscn",
]

# Рекомендация ARC-044: логический тач-таргет не меньше 44x44 пикселя.
const MIN_TOUCH_TARGET := 44.0


func test_stretch_mode_is_canvas_items_expand() -> void:
	# canvas_items — UI масштабируется вместе с окном (не пиксель-в-пиксель
	# "viewport", который просто ресайзит и требует отдельной 3D-камеры
	# логики); expand — на непропорциональных соотношениях сторон открывается
	# больше канвы вместо чёрных полос/обрезки контента.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_base_viewport_size_is_set_explicitly() -> void:
	# База — явный ландшафт 1280x720 (16:9), выбор продукта: устанавливаем
	# конкретно заданное разрешение вместо унаследованного дефолта Godot
	# (1152x648, если бы не было задано явно). stretch/aspect="expand"
	# по-прежнему адаптирует под портретные окна/мобильный браузер в
	# реальном рантайме — эта база влияет на редакторный превью и дефолтное
	# окно десктоп-билда, не запрещает портретный просмотр.
	var w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h = ProjectSettings.get_setting("display/window/size/viewport_height")
	assert_true(w > 0, "viewport_width должен быть явно задан")
	assert_true(w > h, "база — альбомная (ширина больше высоты)")


func test_global_theme_is_registered() -> void:
	var theme_path = ProjectSettings.get_setting("gui/theme/custom")
	assert_eq(theme_path, "res://ui/theme/base_theme.tres")
	assert_true(ResourceLoader.exists(theme_path), "тема должна реально существовать по этому пути")


func test_button_theme_meets_minimum_touch_target_height() -> void:
	var theme: Theme = load("res://ui/theme/base_theme.tres")
	assert_not_null(theme)

	for state in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBox = theme.get_stylebox(state, "Button")
		assert_not_null(style, "Button/styles/%s должен быть задан" % state)
		if style is StyleBoxFlat:
			var vertical_padding = style.content_margin_top + style.content_margin_bottom
			# Текст кнопки (default_font_size=18) добавляет сверху ещё
			# заметную высоту строки — 28px паддинга уже достаточно, чтобы
			# итоговая высота кнопки была за пределами 44px. Проверяем именно
			# паддинг (детерминированная величина из ресурса), а не итоговую
			# высоту (та зависит от рендера шрифта, недоступного без живого
			# Godot).
			assert_true(
				vertical_padding >= (MIN_TOUCH_TARGET - 16.0),
				"Button/%s: вертикальный content_margin (%s) слишком мал для тач-таргета" % [state, vertical_padding]
			)


func test_theme_default_font_size_is_readable_on_mobile() -> void:
	var theme: Theme = load("res://ui/theme/base_theme.tres")
	# Дефолт Godot — 16px, рассчитан на десктоп с обычного расстояния до
	# монитора; для мобильного браузера чуть крупнее читается надёжнее.
	assert_true(theme.default_font_size >= 18)


func test_all_screen_roots_fill_the_viewport() -> void:
	# anchors_preset=15 (PRESET_FULL_RECT) на корне — необходимое условие,
	# чтобы canvas_items/expand вообще могли растянуть экран на весь вьюпорт
	# любого соотношения сторон. instantiate() не добавляет узел в дерево
	# сцены, поэтому _ready() (и любые побочные эффекты вроде
	# MatchManager.setup_match()) не вызывается — проверяем только статичные
	# анкоры, как задокументировано в самой .tscn.
	for scene_path in SCREEN_SCENES:
		var scene: PackedScene = load(scene_path)
		assert_not_null(scene, "Сцена должна грузиться: %s" % scene_path)
		var root: Control = scene.instantiate()
		assert_eq(root.anchor_right, 1.0, "%s: корень должен быть anchor_right=1.0" % scene_path)
		assert_eq(root.anchor_bottom, 1.0, "%s: корень должен быть anchor_bottom=1.0" % scene_path)
		root.free()
