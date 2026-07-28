extends GutTest
## Юнит-тесты чистых хелперов ShopScreen (ARC-012): цена покупки и сортировка
## карт. Экземпляр создаётся через load().new() без добавления в дерево сцены,
## как в tests/test_battle_screen.gd — методы не трогают @onready-поля.

const ShopScreenScript = preload("res://ui/shop/shop_screen.gd")


func _make_card(type: int, cost: int, card_name: String) -> CardData:
	var card := CardData.new()
	card.type = type
	card.cost = cost
	card.card_name = card_name
	return card


func test_card_price_scales_with_cost() -> void:
	var screen = ShopScreenScript.new()

	var cheap := _make_card(CardData.ResourceType.BRICKS, 1, "Дешёвая")
	var expensive := _make_card(CardData.ResourceType.BRICKS, 5, "Дорогая")

	assert_eq(screen._card_price(cheap), 1 * ShopScreenScript.CARD_PRICE_MULTIPLIER)
	assert_eq(screen._card_price(expensive), 5 * ShopScreenScript.CARD_PRICE_MULTIPLIER)

	screen.free()


func test_card_price_is_never_zero_for_zero_cost_card() -> void:
	var screen = ShopScreenScript.new()

	var free_card := _make_card(CardData.ResourceType.BRICKS, 0, "Бесплатная")

	assert_eq(screen._card_price(free_card), 1, "Цена не должна опускаться до 0 золота")

	screen.free()


func test_compare_cards_sorts_by_type_then_cost_then_name() -> void:
	var screen = ShopScreenScript.new()

	var gems_5 := _make_card(CardData.ResourceType.GEMS, 5, "Ж")
	var bricks_1 := _make_card(CardData.ResourceType.BRICKS, 1, "А")
	var bricks_3 := _make_card(CardData.ResourceType.BRICKS, 3, "Б")
	var bricks_3_other_name := _make_card(CardData.ResourceType.BRICKS, 3, "Я")

	var cards: Array = [gems_5, bricks_3_other_name, bricks_1, bricks_3]
	cards.sort_custom(screen._compare_cards)

	assert_eq(
		cards,
		[bricks_1, bricks_3, bricks_3_other_name, gems_5],
		"Сортировка: сначала по типу ресурса, затем по стоимости, затем по имени"
	)

	screen.free()
