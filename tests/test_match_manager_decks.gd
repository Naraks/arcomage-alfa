extends GutTest
## Юнит-тесты MatchManager, связанные с колодами/пулами карт (ARC-016 run_deck,
## ARC-012 build_shop_offer, ARC-095 полный пул для тестового боя).
##
## Вынесено из test_match_manager.gd отдельным файлом (не по сути, а по
## необходимости): gdlint max-file-lines (порог 1000) не даёт держать всё в
## одном файле, а per-file/per-directory override gdlint не поддерживает (та
## же причина, по которой max-public-methods отключено целиком в .gdlintrc,
## см. комментарий там). Этот блок тестов не зависел от before_each()/player/
## enemy основного файла (каждый тест сам строит PlayerData через
## TestFixtures.make_player()), поэтому перенос — чистый copy-paste без
## изменения логики.


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
	# ARC-095: тестовый бой без забега («Битва» в главном меню) теперь берёт
	# полный пул уникальных карт (ALL_CARD_PATHS), а не урезанный 11-карточный
	# STARTER_DECK_CARD_PATHS с паддингом до 20. Начальная раздача (5 карт)
	# уже ушла в руку, поэтому сравниваем deck+hand, а не только deck.
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
	# Реальный забег (p_run_deck непустой) не должен затрагиваться ARC-095 —
	# колода ИИ там как раньше, из урезанного генерик-пула (<= 20 карт).
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
	# Раньше игрок и ИИ делили один общий deck — уникальная карта из run_deck
	# игрока могла оказаться в руке ИИ. Теперь у ИИ отдельная колода (enemy_deck).
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
	# Регрессия: без паддинга стартовая колода (11 карт) почти опустошалась уже
	# начальной раздачей setup_match() (5 игроку + 5 ИИ) — оставалась 1 карта.
	var starting_deck: Array[CardData] = MatchManager.build_starting_run_deck()

	assert_gt(
		starting_deck.size(),
		10,
		"Стартовая колода должна пережить начальную раздачу (5 игроку + 5 ИИ) с запасом"
	)


# ARC-012: предложение магазина (MatchManager.build_shop_offer).


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
	# ARC-038: build_shop_offer() теперь фильтрует RARE-карты, не купленные за
	# Славу (ProfileManager.is_card_unlocked()) — без этого при 0 разблокировок
	# по умолчанию фактически доступный пул меньше ALL_CARD_PATHS.size(), и
	# сравнение ниже сломалось бы ещё до проверки самого клэмпа. Разблокируем
	# всё явно, чтобы тест проверял именно клэмп, а не фильтр (у фильтра свои
	# тесты в test_profile_manager.gd/test_reward_screen.gd).
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
