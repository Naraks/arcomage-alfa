extends Control

const DefaultAIStrategyScript = preload("res://data/resources/default_ai_strategy.gd")
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")
const BuilderAIStrategyScript = preload("res://data/resources/builder_ai_strategy.gd")
const EconomistAIStrategyScript = preload("res://data/resources/economist_ai_strategy.gd")
const BossAIStrategyScript = preload("res://data/resources/boss_ai_strategy.gd")


func _ready() -> void:
	$VersionLabel.text = BuildVersion.get_display_string()
	# ARC-018: «Продолжить» имеет смысл, только если есть сохранённый забег.
	$VBoxContainer/ContinueButton.disabled = not RunSaveManager.has_saved_run()

	if OS.is_debug_build():
		_generate_debug_ai_picker_bar()


func _on_continue_pressed():
	if not RunSaveManager.load_run():
		print("[ERROR] Continue pressed but no valid saved run found")
		return
	get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")


func _on_campaign_pressed():
	print("Campaign pressed - loading world map")

	# ARC-010: процедурная генерация карты вместо хардкода из 2 узлов.
	# Сид не фиксируется здесь намеренно — обычный забег каждый раз получает
	# новую карту; фиксированный сид (для "дневных забегов") — задел на будущее.
	MatchSettings.world_map_data = WorldMapGenerator.generate_map(randi())

	# ARC-016: новый забег начинается со стартовой колоды — она же и есть
	# "колода забега", которую увидит match_manager.setup_match() в каждом
	# бою этой кампании, и которая будет расти от наград/магазина.
	MatchSettings.run_deck = MatchManager.build_starting_run_deck()

	# ARC-012: стартовое золото забега.
	MatchSettings.run_gold = MatchManager.STARTING_RUN_GOLD

	# ARC-013: сброс бонусов с «Отдыха» — иначе протекли бы из прошлой кампании.
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0

	# ARC-015: новый забег начинается без артефактов прошлой кампании.
	MatchSettings.run_artifacts = []

	var err = get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
	print("Change scene result: ", err)


## ARC-085: раньше не передавал стратегию вовсе — enemy_data.ai_strategy
## оставался null, и MatchManager.setup_match() молча подставлял
## DefaultAIStrategy («Сбалансированный»), из-за чего Быстрый бой никогда не
## давал Агрессора/Строителя/Мага-Экономиста, хотя design doc §6.3 описывает
## его как "случайный архетип среднего уровня". Теперь переиспользует тот же
## пул и рандомайзер, что и обычный бой карты мира (world_map_screen.gd,
## ARC-027), вынесенный в MatchManager.pick_random_regular_ai_strategy().
func _on_battle_pressed():
	_start_test_battle(MatchManager.pick_random_regular_ai_strategy())


## ARC-095: вынесено из _on_battle_pressed(), чтобы debug-панель ниже
## (_generate_debug_ai_picker_bar()) могла запускать тот же тестовый бой без
## забега, но с конкретной (не дефолтной) стратегией ИИ соперника — только
## enemy_ai_strategy отличается от обычной кнопки «Битва».
func _start_test_battle(enemy_ai_strategy: Resource = null) -> void:
	print("Battle pressed - loading battle screen")
	_prepare_test_battle_settings(enemy_ai_strategy)
	get_tree().change_scene_to_file("res://ui/battle/battle_screen.tscn")


## ARC-095: вынесено из _start_test_battle() отдельно от get_tree() — только
## MatchSettings-присваивания, без обращения к дереву сцены, чтобы юнит-тест
## мог проверить их напрямую (main_menu.gd не добавляется в дерево в тестах,
## см. tests/test_resolution_adaptation.gd — instantiate() без add_child()).
func _prepare_test_battle_settings(enemy_ai_strategy: Resource = null) -> void:
	var p_data = PlayerData.new()
	var e_data = PlayerData.new()
	if enemy_ai_strategy:
		e_data.ai_strategy = enemy_ai_strategy
	MatchSettings.player_data = p_data
	MatchSettings.enemy_data = e_data

	# ARC-002: прямой тестовый бой из меню, не с карты — на случай, если
	# came_from_map остался true после предыдущего боя, начатого с карты.
	MatchSettings.came_from_map = false
	MatchSettings.current_map_node = null
	# ARC-016/ARC-095: не должна протечь колода забега из предыдущей кампании —
	# это отдельный тестовый бой, не часть забега, setup_match() должен взять
	# полный пул уникальных карт игры (_build_full_card_pool()), не run_deck.
	MatchSettings.run_deck = []
	# ARC-012/013/015: аналогично — не должны протечь золото/бонусы/артефакты прошлой кампании.
	MatchSettings.run_gold = 0
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0
	MatchSettings.run_artifacts = []


## ARC-095: по одной всегда доступной кнопке на каждую известную стратегию
## ИИ — позволяет вручную проверить, как конкретный (не случайный) профиль
## играет против полной колоды тестового боя. Тот же паттерн, что уже
## используется в world_map_screen.gd::_generate_debug_node_bar() —
## CanvasLayer + HBoxContainer внизу экрана, только в debug-сборках, не
## попадёт в релизный экспорт для Яндекс Игр.
func _generate_debug_ai_picker_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -44
	row.offset_bottom = 0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	layer.add_child(row)

	var strategy_scripts := {
		"Default": DefaultAIStrategyScript,
		"Aggressive": AggressiveAIStrategyScript,
		"Builder": BuilderAIStrategyScript,
		"Economist": EconomistAIStrategyScript,
		"Boss": BossAIStrategyScript,
	}
	for strategy_name in strategy_scripts:
		var button := Button.new()
		button.text = "DBG: vs %s" % strategy_name
		button.modulate = Color(1.0, 0.85, 0.3)
		button.pressed.connect(_start_test_battle.bind(strategy_scripts[strategy_name].new()))
		row.add_child(button)


func _on_settings_pressed():
	get_tree().change_scene_to_file("res://ui/settings/settings_screen.tscn")


## ARC-046: «Колода», «Прокачка» и «Статистика» были тремя отдельными
## кнопками/экранами — теперь один "Профиль" открывает единый экран с
## вкладками (ui/profile/profile_screen.tscn), см. блокквот ARC-046 в
## docs/dev_plan_tickets.md.
func _on_profile_pressed():
	get_tree().change_scene_to_file("res://ui/profile/profile_screen.tscn")
