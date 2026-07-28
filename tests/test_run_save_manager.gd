extends GutTest
## Юнит-тесты RunSaveManager (ARC-018). RunSaveManager — autoload, как
## ProfileManager/MatchManager — тесты приводят состояние MatchSettings к
## известному в before_each()/after_each(), как test_rest_screen.gd делает для
## run_*_bonus. Проверяются только build_save_data()/apply_save_data() —
## чистый маппинг полей без обращения к диску (save_run()/load_run()/
## clear_run() читают/пишут user://, что штатно работает в реальном Godot, но
## незачем гонять файловый I/O ради проверки логики маппинга).

const WorldMapData = preload("res://data/resources/world_map_data.gd")


func before_each() -> void:
	MatchSettings.world_map_data = null
	MatchSettings.run_deck = []
	MatchSettings.run_gold = 0
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0
	MatchSettings.run_artifacts = []


func after_each() -> void:
	MatchSettings.world_map_data = null
	MatchSettings.run_deck = []
	MatchSettings.run_gold = 0
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0
	MatchSettings.run_artifacts = []


func test_build_save_data_copies_all_run_fields() -> void:
	var map := WorldMapData.new()
	MatchSettings.world_map_data = map
	MatchSettings.run_deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchSettings.run_gold = 42
	MatchSettings.run_tower_bonus = 5
	MatchSettings.run_quarry_bonus = 2
	MatchSettings.run_magic_bonus = 3
	MatchSettings.run_dungeon_bonus = 4
	MatchSettings.run_artifacts = [TestFixtures.make_artifact()]

	var data := RunSaveManager.build_save_data()

	assert_eq(data.world_map_data, map)
	assert_eq(data.run_deck, MatchSettings.run_deck)
	assert_eq(data.run_gold, 42)
	assert_eq(data.run_tower_bonus, 5)
	assert_eq(data.run_quarry_bonus, 2)
	assert_eq(data.run_magic_bonus, 3)
	assert_eq(data.run_dungeon_bonus, 4)
	assert_eq(data.run_artifacts, MatchSettings.run_artifacts)


func test_build_save_data_duplicates_arrays_not_same_reference() -> void:
	# run_deck/run_artifacts должны копироваться (duplicate()), а не шариться
	# по ссылке — иначе дальнейшие изменения MatchSettings.run_deck/
	# run_artifacts после сохранения незаметно "просочились" бы в уже
	# сохранённый снимок. (Array == сравнивает содержимое, а не ссылку, так
	# что тут проверяем эффект мутации, а не assert_ne по значению.)
	MatchSettings.run_deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchSettings.run_artifacts = [TestFixtures.make_artifact()]

	var data := RunSaveManager.build_save_data()
	MatchSettings.run_deck.append(TestFixtures.make_card(2, CardData.ResourceType.GEMS))
	MatchSettings.run_artifacts.append(TestFixtures.make_artifact())

	assert_eq(
		data.run_deck.size(), 1, "Снимок run_deck не должен расти при мутации MatchSettings.run_deck после сохранения"
	)
	assert_eq(
		data.run_artifacts.size(),
		1,
		"Снимок run_artifacts не должен расти при мутации MatchSettings.run_artifacts после сохранения"
	)


func test_apply_save_data_restores_all_run_fields_into_match_settings() -> void:
	var data := RunSaveData.new()
	var map := WorldMapData.new()
	data.world_map_data = map
	data.run_deck = [TestFixtures.make_card(2, CardData.ResourceType.GEMS)]
	data.run_gold = 17
	data.run_tower_bonus = 1
	data.run_quarry_bonus = 2
	data.run_magic_bonus = 3
	data.run_dungeon_bonus = 4
	data.run_artifacts = [TestFixtures.make_artifact()]

	RunSaveManager.apply_save_data(data)

	assert_eq(MatchSettings.world_map_data, map)
	assert_eq(MatchSettings.run_deck, data.run_deck)
	assert_eq(MatchSettings.run_gold, 17)
	assert_eq(MatchSettings.run_tower_bonus, 1)
	assert_eq(MatchSettings.run_quarry_bonus, 2)
	assert_eq(MatchSettings.run_magic_bonus, 3)
	assert_eq(MatchSettings.run_dungeon_bonus, 4)
	assert_eq(MatchSettings.run_artifacts, data.run_artifacts)


func test_build_then_apply_round_trip_preserves_state() -> void:
	var map := WorldMapData.new()
	MatchSettings.world_map_data = map
	MatchSettings.run_deck = [TestFixtures.make_card(3, CardData.ResourceType.BEASTS)]
	MatchSettings.run_gold = 9
	MatchSettings.run_tower_bonus = 6
	MatchSettings.run_quarry_bonus = 7
	MatchSettings.run_magic_bonus = 8
	MatchSettings.run_dungeon_bonus = 9
	MatchSettings.run_artifacts = [TestFixtures.make_artifact()]

	var data := RunSaveManager.build_save_data()
	# Имитация "закрыли вкладку и открыли заново" — состояние в MatchSettings
	# сбрасывается, восстанавливаем его только из снимка.
	before_each()

	RunSaveManager.apply_save_data(data)

	assert_eq(MatchSettings.world_map_data, map)
	assert_eq(MatchSettings.run_gold, 9)
	assert_eq(MatchSettings.run_tower_bonus, 6)
	assert_eq(MatchSettings.run_quarry_bonus, 7)
	assert_eq(MatchSettings.run_magic_bonus, 8)
	assert_eq(MatchSettings.run_dungeon_bonus, 9)
	assert_eq(MatchSettings.run_deck.size(), 1)
	assert_eq(MatchSettings.run_artifacts.size(), 1)
