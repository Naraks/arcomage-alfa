extends GutTest
## Юнит-тесты ShopScreen (ARC-012, UI 06/13): цена, покупка, недостаток
## золота, защищённое удаление, отмена и блокировка повторного ввода.

const ShopScreenScript = preload("res://ui/shop/shop_screen.gd")


func before_each() -> void:
	MatchSettings.run_gold = 0
	MatchSettings.run_deck.clear()


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


func test_purchase_adds_card_and_deducts_gold_once() -> void:
	var screen = ShopScreenScript.new()
	var card := _make_card(CardData.ResourceType.BRICKS, 3, "Покупка")
	screen._shop_offer.append(card)
	MatchSettings.run_gold = 10

	assert_true(screen._try_buy_card(card))
	assert_false(screen._try_buy_card(card), "Уже купленный товар нельзя оплатить повторно")
	assert_eq(MatchSettings.run_gold, 4)
	assert_eq(MatchSettings.run_deck, [card])
	assert_eq(screen._offer_state(card).reason, "Уже куплено")

	screen.free()


func test_purchase_with_insufficient_gold_changes_nothing() -> void:
	var screen = ShopScreenScript.new()
	var card := _make_card(CardData.ResourceType.GEMS, 4, "Дорогая")
	screen._shop_offer.append(card)
	MatchSettings.run_gold = 7

	assert_false(screen._try_buy_card(card))
	assert_eq(MatchSettings.run_gold, 7)
	assert_true(MatchSettings.run_deck.is_empty())
	assert_eq(screen._offer_state(card).reason, "Недостаточно золота")

	screen.free()


func test_input_during_transaction_cannot_purchase() -> void:
	var screen = ShopScreenScript.new()
	var card := _make_card(CardData.ResourceType.GEMS, 2, "Защищённая")
	screen._shop_offer.append(card)
	MatchSettings.run_gold = 10
	screen._transaction_in_progress = true

	assert_false(screen._try_buy_card(card))
	assert_eq(MatchSettings.run_gold, 10)
	assert_true(MatchSettings.run_deck.is_empty())

	screen.free()


func test_confirmed_removal_deducts_gold_and_removes_selected_card() -> void:
	var screen = ShopScreenScript.new()
	var first := _make_card(CardData.ResourceType.BRICKS, 1, "Первая")
	var second := _make_card(CardData.ResourceType.GEMS, 2, "Вторая")
	MatchSettings.run_deck.assign([first, second])
	MatchSettings.run_gold = 10

	assert_true(screen._request_removal(1))
	assert_eq(MatchSettings.run_deck.size(), 2, "До подтверждения колода не меняется")
	assert_true(screen._confirm_removal())
	assert_false(screen._confirm_removal(), "Повторное подтверждение не должно списывать золото")
	assert_eq(MatchSettings.run_gold, 5)
	assert_eq(MatchSettings.run_deck, [first])

	screen.free()


func test_cancel_removal_preserves_deck_and_gold() -> void:
	var screen = ShopScreenScript.new()
	var first := _make_card(CardData.ResourceType.BRICKS, 1, "Первая")
	var second := _make_card(CardData.ResourceType.GEMS, 2, "Вторая")
	MatchSettings.run_deck.assign([first, second])
	MatchSettings.run_gold = 10

	assert_true(screen._request_removal(0))
	screen._cancel_removal()
	assert_false(screen._confirm_removal())
	assert_eq(MatchSettings.run_gold, 10)
	assert_eq(MatchSettings.run_deck, [first, second])

	screen.free()


func test_last_card_cannot_be_removed() -> void:
	var screen = ShopScreenScript.new()
	MatchSettings.run_deck.append(_make_card(CardData.ResourceType.BEASTS, 1, "Последняя"))
	MatchSettings.run_gold = 10

	assert_false(screen._request_removal(0))
	assert_eq(screen._removal_block_reason(0), "Нельзя удалить последнюю карту")
	assert_eq(MatchSettings.run_gold, 10)
	assert_eq(MatchSettings.run_deck.size(), 1)

	screen.free()


func test_portrait_layout_has_dedicated_mode() -> void:
	var screen = ShopScreenScript.new()

	assert_eq(screen._layout_mode_for_size(Vector2(720, 1280)), "portrait")
	assert_eq(screen._layout_mode_for_size(Vector2(1280, 720)), "wide")

	screen.free()
