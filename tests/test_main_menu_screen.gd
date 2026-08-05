extends GutTest
## Юнит-тесты MainMenu._prepare_test_battle_settings() (ARC-095).
##
## main_menu.gd — не autoload и без class_name (обычный Control-скрипт сцены
## main_menu.tscn), поэтому экземпляр создаётся через load().new() и НЕ
## добавляется в дерево сцены (тот же паттерн, что в test_world_map_screen.gd):
## _ready() при этом не вызывается (трогает $VersionLabel/$VBoxContainer —
## реальные узлы сцены), а _prepare_test_battle_settings() трогает только
## MatchSettings, ей сцена не нужна.

const MainMenuScript = preload("res://ui/main_menu.gd")
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")


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


func test_prepare_test_battle_settings_assigns_requested_debug_strategy() -> void:
	# Debug-кнопки (_generate_debug_ai_picker_bar()) передают конкретную
	# стратегию — она должна дойти до MatchSettings.enemy_data как есть.
	var strategy := AggressiveAIStrategyScript.new()
	var menu := MainMenuScript.new()

	menu._prepare_test_battle_settings(strategy)

	assert_eq(MatchSettings.enemy_data.ai_strategy, strategy)
