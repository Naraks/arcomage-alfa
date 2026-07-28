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
