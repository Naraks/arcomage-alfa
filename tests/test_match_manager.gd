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


## ARC-035: pre-play хук ("Счастливая Монета") — value=1.0 делает срабатывание
## гарантированным (randf() < 1.0 всегда true, см. комментарий в
## tests/test_artifact_manager.gd), поэтому тест детерминирован без seed.
func test_play_card_by_index_skips_payment_when_artifact_guarantees_it() -> void:
	var card := TestFixtures.make_card(3, CardData.ResourceType.BRICKS)
	MatchManager.player_hand = [card]
	player.active_artifacts = [
		TestFixtures.make_artifact([{"trigger": "pre_play", "type": "skip_payment_chance", "value": 1.0}])
	]

	MatchManager.play_card_by_index(0, player)

	assert_eq(player.bricks, 5, "С гарантированным skip_payment_chance ресурсы не должны списываться")
	assert_eq(MatchManager.player_hand.size(), 0, "Карта всё равно должна разыграться и уйти из руки")


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


## ARC-030/031: интеграционный тест на весь путь через РЕАЛЬНЫЙ сигнал
## GameEvents.damage_applied (emitted из apply_damage() внутри
## apply_card_effects() выше) — в отличие от tests/test_artifact_manager.gd,
## который дёргает ArtifactManager._on_damage_taken() напрямую, этот тест
## подтверждает, что ArtifactManager реально подключён как autoload
## (project.godot) и получает source (атакующего) через сигнал, не только
## в изоляции.
func test_play_card_by_index_damage_triggers_reflect_damage_artifact_on_defender() -> void:
	enemy.active_artifacts = [
		TestFixtures.make_artifact([{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}])
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


# --- apply_card_effects: draw_card/steal_resource/conditional (ARC-021) ---


func test_effect_draw_card_draws_into_target_hand() -> void:
	MatchManager.deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "draw_card", "target": "self", "value": 1}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(MatchManager.player_hand.size(), 1, "draw_card с target=self должен пополнить руку actor'а")
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

	assert_eq(MatchManager.player_hand.size(), 2, "value должен определять количество тянущихся карт")


func test_effect_draw_card_respects_max_hand_size() -> void:
	player.max_hand_size = 1
	MatchManager.player_hand = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	MatchManager.deck = [TestFixtures.make_card(1, CardData.ResourceType.BRICKS)]
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "draw_card", "target": "self", "value": 1}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(MatchManager.player_hand.size(), 1, "draw_card не должен превышать max_hand_size (ARC-003)")
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

	assert_eq(enemy.gems, enemy_gems_before - 3, "У цели (target=enemy) должно списаться value ресурса")
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
	assert_eq(player.gems, player_gems_before + 2, "Actor получает ровно столько, сколько реально украдено")


func test_effect_conditional_applies_then_branch_when_condition_true() -> void:
	player.wall_hp = 2
	var card := TestFixtures.make_card(
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

	MatchManager.apply_card_effects(card, player)

	assert_eq(player.wall_hp, 5, "wall_hp(2) < threshold(3) должно применить ветку then (+3)")


func test_effect_conditional_applies_else_branch_when_condition_false() -> void:
	player.wall_hp = 5
	var card := TestFixtures.make_card(
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

	MatchManager.apply_card_effects(card, player)

	assert_eq(player.wall_hp, 6, "wall_hp(5) не < threshold(3) должно применить ветку else (+1)")


func test_effect_conditional_nested_effect_target_independent_of_condition_target() -> void:
	# Условие проверяется на self (wall_hp игрока), но вложенный эффект бьёт enemy —
	# target условия и target вложенного эффекта резолвятся независимо друг от друга.
	player.wall_hp = 5
	var enemy_wall_before: int = enemy.wall_hp
	var card := TestFixtures.make_card(
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

	MatchManager.apply_card_effects(card, player)

	assert_eq(enemy.wall_hp, enemy_wall_before - 4, "Вложенный then-эффект должен бить enemy, а не self")


# --- apply_card_effects: gain_resource/drain_resource/reduce_wall/random steal,
# --- generator floor (ARC-020) ---


func test_effect_mod_quarry_does_not_go_below_zero() -> void:
	player.quarry = 1
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "mod_quarry", "target": "self", "value": -5}]
	)

	MatchManager.apply_card_effects(card, player)

	assert_eq(player.quarry, 0, "Генератор не должен уходить в минус (cards_list.md, порча генераторов)")


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
	assert_eq(player.gems, player_gems_before, "drain_resource — проклятие, а не кража: actor ничего не получает")


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


# --- _resolve_ai_turn (ARC-054: обобщена на любого actor, не только enemy_data,
# --- чтобы её мог использовать tools/battle_simulator.gd для обеих сторон) ---


func test_resolve_ai_turn_plays_best_card_for_player_actor_too() -> void:
	# execute_ai_turn() всегда ведёт enemy_data — _resolve_ai_turn() должна уметь
	# то же самое и для player_data (симулятору нужны обе стороны под ИИ).
	player.ai_strategy = load("res://data/resources/default_ai_strategy.gd").new()
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


func test_resolve_ai_turn_ends_player_turn_and_hands_off_to_enemy_when_hand_empty() -> void:
	player.ai_strategy = load("res://data/resources/default_ai_strategy.gd").new()
	MatchManager.player_hand = []
	MatchManager.current_state = MatchManager.State.PLAYER_TURN

	MatchManager._resolve_ai_turn(player)

	assert_eq(
		MatchManager.current_state,
		MatchManager.State.AI_TURN,
		"Пустая рука игрока должна передать ход ИИ (AI_TURN), а не зависнуть"
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


# --- setup_match / run_*_bonus (ARC-013: постоянные усиления с узлов «Отдых») ---


func test_setup_match_applies_rest_run_bonuses() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var orig_tower_hp: int = p.tower_hp
	var orig_quarry: int = p.quarry
	var orig_magic: int = p.magic
	var orig_dungeon: int = p.dungeon
	# setup_match также прибавляет бонусы ProfileManager к tower_hp/quarry.
	var profile_tower_bonus: int = ProfileManager.profile.player_stats.tower_hp_bonus
	var profile_quarry_bonus: int = ProfileManager.profile.player_stats.resource_gain_bonus

	MatchSettings.run_tower_bonus = 5
	MatchSettings.run_quarry_bonus = 1
	MatchSettings.run_magic_bonus = 2
	MatchSettings.run_dungeon_bonus = 3

	MatchManager.setup_match(p, e)

	assert_eq(MatchManager.player_data.tower_hp, orig_tower_hp + profile_tower_bonus + 5)
	assert_eq(MatchManager.player_data.quarry, orig_quarry + profile_quarry_bonus + 1)
	assert_eq(MatchManager.player_data.magic, orig_magic + 2)
	assert_eq(MatchManager.player_data.dungeon, orig_dungeon + 3)

	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0


func test_setup_match_does_not_apply_rest_bonuses_to_enemy() -> void:
	# Бонусы с «Отдыха» — экипировка ИГРОКА забега, у ИИ нет run_deck/run_gold/
	# run_*_bonus (см. ARC-016) — только своя независимая колода на каждый бой.
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


# --- setup_match / run_artifacts (ARC-015: артефакты как награда за бой) ---


func test_setup_match_applies_run_artifacts_to_player() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var artifact: ArtifactData = load("res://data/artifacts/dwarf_pickaxe.tres")
	MatchSettings.run_artifacts = [artifact]

	MatchManager.setup_match(p, e)

	assert_eq(MatchManager.player_data.active_artifacts, [artifact])

	MatchSettings.run_artifacts = []


func test_setup_match_does_not_apply_run_artifacts_to_enemy() -> void:
	var p := TestFixtures.make_player()
	var e := TestFixtures.make_player()
	var artifact: ArtifactData = load("res://data/artifacts/dwarf_pickaxe.tres")
	MatchSettings.run_artifacts = [artifact]

	MatchManager.setup_match(p, e)

	assert_true(MatchManager.enemy_data.active_artifacts.is_empty())

	MatchSettings.run_artifacts = []


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

	assert_false(MatchManager.enemy_deck.is_empty(), "У ИИ должна быть своя непустая колода после setup_match")

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
	var huge_count: int = MatchManager.ALL_CARD_PATHS.size() + 10
	var offer: Array[CardData] = MatchManager.build_shop_offer(huge_count)

	assert_eq(
		offer.size(),
		MatchManager.ALL_CARD_PATHS.size(),
		"Запрос больше размера пула должен просто вернуть весь пул без ошибок и без повторов"
	)
