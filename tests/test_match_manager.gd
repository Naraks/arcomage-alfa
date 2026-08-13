extends GutTest
## Тесты правил матча.

const DEFAULT_AI_STRATEGY_PATH := "res://data/resources/default_ai_strategy.gd"
const DWARF_PICKAXE_PATH := "res://data/artifacts/dwarf_pickaxe.tres"

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
	MatchManager.auto_execute_ai_turn = true


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


func test_play_card_by_index_deducts_resources() -> void:
	var card := TestFixtures.make_card(3, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(player.bricks, 2, "Стоимость карты должна списаться с нужного ресурса")


func test_play_card_by_index_skips_payment_when_artifact_guarantees_it() -> void:
	var card := TestFixtures.make_card(3, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	player.active_artifacts = [
		TestFixtures.make_artifact(
			[{"trigger": "pre_play", "type": "skip_payment_chance", "value": 1.0}]
		)
	]

	MatchManager.play_card_by_index(0, player)

	assert_eq(
		player.bricks, 5, "С гарантированным skip_payment_chance ресурсы не должны списываться"
	)
	assert_eq(
		MatchManager.player_hand.size(), 0, "Карта всё равно должна разыграться и уйти из руки"
	)


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


func test_play_card_by_index_blocked_for_wrong_actor_on_player_turn() -> void:
	var card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	MatchManager.enemy_hand = [card]
	MatchManager.play_card_by_index(0, enemy)
	assert_eq(MatchManager.enemy_hand.size(), 1, "На ходу игрока ИИ не может разыгрывать карты")


func test_play_card_by_index_applies_direct_damage_effect() -> void:
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "direct_damage", "value": 4, "target": "enemy"}]
	)
	MatchManager.player_hand = [card]
	MatchManager.play_card_by_index(0, player)
	assert_eq(
		enemy.tower_hp, 16, "direct_damage должен уйти врагу напрямую в башню, игнорируя стену"
	)


func test_play_card_by_index_damage_triggers_reflect_damage_artifact_on_defender() -> void:
	enemy.active_artifacts = [
		TestFixtures.make_artifact(
			[{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}]
		)
	]
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "damage", "value": 3, "target": "enemy"}]
	)
	MatchManager.player_hand = [card]
	var player_tower_before: int = player.tower_hp

	MatchManager.play_card_by_index(0, player)

	assert_eq(
		player.tower_hp,
		player_tower_before - 2,
		"Урон по стене врага с Шипастой Стеной должен вернуть 2 урона атакующему"
	)


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
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.BRICKS,
		[{"type": "build_wall", "value": 3, "target": "enemy_wall"}]
	)
	MatchManager.player_hand = [card]
	var enemy_wall_before: int = enemy.wall_hp
	MatchManager.play_card_by_index(0, player)
	assert_eq(
		enemy.wall_hp,
		enemy_wall_before + 3,
		"build_wall с target=enemy_wall должен прибавлять wall_hp врагу"
	)


func test_effect_draw_card_draws_into_target_hand() -> void:
	MatchManager.deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "draw_card", "target": "self", "value": 1}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(
		MatchManager.player_hand.size(), 1, "draw_card с target=self должен пополнить руку actor'а"
	)
	assert_true(MatchManager.deck.is_empty(), "Карта должна уйти из колоды в руку")


func test_effect_draw_card_draws_multiple_cards_by_value() -> void:
	MatchManager.deck = [
		TestFixtures.make_card(1, CardData.ResourceType.BRICKS),
		TestFixtures.make_card(1, CardData.ResourceType.BRICKS),
	]
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "draw_card", "target": "self", "value": 2}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(
		MatchManager.player_hand.size(), 2, "value должен определять количество тянущихся карт"
	)


func test_effect_draw_card_respects_max_hand_size() -> void:
	player.max_hand_size = 1
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchManager.deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "draw_card", "target": "self", "value": 1}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(
		MatchManager.player_hand.size(), 1, "draw_card не должен превышать max_hand_size (ARC-003)"
	)
	assert_eq(MatchManager.deck.size(), 1, "Невытянутая карта должна остаться в колоде")


func test_effect_steal_resource_moves_amount_from_target_to_actor() -> void:
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 3}]
	)
	var enemy_gems_before: int = enemy.gems
	var player_gems_before: int = player.gems

	MatchManager.apply_card_effects(card, player)

	assert_eq(
		enemy.gems, enemy_gems_before - 3, "У цели (target=enemy) должно списаться value ресурса"
	)
	assert_eq(player.gems, player_gems_before + 3, "Actor должен получить украденное, а не target")


func test_effect_steal_resource_clamps_to_amount_available() -> void:
	enemy.gems = 2
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 5}]
	)
	var player_gems_before: int = player.gems

	MatchManager.apply_card_effects(card, player)

	assert_eq(enemy.gems, 0, "Нельзя увести ресурс цели в минус")
	assert_eq(
		player.gems,
		player_gems_before + 2,
		"Actor получает ровно столько, сколько реально украдено"
	)


func test_effect_conditional_applies_then_branch_when_condition_true() -> void:
	player.wall_hp = 2
	var card := (
		TestFixtures
		. make_card(
			1,
			CardData.ResourceType.BRICKS,
			[
				{
					"type": "conditional",
					"target": "self",
					"field": "wall_hp",
					"op": "<",
					"threshold": 3,
					"then": {"type": "build_wall", "target": "self", "value": 3},
					"else": {"type": "build_wall", "target": "self", "value": 1},
				}
			]
		)
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(player.wall_hp, 5, "wall_hp(2) < threshold(3) должно применить ветку then (+3)")


func test_effect_conditional_applies_else_branch_when_condition_false() -> void:
	player.wall_hp = 5
	var card := (
		TestFixtures
		. make_card(
			1,
			CardData.ResourceType.BRICKS,
			[
				{
					"type": "conditional",
					"target": "self",
					"field": "wall_hp",
					"op": "<",
					"threshold": 3,
					"then": {"type": "build_wall", "target": "self", "value": 3},
					"else": {"type": "build_wall", "target": "self", "value": 1},
				}
			]
		)
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(player.wall_hp, 6, "wall_hp(5) не < threshold(3) должно применить ветку else (+1)")


func test_effect_conditional_nested_effect_target_independent_of_condition_target() -> void:
	player.wall_hp = 5
	var enemy_wall_before: int = enemy.wall_hp
	var card := (
		TestFixtures
		. make_card(
			1,
			CardData.ResourceType.BRICKS,
			[
				{
					"type": "conditional",
					"target": "self",
					"field": "wall_hp",
					"op": ">",
					"threshold": 0,
					"then": {"type": "damage", "target": "enemy", "value": 4},
				}
			]
		)
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(
		enemy.wall_hp, enemy_wall_before - 4, "Вложенный then-эффект должен бить enemy, а не self"
	)


func test_effect_mod_quarry_does_not_go_below_zero() -> void:
	player.quarry = 1
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "mod_quarry", "target": "self", "value": -5}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(
		player.quarry, 0, "Генератор не должен уходить в минус при порче генераторов"
	)


func test_effect_gain_resource_adds_instantly_to_target() -> void:
	var bricks_before: int = player.bricks
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.BRICKS,
		[{"type": "gain_resource", "target": "self", "resource": "bricks", "value": 5}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(player.bricks, bricks_before + 5)


func test_effect_drain_resource_removes_without_transferring_to_actor() -> void:
	enemy.gems = 5
	var player_gems_before: int = player.gems
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "drain_resource", "target": "enemy", "resource": "gems", "value": 3}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(enemy.gems, 2)
	assert_eq(
		player.gems,
		player_gems_before,
		"drain_resource — проклятие, а не кража: actor ничего не получает"
	)


func test_effect_drain_resource_clamps_to_amount_available() -> void:
	enemy.gems = 2
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "drain_resource", "target": "enemy", "resource": "gems", "value": 10}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(enemy.gems, 0, "Нельзя увести ресурс цели в минус")


func test_effect_reduce_wall_subtracts_flat_without_tower_overflow() -> void:
	enemy.wall_hp = 3
	var enemy_tower_before: int = enemy.tower_hp
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BEASTS, [{"type": "reduce_wall", "target": "enemy", "value": 10}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(enemy.wall_hp, 0, "wall_hp не должен уходить в минус")
	assert_eq(
		enemy.tower_hp,
		enemy_tower_before,
		"reduce_wall не должен переливаться в tower_hp — этим он отличается от damage"
	)


func test_effect_steal_resource_random_moves_exactly_one_resource_type() -> void:
	enemy.bricks = 10
	enemy.gems = 10
	enemy.beasts = 10
	var player_bricks_before: int = player.bricks
	var player_gems_before: int = player.gems
	var player_beasts_before: int = player.beasts
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "random", "value": 5}]
	)

	MatchManager.apply_card_effects(card, player)

	var deltas := [
		player.bricks - player_bricks_before,
		player.gems - player_gems_before,
		player.beasts - player_beasts_before,
	]
	var nonzero_deltas: Array = deltas.filter(func(d): return d != 0)
	assert_eq(nonzero_deltas.size(), 1, "resource=random должен затронуть ровно один тип ресурса")
	if nonzero_deltas.size() == 1:
		assert_eq(nonzero_deltas[0], 5, "Должно быть украдено ровно value")


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


func test_check_win_reason_is_tower_height() -> void:
	player.tower_hp = MatchManager.WIN_TOWER_HEIGHT
	MatchManager.check_win()
	assert_eq(MatchManager.last_win_reason, "tower_height")
	assert_eq(MatchManager.last_win_resource, "", "Победа по высоте башни не про ресурс")


func test_check_win_reason_is_tower_destroyed() -> void:
	enemy.tower_hp = 0
	MatchManager.check_win()
	assert_eq(MatchManager.last_win_reason, "tower_destroyed")
	assert_eq(MatchManager.last_win_resource, "")


func test_check_win_reason_prioritizes_destruction_over_own_height() -> void:
	player.tower_hp = MatchManager.WIN_TOWER_HEIGHT
	enemy.tower_hp = 0
	MatchManager.check_win()
	assert_eq(MatchManager.last_win_reason, "tower_destroyed")


func test_check_win_reason_is_resource_bricks() -> void:
	player.bricks = MatchManager.WIN_RESOURCE_AMOUNT
	MatchManager.check_win()
	assert_eq(MatchManager.last_win_reason, "resource")
	assert_eq(MatchManager.last_win_resource, "bricks")


func test_check_win_reason_is_resource_gems() -> void:
	enemy.gems = MatchManager.WIN_RESOURCE_AMOUNT
	MatchManager.check_win()
	assert_eq(MatchManager.last_win_reason, "resource")
	assert_eq(MatchManager.last_win_resource, "gems")


func test_check_win_reason_is_resource_beasts() -> void:
	player.beasts = MatchManager.WIN_RESOURCE_AMOUNT
	MatchManager.check_win()
	assert_eq(MatchManager.last_win_reason, "resource")
	assert_eq(MatchManager.last_win_resource, "beasts")


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
	assert_push_warning("MatchManager: AI Strategy не назначена, использую default_ai_strategy.gd")


func test_execute_ai_turn_returns_turn_to_player_when_hand_empty() -> void:
	enemy.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()
	MatchManager.current_state = MatchManager.State.AI_TURN
	MatchManager.enemy_hand = []

	await MatchManager.execute_ai_turn()

	assert_eq(
		MatchManager.current_state,
		MatchManager.State.PLAYER_TURN,
		"Пустая рука ИИ не должна вешать ход — он обязан вернуться к игроку"
	)


func test_resolve_ai_turn_plays_best_card_for_player_actor_too() -> void:
	player.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_wall", "target": "self", "value": 3}]
	)
	MatchManager.player_hand = [card]
	MatchManager.current_state = MatchManager.State.PLAYER_TURN

	MatchManager._resolve_ai_turn(player)

	assert_false(MatchManager.player_hand.has(card), "Карта должна быть разыграна и уйти из руки")


func test_resolve_ai_turn_falls_back_to_default_strategy_for_any_actor() -> void:
	player.ai_strategy = null
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchManager.current_state = MatchManager.State.PLAYER_TURN

	MatchManager._resolve_ai_turn(player)

	assert_not_null(player.ai_strategy, "Отсутствие стратегии у actor'а не должно ронять ход")
	assert_push_warning("MatchManager: AI Strategy не назначена, использую default_ai_strategy.gd")


func test_resolve_ai_turn_ends_player_turn_and_hands_off_to_enemy_when_hand_empty() -> void:
	player.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()
	MatchManager.player_hand = []
	MatchManager.current_state = MatchManager.State.PLAYER_TURN

	MatchManager._resolve_ai_turn(player)

	assert_eq(
		MatchManager.current_state,
		MatchManager.State.AI_TURN,
		"Пустая рука игрока должна передать ход ИИ (AI_TURN), а не зависнуть"
	)


func test_player_data_uses_25_8_balance_package_defaults() -> void:
	var live_defaults := PlayerData.new()
	assert_eq(live_defaults.tower_hp, 25, "Пакет ARC-096: стартовая башня")
	assert_eq(live_defaults.wall_hp, 8, "Пакет ARC-096: стартовая стена")
	assert_eq(MatchManager.WIN_TOWER_HEIGHT, 55, "Калибровка ARC-097: цель строительной победы")


func test_setup_match_can_disable_all_player_progression_for_simulation() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var artifact: ArtifactData = load(DWARF_PICKAXE_PATH)
	var saved_upgrades: Dictionary = ProfileManager.profile.get("upgrades", {}).duplicate()
	ProfileManager.profile["upgrades"] = {"tower": 2, "quarry": 2}
	MatchSettings.run_tower_bonus = 5
	MatchSettings.run_quarry_bonus = 3
	MatchSettings.run_artifacts = [artifact]

	MatchManager.setup_match(p, e, [], false)

	assert_eq(p.tower_hp, 20, "Симулятор не должен получать meta/run bonus стороны A")
	assert_eq(p.quarry, 1, "Генератор стороны A должен остаться симметричным стороне B")
	assert_true(p.active_artifacts.is_empty(), "Артефакты забега не участвуют в чистом A/B")

	ProfileManager.profile["upgrades"] = saved_upgrades
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_artifacts = []


func test_setup_match_can_start_enemy_side_for_paired_simulation() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()

	MatchManager.setup_match(p, e, [], false, 1, false)

	assert_eq(MatchManager.current_state, MatchManager.State.AI_TURN)
	assert_eq(p.bricks, 5, "Сторона A не должна получить доход до своего первого хода")
	assert_eq(e.bricks, 6, "Стартующая сторона B должна получить доход своего первого хода")


func test_setup_match_applies_profile_manager_bonuses() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var orig_tower_hp: int = p.tower_hp
	var orig_wall_hp: int = p.wall_hp
	var orig_quarry: int = p.quarry
	var orig_magic: int = p.magic
	var orig_dungeon: int = p.dungeon
	var orig_hand_size: int = p.max_hand_size

	var saved_upgrades: Dictionary = ProfileManager.profile.get("upgrades", {}).duplicate()
	ProfileManager.profile["upgrades"] = {
		"tower": 2, "wall": 1, "quarry": 3, "magic": 1, "dungeon": 2, "hand_size": 1
	}

	MatchManager.setup_match(p, e)

	assert_eq(
		MatchManager.player_data.tower_hp, orig_tower_hp + 2 * 3, "tower: уровень 2 * per_level 3"
	)
	assert_eq(
		MatchManager.player_data.wall_hp, orig_wall_hp + 1 * 3, "wall: уровень 1 * per_level 3"
	)
	assert_eq(
		MatchManager.player_data.quarry, orig_quarry + 3 * 1, "quarry: уровень 3 * per_level 1"
	)
	assert_eq(MatchManager.player_data.magic, orig_magic + 1 * 1, "magic: уровень 1 * per_level 1")
	assert_eq(
		MatchManager.player_data.dungeon, orig_dungeon + 2 * 1, "dungeon: уровень 2 * per_level 1"
	)
	assert_eq(
		MatchManager.player_data.max_hand_size,
		orig_hand_size + 1 * 1,
		"hand_size: уровень 1 * per_level 1"
	)

	ProfileManager.profile["upgrades"] = saved_upgrades


func test_setup_match_applies_rest_run_bonuses() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var orig_tower_hp: int = p.tower_hp
	var orig_quarry: int = p.quarry
	var orig_magic: int = p.magic
	var orig_dungeon: int = p.dungeon

	var saved_upgrades: Dictionary = ProfileManager.profile.get("upgrades", {}).duplicate()
	ProfileManager.profile["upgrades"] = {}

	MatchSettings.run_tower_bonus = 5
	MatchSettings.run_quarry_bonus = 1
	MatchSettings.run_magic_bonus = 2
	MatchSettings.run_dungeon_bonus = 3

	MatchManager.setup_match(p, e)

	assert_eq(MatchManager.player_data.tower_hp, orig_tower_hp + 5)
	assert_eq(MatchManager.player_data.quarry, orig_quarry + 1)
	assert_eq(MatchManager.player_data.magic, orig_magic + 2)
	assert_eq(MatchManager.player_data.dungeon, orig_dungeon + 3)

	ProfileManager.profile["upgrades"] = saved_upgrades

	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0


func test_setup_match_does_not_apply_rest_bonuses_to_enemy() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var orig_enemy_tower_hp: int = e.tower_hp

	MatchSettings.run_tower_bonus = 5
	MatchManager.setup_match(p, e)

	assert_eq(
		MatchManager.enemy_data.tower_hp,
		orig_enemy_tower_hp,
		"Бонусы забега с «Отдыха» не должны применяться к ИИ"
	)

	MatchSettings.run_tower_bonus = 0


func test_setup_match_applies_run_artifacts_to_player() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var artifact: ArtifactData = load(DWARF_PICKAXE_PATH)
	MatchSettings.run_artifacts = [artifact]

	MatchManager.setup_match(p, e)

	assert_eq(MatchManager.player_data.active_artifacts, [artifact])

	MatchSettings.run_artifacts = []


func test_setup_match_does_not_apply_run_artifacts_to_enemy() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var artifact: ArtifactData = load(DWARF_PICKAXE_PATH)
	MatchSettings.run_artifacts = [artifact]

	MatchManager.setup_match(p, e)

	assert_true(MatchManager.enemy_data.active_artifacts.is_empty())

	MatchSettings.run_artifacts = []


func test_setup_match_resets_hands_from_previous_match() -> void:
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchManager.enemy_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]

	MatchManager.setup_match(TestFixtures.make_player(), TestFixtures.make_player())

	assert_eq(
		MatchManager.player_hand.size(), 5, "Рука игрока должна начинаться с нуля, а не копиться"
	)
	assert_eq(MatchManager.enemy_hand.size(), 5, "Рука ИИ должна начинаться с нуля, а не копиться")


func test_pick_random_regular_ai_strategy_returns_all_four_archetypes() -> void:
	var seen_types := {}

	for i in range(200):
		var strategy = MatchManager.pick_random_regular_ai_strategy()
		assert_true(
			(
				strategy is DefaultAIStrategy
				or strategy is AggressiveAIStrategy
				or strategy is BuilderAIStrategy
				or strategy is EconomistAIStrategy
			),
			"Должен возвращаться один из четырёх обычных архетипов"
		)
		seen_types[strategy.get_script()] = true

	assert_true(
		seen_types.size() > 1, "За 200 попыток должно встретиться больше одного типа стратегии"
	)
