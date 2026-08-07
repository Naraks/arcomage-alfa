extends GutTest
## Тесты колод и карточных пулов.


func test_setup_match_uses_run_deck_when_provided() -> void:
	var marker_card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	var run_deck: Array[CardData] = [marker_card]
	for i in range(11):
		run_deck.append(TestFixtures.make_card(1, CardData.ResourceType.BRICKS))

	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player(), run_deck)

	var everywhere: Array = MatchManager.deck + MatchManager.player_hand + MatchManager.enemy_hand
	assert_true(
		everywhere.has(marker_card),
		"Карта из run_deck должна оказаться в бою — в колоде или в чьей-то руке после раздачи"
	)


func test_setup_match_falls_back_to_test_deck_when_run_deck_empty() -> void:
	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player())

	assert_false(
		MatchManager.deck.is_empty(),
		"Без run_deck (дефолт []) должна использоваться тестовая колода"
	)


func test_setup_match_without_run_deck_uses_full_card_pool() -> void:
	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player())

	assert_eq(
		MatchManager.deck.size() + MatchManager.player_hand.size(),
		MatchManager.ALL_CARD_PATHS.size(),
		"Колода игрока в тестовом бою без забега должна быть полным пулом всех карт"
	)
	assert_eq(
		MatchManager.enemy_deck.size() + MatchManager.enemy_hand.size(),
		MatchManager.ALL_CARD_PATHS.size(),
		"Колода ИИ в тестовом бою без забега тоже должна быть полным пулом всех карт"
	)


func test_setup_match_with_run_deck_does_not_touch_full_card_pool() -> void:
	var run_deck: Array[CardData] = []
	for i in range(12):
		run_deck.append(TestFixtures.make_card(1, CardData.ResourceType.BRICKS))

	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player(), run_deck)

	assert_lt(
		MatchManager.enemy_deck.size() + MatchManager.enemy_hand.size(),
		MatchManager.ALL_CARD_PATHS.size(),
		"В реальном забеге колода ИИ должна остаться генерик-пулом, не полным"
	)


func test_ai_does_not_draw_from_players_run_deck() -> void:
	var marker_card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	var run_deck: Array[CardData] = [marker_card]
	for i in range(19):
		run_deck.append(TestFixtures.make_card(1, CardData.ResourceType.BRICKS))

	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player(), run_deck)

	assert_false(
		MatchManager.enemy_hand.has(marker_card) or MatchManager.enemy_deck.has(marker_card),
		"Карта из run_deck игрока не должна попадать ни в руку, ни в колоду ИИ"
	)
	assert_true(
		MatchManager.deck.has(marker_card) or MatchManager.player_hand.has(marker_card),
		"Карта из run_deck должна остаться доступна игроку — в его колоде или руке"
	)


func test_setup_match_gives_enemy_independent_deck() -> void:
	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player())

	assert_false(
		MatchManager.enemy_deck.is_empty(),
		"У ИИ должна быть своя непустая колода после setup_match"
	)

	var enemy_deck_size_before: int = MatchManager.enemy_deck.size()
	MatchManager.deck.pop_back()

	assert_eq(
		MatchManager.enemy_deck.size(),
		enemy_deck_size_before,
		"Колода ИИ не должна меняться при изменении колоды игрока — это независимые массивы"
	)


func test_setup_match_does_not_mutate_caller_run_deck() -> void:
	var run_deck: Array[CardData] = []
	for i in range(12):
		run_deck.append(TestFixtures.make_card(1, CardData.ResourceType.BRICKS))
	var original_size: int = run_deck.size()

	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player(), run_deck)

	assert_eq(
		run_deck.size(),
		original_size,
		"setup_match кладёт в бой шафл-копию run_deck — сама run_deck не должна расходоваться за бой"
	)


func test_build_starting_run_deck_is_not_empty() -> void:
	var starting_deck: Array[CardData] = MatchManager.build_starting_run_deck()

	assert_false(starting_deck.is_empty(), "Стартовая колода забега не должна быть пустой")


func test_build_starting_run_deck_survives_initial_draw() -> void:
	var starting_deck: Array[CardData] = MatchManager.build_starting_run_deck()

	assert_gt(
		starting_deck.size(),
		10,
		"Стартовая колода должна пережить начальную раздачу (5 игроку + 5 ИИ) с запасом"
	)


func test_build_shop_offer_returns_requested_count() -> void:
	var offer: Array[CardData] = MatchManager.build_shop_offer(4)

	assert_eq(offer.size(), 4, "Магазин должен предложить ровно запрошенное число карт")


func test_build_shop_offer_has_no_duplicate_cards() -> void:
	var offer: Array[CardData] = MatchManager.build_shop_offer(5)

	var seen := {}
	for card in offer:
		assert_false(seen.has(card), "Предложение магазина не должно повторять одну и ту же карту")
		seen[card] = true


func test_build_shop_offer_clamps_to_pool_size_without_error() -> void:
	var saved_unlocked: Array = ProfileManager.profile.get("unlocked_cards", []).duplicate()
	ProfileManager.profile["unlocked_cards"] = MatchManager.ALL_CARD_PATHS.duplicate()

	var huge_count: int = MatchManager.ALL_CARD_PATHS.size() + 10
	var offer: Array[CardData] = MatchManager.build_shop_offer(huge_count)

	assert_eq(
		offer.size(),
		MatchManager.ALL_CARD_PATHS.size(),
		"Запрос больше размера пула должен просто вернуть весь пул без ошибок и без повторов"
	)

	ProfileManager.profile["unlocked_cards"] = saved_unlocked
