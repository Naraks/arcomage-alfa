extends GutTest
## Тесты просмотра колоды.

const DeckScreenScript = preload("res://ui/deck/deck_screen.gd")


func _make_card(type: int, cost: int, card_name: String) -> CardData:
	var card := CardData.new()
	card.type = type
	card.cost = cost
	card.card_name = card_name
	return card


func test_group_cards_counts_duplicate_references() -> void:
	var screen = DeckScreenScript.new()
	var brick := _make_card(CardData.ResourceType.BRICKS, 1, "Каменоломня")
	var gem := _make_card(CardData.ResourceType.GEMS, 2, "Огненный шар")

	var deck: Array[CardData] = [brick, brick, gem, brick]
	var grouped := screen._group_cards(deck)

	assert_eq(grouped.size(), 2, "Два уникальных ресурса CardData -> две сгруппированные строки")

	var by_name := {}
	for entry in grouped:
		by_name[entry["card"].card_name] = entry["count"]

	assert_eq(by_name["Каменоломня"], 3)
	assert_eq(by_name["Огненный шар"], 1)

	screen.free()


func test_group_cards_sorts_by_type_then_cost_then_name() -> void:
	var screen = DeckScreenScript.new()

	var gems_5 := _make_card(CardData.ResourceType.GEMS, 5, "Ж")
	var bricks_1 := _make_card(CardData.ResourceType.BRICKS, 1, "А")
	var bricks_3 := _make_card(CardData.ResourceType.BRICKS, 3, "Б")
	var bricks_3_other_name := _make_card(CardData.ResourceType.BRICKS, 3, "Я")

	var deck: Array[CardData] = [gems_5, bricks_3_other_name, bricks_1, bricks_3]
	var grouped := screen._group_cards(deck)

	var ordered_names: Array = []
	for entry in grouped:
		ordered_names.append(entry["card"].card_name)

	assert_eq(ordered_names, ["А", "Б", "Я", "Ж"])

	screen.free()


func test_group_cards_empty_deck_returns_empty_array() -> void:
	var screen = DeckScreenScript.new()

	var grouped := screen._group_cards([])

	assert_eq(grouped, [])

	screen.free()


func test_compare_cards_sorts_by_type_then_cost_then_name() -> void:
	var screen = DeckScreenScript.new()

	var gems_5 := _make_card(CardData.ResourceType.GEMS, 5, "Ж")
	var bricks_1 := _make_card(CardData.ResourceType.BRICKS, 1, "А")
	var bricks_3 := _make_card(CardData.ResourceType.BRICKS, 3, "Б")
	var bricks_3_other_name := _make_card(CardData.ResourceType.BRICKS, 3, "Я")

	var cards: Array = [gems_5, bricks_3_other_name, bricks_1, bricks_3]
	cards.sort_custom(screen._compare_cards)

	assert_eq(cards, [bricks_1, bricks_3, bricks_3_other_name, gems_5])

	screen.free()
