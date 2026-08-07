extends GutTest
## Тесты адаптивной компоновки.

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
const BASE_THEME := preload("res://ui/theme/base_theme.tres")

const MIN_TOUCH_TARGET := 44.0


func test_stretch_mode_is_canvas_items_expand() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_base_viewport_size_is_set_explicitly() -> void:
	var w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h = ProjectSettings.get_setting("display/window/size/viewport_height")
	assert_true(w > 0, "viewport_width должен быть явно задан")
	assert_true(w > h, "база — альбомная (ширина больше высоты)")


func test_global_theme_is_registered() -> void:
	var theme_path = ProjectSettings.get_setting("gui/theme/custom")
	assert_eq(theme_path, "res://ui/theme/base_theme.tres")
	assert_true(ResourceLoader.exists(theme_path), "тема должна реально существовать по этому пути")


func test_custom_branding_assets_replace_godot_defaults() -> void:
	var icon_path: String = ProjectSettings.get_setting("application/config/icon")
	var splash_path: String = ProjectSettings.get_setting("application/boot_splash/image")

	assert_eq(icon_path, "res://art/branding/app_icon.png")
	assert_true(ResourceLoader.exists(icon_path), "Иконка приложения должна импортироваться")
	assert_eq(splash_path, "res://art/branding/loading_splash.png")
	assert_true(ResourceLoader.exists(splash_path), "Загрузочная заставка должна импортироваться")
	assert_true("boot_splash/fullsize=true" in FileAccess.get_file_as_string("res://project.godot"))


func test_web_export_uses_project_icon_and_pwa_sizes() -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")

	assert_true("html/export_icon=true" in presets)
	assert_true('progressive_web_app/icon_144x144="res://art/branding/app_icon_144.png"' in presets)
	assert_true('progressive_web_app/icon_180x180="res://art/branding/app_icon_180.png"' in presets)
	assert_true('progressive_web_app/icon_512x512="res://art/branding/app_icon.png"' in presets)


func test_button_theme_meets_minimum_touch_target_height() -> void:
	var theme: Theme = BASE_THEME
	assert_not_null(theme)

	for state in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBox = theme.get_stylebox(state, "Button")
		assert_not_null(style, "Button/styles/%s должен быть задан" % state)
		if style is StyleBoxFlat:
			var vertical_padding = style.content_margin_top + style.content_margin_bottom
			assert_true(
				vertical_padding >= (MIN_TOUCH_TARGET - 16.0),
				(
					"Button/%s: вертикальный content_margin (%s) слишком мал для тач-таргета"
					% [state, vertical_padding]
				)
			)


func test_theme_default_font_size_is_readable_on_mobile() -> void:
	var theme: Theme = BASE_THEME
	assert_true(theme.default_font_size >= 18)


func test_all_screen_roots_fill_the_viewport() -> void:
	for scene_path in SCREEN_SCENES:
		var scene: PackedScene = load(scene_path)
		assert_not_null(scene, "Сцена должна грузиться: %s" % scene_path)
		var root: Control = scene.instantiate()
		assert_eq(root.anchor_right, 1.0, "%s: корень должен быть anchor_right=1.0" % scene_path)
		assert_eq(root.anchor_bottom, 1.0, "%s: корень должен быть anchor_bottom=1.0" % scene_path)
		root.free()
