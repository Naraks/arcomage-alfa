extends GutTest
## Юнит-тесты чистых хелперов DeckScreen (ARC-041): группировка одинаковых
## карт по количеству и сортировка. Экземпляр создаётся через preload().new()
## без добавления в дерево сцены, как в tests/test_shop_screen.gd —
## _group_cards()/_compare_cards() не трогают @onready-поля
## (_deck_list/_source_label, заполняются только в _build_ui()).
##
## _load_deck_to_show() (какую колоду показать — текущий забег или превью
## стартовой) намеренно не тестируется здесь: она читает реальный
## RunSaveManager.has_saved_run()/load_run() (файловый I/O в user://), а этот
## путь в проекте нигде не покрыт GUT-тестами — то же решение, что и для
## RunSaveManager.save_run()/load_run() самих по себе (см. блокквот ARC-018
## в dev_plan_tickets.md: "штатно работает в реальном Godot... нужна ручная
## проверка в редакторе").

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
