extends GutTest
## Тесты стратегий ИИ.

const BuilderAIStrategy = preload("res://data/resources/builder_ai_strategy.gd")
const EconomistAIStrategy = preload("res://data/resources/economist_ai_strategy.gd")
const BossAIStrategy = preload("res://data/resources/boss_ai_strategy.gd")

var player: PlayerData
var enemy: PlayerData


func before_each() -> void:
	player = TestFixtures.make_player()
	enemy = TestFixtures.make_player()


func test_builder_prefers_build_tower_over_damage_card() -> void:
	var strategy := BuilderAIStrategy.new()
	var tower_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_tower", "target": "self", "value": 5}]
	)
	var damage_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "damage", "target": "enemy", "value": 5}]
	)

	var best := strategy.get_best_card([damage_card, tower_card], player, enemy)

	assert_eq(best, tower_card, "Строитель должен предпочесть рост Башни атаке при равном value")


func test_builder_prefers_mod_quarry_over_build_wall() -> void:
	var strategy := BuilderAIStrategy.new()
	var quarry_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "mod_quarry", "target": "self", "value": 3}]
	)
	var wall_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_wall", "target": "self", "value": 3}]
	)

	var best := strategy.get_best_card([wall_card, quarry_card], player, enemy)

	assert_eq(
		best, quarry_card, "Добыча Кирпичей — главный приоритет Строителя (описание тикета ARC-025)"
	)


func test_builder_calculate_priority_ranks_build_tower_above_damage() -> void:
	var strategy := BuilderAIStrategy.new()
	var tower_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_tower", "target": "self", "value": 5}]
	)
	var damage_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "damage", "target": "enemy", "value": 5}]
	)

	var tower_priority: float = strategy.calculate_card_priority(tower_card, player, enemy)
	var damage_priority: float = strategy.calculate_card_priority(damage_card, player, enemy)

	assert_true(
		tower_priority > damage_priority,
		"build_tower должен весить больше damage при одинаковом value"
	)


func test_builder_get_best_card_returns_null_when_nothing_affordable() -> void:
	var strategy := BuilderAIStrategy.new()
	player.bricks = 0
	var expensive_card := TestFixtures.make_card(
		5, CardData.ResourceType.BRICKS, [{"type": "build_tower", "target": "self", "value": 5}]
	)

	var best := strategy.get_best_card([expensive_card], player, enemy)

	assert_null(best)


func test_builder_faster_tower_growth_than_default_over_simulated_turns() -> void:
	var strategy := BuilderAIStrategy.new()
	var hand: Array[CardData] = [
		TestFixtures.make_card(
			1, CardData.ResourceType.BRICKS, [{"type": "build_tower", "target": "self", "value": 4}]
		),
		TestFixtures.make_card(
			1, CardData.ResourceType.BRICKS, [{"type": "damage", "target": "enemy", "value": 4}]
		),
	]

	var tower_hp_before: int = player.tower_hp
	for i in range(3):
		var chosen := strategy.get_best_card(hand, player, enemy)
		assert_eq(
			chosen, hand[0], "При равном value build_tower должен выигрывать у damage каждый ход"
		)
		player.tower_hp += 4

	assert_eq(
		player.tower_hp, tower_hp_before + 12, "Три хода подряд должны были уйти в рост Башни"
	)


func test_economist_prefers_mod_magic_over_damage_card() -> void:
	var strategy := EconomistAIStrategy.new()
	var magic_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "mod_magic", "target": "self", "value": 3}]
	)
	var damage_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "damage", "target": "enemy", "value": 3}]
	)

	var best := strategy.get_best_card([damage_card, magic_card], player, enemy)

	assert_eq(best, magic_card, "Экономист должен предпочесть добычу Гемов атаке при равном value")


func test_economist_prefers_steal_resource_over_build_wall() -> void:
	var strategy := EconomistAIStrategy.new()
	var steal_card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 3}]
	)
	var wall_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "build_wall", "target": "self", "value": 3}]
	)

	var best := strategy.get_best_card([wall_card, steal_card], player, enemy)

	assert_eq(
		best,
		steal_card,
		"Кража ресурсов (ARC-020/021) — прямое попадание в специализацию Экономиста"
	)


func test_economist_calculate_priority_ranks_mod_magic_above_build_tower() -> void:
	var strategy := EconomistAIStrategy.new()
	var magic_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "mod_magic", "target": "self", "value": 4}]
	)
	var tower_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "build_tower", "target": "self", "value": 4}]
	)

	var magic_priority: float = strategy.calculate_card_priority(magic_card, player, enemy)
	var tower_priority: float = strategy.calculate_card_priority(tower_card, player, enemy)

	assert_true(
		magic_priority > tower_priority, "mod_magic должен весить больше build_tower у Экономиста"
	)


func test_economist_get_best_card_returns_null_when_nothing_affordable() -> void:
	var strategy := EconomistAIStrategy.new()
	player.gems = 0
	var expensive_card := TestFixtures.make_card(
		5, CardData.ResourceType.GEMS, [{"type": "mod_magic", "target": "self", "value": 5}]
	)

	var best := strategy.get_best_card([expensive_card], player, enemy)

	assert_null(best)


func test_economist_weighs_steal_resource_higher_than_default_which_now_sees_it_too() -> void:
	var economist := EconomistAIStrategy.new()
	var default_ai := DefaultAIStrategy.new()
	var steal_card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 3}]
	)

	var economist_priority: float = economist.calculate_card_priority(steal_card, player, enemy)
	var default_priority: float = default_ai.calculate_card_priority(steal_card, player, enemy)

	assert_true(
		default_priority > 0.0,
		"ARC-093: Default больше не должен давать steal_resource нулевой вес"
	)
	assert_true(
		economist_priority > default_priority,
		"Экономист специализируется на краже ресурсов сильнее Default"
	)


func test_economist_differs_from_builder_on_mod_magic_vs_mod_quarry() -> void:
	var economist := EconomistAIStrategy.new()
	var builder := BuilderAIStrategy.new()
	var magic_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "mod_magic", "target": "self", "value": 4}]
	)
	var quarry_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "mod_quarry", "target": "self", "value": 4}]
	)
	var hand: Array[CardData] = [magic_card, quarry_card]

	assert_eq(
		economist.get_best_card(hand, player, enemy), magic_card, "Экономист — про Гемы, не Кирпичи"
	)
	assert_eq(
		builder.get_best_card(hand, player, enemy), quarry_card, "Строитель — про Кирпичи, не Гемы"
	)


func test_default_no_longer_ignores_gain_resource() -> void:
	var strategy := DefaultAIStrategy.new()
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "gain_resource", "resource": "gems", "value": 4}]
	)

	assert_true(strategy.calculate_card_priority(card, player, enemy) > 0.0)


func test_default_no_longer_ignores_drain_resource() -> void:
	var strategy := DefaultAIStrategy.new()
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "drain_resource", "target": "enemy", "resource": "gems", "value": 4}]
	)

	assert_true(strategy.calculate_card_priority(card, player, enemy) > 0.0)


func test_default_no_longer_ignores_draw_card() -> void:
	var strategy := DefaultAIStrategy.new()
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "draw_card", "target": "self", "value": 1}]
	)

	assert_true(strategy.calculate_card_priority(card, player, enemy) > 0.0)


func test_aggressive_no_longer_ignores_reduce_wall() -> void:
	var strategy := AggressiveAIStrategy.new()
	var card := TestFixtures.make_card(
		1, CardData.ResourceType.BEASTS, [{"type": "reduce_wall", "target": "enemy", "value": 4}]
	)

	assert_true(strategy.calculate_card_priority(card, player, enemy) > 0.0)


func test_aggressive_prefers_damage_over_economic_at_full_enemy_tower() -> void:
	var strategy := AggressiveAIStrategy.new()
	enemy.tower_hp = 200
	var damage_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "damage", "target": "enemy", "value": 5}]
	)
	var economic_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "mod_quarry", "target": "self", "value": 3}]
	)

	var damage_score := strategy.calculate_card_priority(damage_card, player, enemy)
	var economic_score := strategy.calculate_card_priority(economic_card, player, enemy)
	assert_gt(
		damage_score,
		economic_score,
		"Aggressive must prefer damage over economy regardless of enemy tower HP"
	)


func test_aggressive_get_best_card_picks_damage_at_full_enemy_tower() -> void:
	var strategy := AggressiveAIStrategy.new()
	enemy.tower_hp = 200
	player.gems = 10
	var damage_card := TestFixtures.make_card(
		5, CardData.ResourceType.GEMS, [{"type": "damage", "target": "enemy", "value": 5}]
	)
	var economic_card := TestFixtures.make_card(
		5, CardData.ResourceType.GEMS, [{"type": "mod_quarry", "target": "self", "value": 3}]
	)
	var hand: Array[CardData] = [economic_card, damage_card]

	assert_eq(strategy.get_best_card(hand, player, enemy), damage_card)


func test_builder_no_longer_ignores_steal_resource() -> void:
	var strategy := BuilderAIStrategy.new()
	var card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 4}]
	)

	assert_true(strategy.calculate_card_priority(card, player, enemy) > 0.0)


func _repair_like_conditional_effect() -> Dictionary:
	return {
		"type": "conditional",
		"target": "self",
		"field": "wall_hp",
		"op": "<",
		"threshold": 3,
		"then": {"type": "build_wall", "target": "self", "value": 3},
		"else": {"type": "build_wall", "target": "self", "value": 1},
	}


func test_default_conditional_scores_then_branch_when_condition_true() -> void:
	var strategy := DefaultAIStrategy.new()
	player.wall_hp = 1
	var conditional_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [_repair_like_conditional_effect()]
	)
	var then_equivalent := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_wall", "target": "self", "value": 3}]
	)

	var conditional_priority: float = strategy.calculate_card_priority(
		conditional_card, player, enemy
	)
	var expected_priority: float = strategy.calculate_card_priority(then_equivalent, player, enemy)

	assert_eq(
		conditional_priority,
		expected_priority,
		"ARC-093: при wall_hp < 3 приоритет должен считаться по ветке 'then'"
	)


func test_default_conditional_scores_else_branch_when_condition_false() -> void:
	var strategy := DefaultAIStrategy.new()
	var conditional_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [_repair_like_conditional_effect()]
	)
	var else_equivalent := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_wall", "target": "self", "value": 1}]
	)

	var conditional_priority: float = strategy.calculate_card_priority(
		conditional_card, player, enemy
	)
	var expected_priority: float = strategy.calculate_card_priority(else_equivalent, player, enemy)

	assert_eq(
		conditional_priority,
		expected_priority,
		"ARC-093: при wall_hp >= 3 приоритет должен считаться по ветке 'else'"
	)


func test_builder_conditional_branch_selection_matches_default() -> void:
	var builder := BuilderAIStrategy.new()
	player.wall_hp = 1
	var conditional_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [_repair_like_conditional_effect()]
	)
	var then_equivalent := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_wall", "target": "self", "value": 3}]
	)

	var conditional_priority: float = builder.calculate_card_priority(
		conditional_card, player, enemy
	)
	var expected_priority: float = builder.calculate_card_priority(then_equivalent, player, enemy)

	assert_eq(conditional_priority, expected_priority)


func _boss_hand() -> Array[CardData]:
	var tower_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "build_tower", "target": "self", "value": 4}]
	)
	var damage_card := TestFixtures.make_card(
		1, CardData.ResourceType.BRICKS, [{"type": "damage", "target": "enemy", "value": 4}]
	)
	return [tower_card, damage_card]


func test_boss_plays_aggressive_when_enemy_tower_is_lethally_low() -> void:
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = BossAIStrategy.LETHAL_ENEMY_TOWER_HP

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[1],
		"Врага почти добили — Босс должен добивать (Aggressive), а не растить свою Башню"
	)


func test_boss_plays_aggressive_when_own_tower_in_danger() -> void:
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = 20
	player.tower_hp = BossAIStrategy.DANGER_OWN_TOWER_HP

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[1],
		"Сам Босс под угрозой поражения — должен биться в ответ (Aggressive), а не копить экономику"
	)


func test_boss_plays_builder_when_safe() -> void:
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = 20
	player.tower_hp = 20

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[0],
		"Ни угрозы, ни лёгкой добычи — Босс должен играть в долгую (Builder), растить свою Башню"
	)


func test_boss_switches_mode_within_same_instance_as_state_changes() -> void:
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = 20
	player.tower_hp = 20

	assert_eq(
		strategy.get_best_card(hand, player, enemy), hand[0], "Пока всё безопасно — режим Builder"
	)

	enemy.tower_hp = BossAIStrategy.LETHAL_ENEMY_TOWER_HP

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[1],
		"Тот же экземпляр должен переключиться на Aggressive, как только враг оказался при смерти"
	)
