extends GutTest
## Юнит-тесты MatchManager (ARC-073). MatchManager — autoload-синглтон,
## поэтому тесты используют его напрямую, приводя состояние к известному
## в before_each(), а не создают отдельный экземпляр.
##
## PlayerData/CardData собираются через TestFixtures (ARC-074, tests/fixtures.gd) —
## не читаются из боевого контента data/cards/*.tres, который часто меняется
## из-за баланса (Эпик C) и не должен ломать тесты логики.

var player: PlayerData
var enemy: PlayerData


func before_each() -> void:
	player = TestFixtures.make_player()
	enemy = TestFixtures.make_player()

	MatchManager.player_data = player
	MatchManager.enemy_data = enemy
	MatchManager.player_hand = []
	MatchManager.enemy_hand = []
	MatchManager.current_state = MatchManager.State.PLAYER_TURN


# --- apply_damage ---


func test_apply_damage_reduces_wall_first() -> void:
	MatchManager.apply_damage(3, player, false)
	assert_eq(player.wall_hp, 2, "Урон меньше HP стены должен полностью уйти в стену")
	assert_eq(player.tower_hp, 20, "Башня не должна пострадать, пока цела стена")


func test_apply_damage_overflows_to_tower_when_wall_insufficient() -> void:
	player.wall_hp = 2
	MatchManager.apply_damage(5, player, false)
	assert_eq(player.wall_hp, 0, "Стена не может уйти в минус")
	assert_eq(player.tower_hp, 17, "Излишек урона (3) должен уйти в башню")


func test_apply_damage_ignore_wall_hits_tower_directly() -> void:
	MatchManager.apply_damage(5, player, true)
	assert_eq(player.wall_hp, 5, "Стена не должна пострадать при ignore_wall = true")
	assert_eq(player.tower_hp, 15, "Весь урон должен уйти напрямую в башню")


# --- draw_card / max_hand_size (ARC-003) ---


func test_draw_card_does_not_exceed_max_hand_size() -> void:
	player.max_hand_size = 2
	MatchManager.player_hand = [
		TestFixtures.make_card(1, CardData.ResourceType.BRICKS),
		TestFixtures.make_card(1, CardData.ResourceType.BRICKS),
	]
	MatchManager.deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]

	MatchManager.draw_card(player)

	assert_eq(MatchManager.player_hand.size(), 2, "Рука не должна превышать max_hand_size")
	assert_eq(MatchManager.deck.size(), 1, "Карта должна остаться в колоде, а не потеряться")


func test_draw_card_draws_normally_below_max_hand_size() -> void:
	player.max_hand_size = 2
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchManager.deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]

	MatchManager.draw_card(player)

	assert_eq(MatchManager.player_hand.size(), 2, "Рука ниже лимита должна пополняться как обычно")
	assert_eq(MatchManager.deck.size(), 0, "Карта должна уйти из колоды в руку")


# --- can_afford ---


func test_can_afford_true_when_enough_bricks() -> void:
	var card := TestFixtures.make_card(3, CardData.ResourceType.BRICKS)
	assert_true(MatchManager.can_afford(card, player))


func test_can_afford_false_when_not_enough_bricks() -> void:
	var card := TestFixtures.make_card(10, CardData.ResourceType.BRICKS)
	assert_false(MatchManager.can_afford(card, player))


func test_can_afford_true_when_enough_gems() -> void:
	var card := TestFixtures.make_card(5, CardData.ResourceType.GEMS)
	assert_true(MatchManager.can_afford(card, player))


func test_can_afford_true_when_enough_beasts() -> void:
	var card := TestFixtures.make_card(5, CardData.ResourceType.BEASTS)
	assert_true(MatchManager.can_afford(card, player))


# --- play_card_by_index ---


func test_play_card_by_index_deducts_resources() -> void:
	var card := TestFixtures.make_card(3, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(player.bricks, 2, "Стоимость карты должна списаться с нужного ресурса")


func test_play_card_by_index_removes_card_from_hand() -> void:
	var card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 0, "Сыгранная карта должна уйти из руки")


func test_play_card_by_index_blocked_when_cannot_afford() -> void:
	var card := TestFixtures.make_card(999, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 1, "Карта не должна разыграться без ресурсов")
	assert_eq(player.bricks, 5, "Ресурсы не должны списаться при неудачной попытке")


func test_play_card_by_index_blocked_outside_turn_states() -> void:
	MatchManager.current_state = MatchManager.State.END_MATCH
	var card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 1, "Вне PLAYER_TURN/AI_TURN карту разыграть нельзя")


func test_play_card_by_index_applies_direct_damage_effect() -> void:
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "direct_damage", "value": 4, "target": "enemy"}]
	)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(enemy.tower_hp, 16, "direct_damage должен уйти врагу напрямую в башню, игнорируя стену")


# --- resolve_target (ARC-005) ---


func test_resolve_target_self_prefix_returns_actor() -> void:
	assert_eq(
		MatchManager.resolve_target(player, enemy, "self_wall"),
		player,
		"Префикс self (в т.ч. self_wall) должен резолвиться в actor"
	)


func test_resolve_target_non_self_returns_enemy() -> void:
	assert_eq(
		MatchManager.resolve_target(player, enemy, "enemy_wall"),
		enemy,
		"Всё, что не начинается с self, должно резолвиться в enemy"
	)


func test_apply_card_effects_build_wall_targets_enemy() -> void:
	# build_wall/build_tower уже поддерживают любой target (self/enemy) через
	# resolve_target() — отдельный generic "build" тип был избыточен и убран (ARC-005),
	# т.к. использовался ровно одной картой (wall_card.tres) и дублировал build_wall.
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_wall", "value": 3, "target": "enemy_wall"}]
	)
	MatchManager.player_hand = [card]
	var enemy_wall_before: int = enemy.wall_hp
	MatchManager.play_card_by_index(0, player)
	assert_eq(
		enemy.wall_hp, enemy_wall_before + 3, "build_wall с target=enemy_wall должен прибавлять wall_hp врагу"
	)


# --- discard_card_by_index ---


func test_discard_card_by_index_removes_card() -> void:
	var card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.discard_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 0, "Сброшенная карта должна уйти из руки")


func test_discard_card_by_index_blocked_for_wrong_actor_on_player_turn() -> void:
	var card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.enemy_hand = [card]
	MatchManager.discard_card_by_index(0, enemy)
	assert_eq(MatchManager.enemy_hand.size(), 1, "На ходу игрока ИИ не может сбрасывать карты")


# --- check_win ---


func test_check_win_false_when_no_condition_met() -> void:
	assert_false(MatchManager.check_win())


func test_check_win_true_when_tower_reaches_target_height() -> void:
	player.tower_hp = MatchManager.WIN_TOWER_HEIGHT
	assert_true(MatchManager.check_win())


func test_check_win_true_when_enemy_tower_destroyed() -> void:
	enemy.tower_hp = 0
	assert_true(MatchManager.check_win())


func test_check_win_true_when_resource_target_reached() -> void:
	player.bricks = MatchManager.WIN_RESOURCE_AMOUNT
	assert_true(MatchManager.check_win())


# --- setup_match / execute_ai_turn (регрессия ARC-078: зависающий ход ИИ) ---


func test_setup_match_assigns_default_ai_strategy_when_missing() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	e.ai_strategy = null

	MatchManager.setup_match(p, e)

	assert_not_null(
		MatchManager.enemy_data.ai_strategy,
		"setup_match должен назначить стратегию ИИ по умолчанию, если она не задана"
	)


func test_execute_ai_turn_returns_turn_to_player_when_ai_strategy_missing() -> void:
	enemy.ai_strategy = null
	MatchManager.current_state = MatchManager.State.AI_TURN
	MatchManager.enemy_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]

	await MatchManager.execute_ai_turn()

	assert_eq(
		MatchManager.current_state,
		MatchManager.State.PLAYER_TURN,
		"Ход должен вернуться к игроку, даже если у ИИ на момент хода не было стратегии"
	)


func test_execute_ai_turn_returns_turn_to_player_when_hand_empty() -> void:
	enemy.ai_strategy = load("res://data/resources/default_ai_strategy.gd").new()
	MatchManager.current_state = MatchManager.State.AI_TURN
	MatchManager.enemy_hand = []

	await MatchManager.execute_ai_turn()

	assert_eq(
		MatchManager.current_state,
		MatchManager.State.PLAYER_TURN,
		"Пустая рука ИИ не должна вешать ход — он обязан вернуться к игроку"
	)


# --- setup_match / ProfileManager (регрессия ARC-001: непримененные бонусы) ---


func test_setup_match_applies_profile_manager_bonuses() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var orig_tower_hp: int = p.tower_hp
	var orig_quarry: int = p.quarry
	var tower_hp_bonus: int = ProfileManager.profile.player_stats.tower_hp_bonus
	var resource_gain_bonus: int = ProfileManager.profile.player_stats.resource_gain_bonus

	MatchManager.setup_match(p, e)

	assert_eq(
		MatchManager.player_data.tower_hp,
		orig_tower_hp + tower_hp_bonus,
		"setup_match должен прибавить tower_hp_bonus из профиля к tower_hp игрока"
	)
	assert_eq(
		MatchManager.player_data.quarry,
		orig_quarry + resource_gain_bonus,
		"setup_match должен прибавить resource_gain_bonus из профиля к quarry игрока"
	)


# --- setup_match / повторный вызов (регрессия ARC-002: карта -> бой -> карта -> бой) ---


func test_setup_match_resets_hands_from_previous_match() -> void:
	# Раньше setup_match() дописывал новые карты поверх текущей руки, не очищая
	# её. Пока карту мира нельзя было пройти больше одного боя за сессию (сам
	# баг ARC-002), это было незаметно — теперь несколько боёв подряд реальны.
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchManager.enemy_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]

	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player())

	# 5 карт из начальной раздачи заполняют руку до max_hand_size (ARC-003);
	# доборная карта в start_turn(player_data) в конце setup_match() блокируется
	# лимитом руки, поэтому обе руки останавливаются на 5, а не копятся выше.
	assert_eq(MatchManager.player_hand.size(), 5, "Рука игрока должна начинаться с нуля, а не копиться")
	assert_eq(MatchManager.enemy_hand.size(), 5, "Рука ИИ должна начинаться с нуля, а не копиться")


# --- setup_match / run_deck (ARC-016: колода забега как отдельная сущность) ---


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

	assert_false(MatchManager.deck.is_empty(), "Без run_deck (дефолт []) должна использоваться тестовая колода")


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
