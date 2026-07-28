extends GutTest
## Юнит-тест BattleScreen._compare_cards_for_view() (ARC-016 — попап просмотра
## колоды сортирует карты для читаемости вместо показа реального порядка тяги).
##
## battle_screen.gd — обычный Control-скрипт сцены (без class_name), поэтому
## экземпляр создаётся через load().new() и НЕ добавляется в дерево сцены:
## _compare_cards_for_view() не трогает @onready-поля/сцену, только сравнивает
## два переданных CardData.

const BattleScreenScript = preload("res://ui/battle/battle_screen.gd")


func _make_card(type: int, cost: int, card_name: String) -> CardData:
	var card := CardData.new()
	card.type = type
	card.cost = cost
	card.card_name = card_name
	return card


func test_compare_cards_sorts_by_type_then_cost_then_name() -> void:
	var screen = BattleScreenScript.new()

	var gems_5 := _make_card(CardData.ResourceType.GEMS, 5, "Ж")
	var bricks_1 := _make_card(CardData.ResourceType.BRICKS, 1, "А")
	var bricks_3 := _make_card(CardData.ResourceType.BRICKS, 3, "Б")
	var bricks_3_other_name := _make_card(CardData.ResourceType.BRICKS, 3, "Я")

	var cards: Array = [gems_5, bricks_3_other_name, bricks_1, bricks_3]
	cards.sort_custom(screen._compare_cards_for_view)

	assert_eq(
		cards,
		[bricks_1, bricks_3, bricks_3_other_name, gems_5],
		"Сортировка: сначала по типу ресурса, затем по стоимости, затем по имени"
	)

	screen.free()


## ARC-028: _has_playable_card() читает MatchManager.player_hand/player_data
## напрямую (тот же паттерн, что в tests/test_match_manager.gd) — не требует
## сцены/@onready-полей, поэтому screen.new() без add_child здесь тоже ок.

var _prev_player_data: PlayerData
var _prev_player_hand: Array


func before_each() -> void:
	_prev_player_data = MatchManager.player_data
	_prev_player_hand = MatchManager.player_hand
	MatchManager.player_data = TestFixtures.make_player()


func after_each() -> void:
	MatchManager.player_data = _prev_player_data
	MatchManager.player_hand = _prev_player_hand


func test_has_playable_card_true_when_affordable_card_in_hand() -> void:
	var screen = BattleScreenScript.new()
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]

	assert_true(screen._has_playable_card(), "Карта по карману (bricks=5 >= cost=1) должна считаться играбельной")

	screen.free()


func test_has_playable_card_false_when_nothing_affordable() -> void:
	var screen = BattleScreenScript.new()
	MatchManager.player_hand = [
		TestFixtures.make_card(99, CardData.ResourceType.BRICKS),
		TestFixtures.make_card(99, CardData.ResourceType.GEMS),
	]

	assert_false(screen._has_playable_card(), "Ни одна карта не по карману (cost=99) — играбельных нет")

	screen.free()


func test_has_playable_card_false_when_hand_empty() -> void:
	var screen = BattleScreenScript.new()
	MatchManager.player_hand = []

	assert_false(screen._has_playable_card(), "Пустая рука — играбельных карт нет")

	screen.free()
