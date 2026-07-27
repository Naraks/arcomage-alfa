extends GutTest
## Юнит-тесты MatchManager (ARC-073). MatchManager — autoload-синглтон,
## поэтому тесты используют его напрямую, приводя состояние к известному
## в before_each(), а не создают отдельный экземпляр.

var player: PlayerData
var enemy: PlayerData


func before_each() -> void:
	player = PlayerData.new()
	player.tower_hp = 20
	player.wall_hp = 5
	player.bricks = 5
	player.gems = 5
	player.beasts = 5

	enemy = PlayerData.new()
	enemy.tower_hp = 20
	enemy.wall_hp = 5
	enemy.bricks = 5
	enemy.gems = 5
	enemy.beasts = 5

	MatchManager.player_data = player
	MatchManager.enemy_data = enemy
	MatchManager.player_hand = []
	MatchManager.enemy_hand = []
	MatchManager.current_state = MatchManager.State.PLAYER_TURN


func _make_card(
	cost: int, type: CardData.ResourceType, effects: Array[Dictionary] = []
) -> CardData:
	var card := CardData.new()
	card.cost = cost
	card.type = type
	card.effects = effects
	return card


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


# --- can_afford ---


func test_can_afford_true_when_enough_bricks() -> void:
	var card := _make_card(3, CardData.ResourceType.BRICKS)
	assert_true(MatchManager.can_afford(card, player))


func test_can_afford_false_when_not_enough_bricks() -> void:
	var card := _make_card(10, CardData.ResourceType.BRICKS)
	assert_false(MatchManager.can_afford(card, player))


func test_can_afford_true_when_enough_gems() -> void:
	var card := _make_card(5, CardData.ResourceType.GEMS)
	assert_true(MatchManager.can_afford(card, player))


func test_can_afford_true_when_enough_beasts() -> void:
	var card := _make_card(5, CardData.ResourceType.BEASTS)
	assert_true(MatchManager.can_afford(card, player))


# --- play_card_by_index ---


func test_play_card_by_index_deducts_resources() -> void:
	var card := _make_card(3, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(player.bricks, 2, "Стоимость карты должна списаться с нужного ресурса")


func test_play_card_by_index_removes_card_from_hand() -> void:
	var card := _make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 0, "Сыгранная карта должна уйти из руки")


func test_play_card_by_index_blocked_when_cannot_afford() -> void:
	var card := _make_card(999, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 1, "Карта не должна разыграться без ресурсов")
	assert_eq(player.bricks, 5, "Ресурсы не должны списаться при неудачной попытке")


func test_play_card_by_index_blocked_outside_turn_states() -> void:
	MatchManager.current_state = MatchManager.State.END_MATCH
	var card := _make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 1, "Вне PLAYER_TURN/AI_TURN карту разыграть нельзя")


func test_play_card_by_index_applies_direct_damage_effect() -> void:
	var card := _make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "direct_damage", "value": 4, "target": "enemy"}]
	)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(enemy.tower_hp, 16, "direct_damage должен уйти врагу напрямую в башню, игнорируя стену")


# --- discard_card_by_index ---


func test_discard_card_by_index_removes_card() -> void:
	var card := _make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.discard_card_by_index(0, player)
	assert_eq(MatchManager.player_hand.size(), 0, "Сброшенная карта должна уйти из руки")


func test_discard_card_by_index_blocked_for_wrong_actor_on_player_turn() -> void:
	var card := _make_card(1, CardData.ResourceType.BRICKS)
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


# --- setup_match / execute_ai_turn ---
# Регрессия: в реальной игре enemy_data создаётся "на лету" (world_map_screen.gd,
# main_menu.gd) без ai_strategy. execute_ai_turn() падал на проверке ai_strategy и
# выходил, ни разу не вызвав end_turn() — ход навсегда зависал в AI_TURN, игрок не
# мог продолжить матч. Тесты ниже покрывают и исходную причину (setup_match теперь
# сам назначает стратегию по умолчанию), и саму execute_ai_turn как страховку на
# случай, если её вызовут в обход setup_match.


func test_setup_match_assigns_default_ai_strategy_when_missing() -> void:
	var p := PlayerData.new()
	var e := PlayerData.new()
	e.ai_strategy = null

	MatchManager.setup_match(p, e)

	assert_not_null(
		MatchManager.enemy_data.ai_strategy,
		"setup_match должен назначить стратегию ИИ по умолчанию, если она не задана"
	)


func test_execute_ai_turn_returns_turn_to_player_when_ai_strategy_missing() -> void:
	enemy.ai_strategy = null
	MatchManager.current_state = MatchManager.State.AI_TURN
	MatchManager.enemy_hand = [_make_card(1, CardData.ResourceType.BRICKS)]

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
