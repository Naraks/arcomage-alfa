extends GutTest
## Юнит-тесты MainMenu (ARC-095 + UI 13/13, GitHub issue #108).
##
## main_menu.gd — не autoload и без class_name (обычный Control-скрипт сцены
## main_menu.tscn), поэтому экземпляр создаётся через load().new() и НЕ
## добавляется в дерево сцены (тот же паттерн, что в test_world_map_screen.gd):
## _ready() при этом не вызывается. Для CTA-тестов явно вызываем _build_ui()
## и передаём состояние сейва параметром — user:// тестами не затрагивается.

const MainMenuScript = preload("res://ui/main_menu.gd")
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")


func test_public_game_title_is_consistent() -> void:
	assert_eq(MainMenuScript.GAME_TITLE, "Башни магов: Дуэль")
	assert_eq(ProjectSettings.get_setting("application/config/name"), MainMenuScript.GAME_TITLE)

	var menu := MainMenuScript.new()
	menu._build_ui()
	var logo: Label = menu.find_child("Logo", true, false)
	var title_suffix: Label = menu.find_child("TitleSuffix", true, false)
	assert_not_null(logo)
	assert_not_null(title_suffix)
	assert_eq(logo.text, "БАШНИ МАГОВ")
	assert_eq(title_suffix.text, "ДУЭЛЬ")
	assert_true(logo.has_theme_font_override("font"))
	assert_eq(logo.get_theme_font("font"), MainMenuScript.TITLE_FONT)
	assert_false(title_suffix.has_theme_font_override("font"))
	menu.free()


func test_no_save_makes_new_run_the_only_primary_cta() -> void:
	var menu := MainMenuScript.new()
	menu._build_ui()
	menu._configure_run_actions(false)

	var state: Dictionary = menu._run_cta_state(false)
	assert_false(state.continue_visible)
	assert_true(state.continue_disabled)
	assert_true(state.new_run_is_primary)
	assert_false(
		menu._continue_button.visible, "Без сейва Продолжить не должно занимать главный слот"
	)
	assert_eq(menu._campaign_button.text, "Новый забег")
	assert_true(menu._campaign_button.custom_minimum_size.y >= 44.0)
	menu.free()


func test_saved_run_makes_continue_primary_and_shows_progress() -> void:
	var menu := MainMenuScript.new()
	menu._build_ui()
	menu._configure_run_actions(true, "Этаж 9 из 15")

	var state: Dictionary = menu._run_cta_state(true, "Этаж 9 из 15")
	assert_true(state.continue_visible)
	assert_false(state.continue_disabled)
	assert_false(state.new_run_is_primary)
	assert_true(menu._continue_button.visible)
	assert_false(menu._continue_button.disabled)
	assert_string_contains(menu._continue_button.text, "Продолжить забег")
	assert_string_contains(menu._continue_button.text, "Этаж 9 из 15")
	assert_eq(menu._campaign_button.text, "Новый забег")
	menu.free()


func test_saved_run_without_readable_progress_has_honest_fallback() -> void:
	var menu := MainMenuScript.new()
	var state: Dictionary = menu._run_cta_state(true, "")

	assert_eq(state.continue_text, "Продолжить забег\nСохранённый забег")
	menu.free()


func test_run_progress_uses_next_floor_after_completed_node() -> void:
	var menu := MainMenuScript.new()
	var map := WorldMapData.new()
	map.floor_count = 15
	map.current_node_index = 0
	var completed_node := MapNodeData.new()
	completed_node.floor_index = 7
	completed_node.is_completed = true
	map.map_nodes = [completed_node]

	assert_eq(menu._format_run_progress(map), "Этаж 9 из 15")
	menu.free()


func test_fresh_run_progress_starts_from_first_floor() -> void:
	var menu := MainMenuScript.new()
	var map := WorldMapData.new()
	map.floor_count = 12
	map.current_node_index = -1

	assert_eq(menu._format_run_progress(map), "Этаж 1 из 12")
	menu.free()


func test_built_menu_uses_clear_quick_battle_label_and_touch_targets() -> void:
	var menu := MainMenuScript.new()
	menu._build_ui()

	assert_eq(menu._battle_button.text, "Быстрый бой")
	for button in [
		menu._campaign_button, menu._battle_button, menu._profile_button, menu._settings_button
	]:
		assert_true(
			button.custom_minimum_size.y >= 44.0, "%s должен иметь touch-цель >=44px" % button.name
		)
	menu.free()


func test_layout_uses_side_panel_for_landscape_and_bottom_panel_for_portrait() -> void:
	var menu := MainMenuScript.new()
	menu._build_ui()
	# В рантайме размер полноэкранного корня задаёт viewport. В изолированном
	# тесте родительского viewport нет, поэтому временно сводим anchors в одну
	# точку перед ручной установкой size — иначе Godot предупреждает, что
	# разнесённые anchors впоследствии переопределят этот размер.
	menu.set_anchors_preset(Control.PRESET_TOP_LEFT)

	for viewport_size in [Vector2(1280, 720), Vector2(960, 720)]:
		menu.size = viewport_size
		menu._apply_responsive_layout()
		assert_eq(menu._menu_panel.anchor_left, 0.0)
		assert_eq(menu._menu_panel.anchor_right, 0.0)
		assert_true(menu._menu_panel.offset_right <= viewport_size.x)

	menu.size = Vector2(720, 1280)
	menu._apply_responsive_layout()
	assert_eq(menu._menu_panel.anchor_left, 0.0)
	assert_eq(menu._menu_panel.anchor_right, 1.0)
	assert_eq(menu._menu_panel.anchor_top, 1.0)
	assert_eq(menu._menu_panel.anchor_bottom, 1.0)
	menu.free()


func test_prepare_test_battle_settings_resets_run_state() -> void:
	# Симулируем "протёкшее" состояние прошлой кампании — метод должен
	# сбросить всё до нуля независимо от того, что было раньше (ARC-002/016).
	MatchSettings.run_deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchSettings.run_gold = 999
	MatchSettings.came_from_map = true
	MatchSettings.current_map_node = MapNodeData.new()

	var menu := MainMenuScript.new()
	menu._prepare_test_battle_settings()

	assert_true(MatchSettings.run_deck.is_empty(), "run_deck не должен протечь из прошлой кампании")
	assert_eq(MatchSettings.run_gold, 0)
	assert_false(MatchSettings.came_from_map)
	assert_null(MatchSettings.current_map_node)
	assert_not_null(MatchSettings.player_data)
	assert_not_null(MatchSettings.enemy_data)
	menu.free()


func test_prepare_test_battle_settings_without_strategy_leaves_enemy_ai_unset() -> void:
	# _prepare_test_battle_settings() сам по себе, без переданной стратегии,
	# оставляет enemy_data.ai_strategy равным null — дальше подстрахует
	# DefaultAIStrategy-фоллбэк в MatchManager.setup_match() (ARC-078). С
	# ARC-085 обычная кнопка «Битва» (_on_battle_pressed()) больше не зовёт
	# этот метод без стратегии — она передаёт случайный обычный архетип
	# (см. test_pick_random_regular_ai_strategy_returns_all_four_archetypes в
	# tests/test_match_manager.gd) — но сам метод остаётся пригоден для
	# явного null (используется debug-кнопками не отсюда).
	var menu := MainMenuScript.new()
	menu._prepare_test_battle_settings()

	assert_null(MatchSettings.enemy_data.ai_strategy)
	menu.free()


func test_prepare_test_battle_settings_assigns_requested_debug_strategy() -> void:
	# Debug-кнопки (_generate_debug_ai_picker_bar()) передают конкретную
	# стратегию — она должна дойти до MatchSettings.enemy_data как есть.
	var strategy := AggressiveAIStrategyScript.new()
	var menu := MainMenuScript.new()

	menu._prepare_test_battle_settings(strategy)

	assert_eq(MatchSettings.enemy_data.ai_strategy, strategy)
	menu.free()
