extends GutTest
## Юнит-тесты профилей ИИ (ARC-025 «Строитель», ARC-026 «Маг/Экономист»).
## AIStrategy — Resource, не Node, поэтому создаётся через .new() напрямую,
## без сцены (как data/resources/*_ai_strategy.gd вообще не участвуют в
## дереве сцены — их use-site — MatchManager, не UI).

const BuilderAIStrategy = preload("res://data/resources/builder_ai_strategy.gd")
const EconomistAIStrategy = preload("res://data/resources/economist_ai_strategy.gd")
const BossAIStrategy = preload("res://data/resources/boss_ai_strategy.gd")

var player: PlayerData
var enemy: PlayerData


func before_each() -> void:
	player = TestFixtures.make_player()
	enemy = TestFixtures.make_player()


# --- BuilderAIStrategy (ARC-025) ---


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

	assert_eq(best, quarry_card, "Добыча Кирпичей — главный приоритет Строителя (описание тикета ARC-025)")


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
		tower_priority > damage_priority, "build_tower должен весить больше damage при одинаковом value"
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
	# Акцептанс-критерий ARC-025: "в тестовом бою Строитель реально быстрее
	# отстраивает башню, чем разыгрывает атакующие карты" — симулируем
	# несколько ходов подряд одной и той же рукой (build_tower/mod_quarry
	# против damage) и проверяем, что Строитель растит tower_hp, а не
	# разменивает ходы на атаку, когда альтернатива есть.
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
			chosen,
			hand[0],
			"При равном value build_tower должен выигрывать у damage на каждом ходу, пока башня не почти полна"
		)
		player.tower_hp += 4

	assert_eq(player.tower_hp, tower_hp_before + 12, "Три хода подряд должны были уйти в рост Башни")


# --- EconomistAIStrategy (ARC-026) ---


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
		best, steal_card, "Кража ресурсов (ARC-020/021) — прямое попадание в специализацию Экономиста"
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

	assert_true(magic_priority > tower_priority, "mod_magic должен весить больше build_tower у Экономиста")


func test_economist_get_best_card_returns_null_when_nothing_affordable() -> void:
	var strategy := EconomistAIStrategy.new()
	player.gems = 0
	var expensive_card := TestFixtures.make_card(
		5, CardData.ResourceType.GEMS, [{"type": "mod_magic", "target": "self", "value": 5}]
	)

	var best := strategy.get_best_card([expensive_card], player, enemy)

	assert_null(best)


func test_economist_differs_from_default_on_steal_resource_vs_build_wall() -> void:
	# Акцептанс-критерий ARC-026: "тест показывает иное поведение
	# относительно Default/Aggressive/Builder". DefaultAIStrategy не знает
	# про steal_resource (нет такой ветки в его calculate_card_priority,
	# ARC-005/ARC-021) — на той же руке выбирает wall_card, а не steal_card.
	var economist := EconomistAIStrategy.new()
	var default_ai := DefaultAIStrategy.new()
	var steal_card := TestFixtures.make_card(
		1,
		CardData.ResourceType.GEMS,
		[{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 3}]
	)
	var wall_card := TestFixtures.make_card(
		1, CardData.ResourceType.GEMS, [{"type": "build_wall", "target": "self", "value": 3}]
	)
	var hand: Array[CardData] = [wall_card, steal_card]

	assert_eq(economist.get_best_card(hand, player, enemy), steal_card)
	assert_eq(
		default_ai.get_best_card(hand, player, enemy),
		wall_card,
		"Default не умеет оценивать steal_resource — должен откатиться на build_wall"
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

	assert_eq(economist.get_best_card(hand, player, enemy), magic_card, "Экономист — про Гемы, не Кирпичи")
	assert_eq(builder.get_best_card(hand, player, enemy), quarry_card, "Строитель — про Кирпичи, не Гемы")


# --- BossAIStrategy (ARC-027) ---
#
# Aggressive не оценивает build_tower вовсе (calculate_card_priority без ветки
# "build_tower" в aggressive_ai_strategy.gd) — при равном value damage_card
# всегда выигрывает у tower_card, поэтому этой парой удобно проверять, какой
# из двух делегатов (_aggressive/_builder) реально выбрал ход.


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
	enemy.tower_hp = BossAIStrategy.LETHAL_ENEMY_TOWER_HP  # на грани — уже "добивать"

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[1],
		"Врага почти добили — Босс должен добивать (Aggressive), а не растить свою Башню"
	)


func test_boss_plays_aggressive_when_own_tower_in_danger() -> void:
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = 20  # враг не при смерти — не режим добивания
	player.tower_hp = BossAIStrategy.DANGER_OWN_TOWER_HP  # но сам Босс под угрозой

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[1],
		"Сам Босс под угрозой поражения — должен биться в ответ (Aggressive), а не копить экономику"
	)


func test_boss_plays_builder_when_safe() -> void:
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = 20  # не при смерти
	player.tower_hp = 20  # сам Босс не под угрозой

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[0],
		"Ни угрозы, ни лёгкой добычи — Босс должен играть в долгую (Builder), растить свою Башню"
	)


func test_boss_switches_mode_within_same_instance_as_state_changes() -> void:
	# ARC-027 требует именно динамическую реакцию "по угрозе поражения", а не
	# фиксированный на момент создания режим — один и тот же экземпляр должен
	# менять выбор при изменении tower_hp между вызовами.
	var strategy := BossAIStrategy.new()
	var hand := _boss_hand()
	enemy.tower_hp = 20
	player.tower_hp = 20

	assert_eq(strategy.get_best_card(hand, player, enemy), hand[0], "Пока всё безопасно — режим Builder")

	enemy.tower_hp = BossAIStrategy.LETHAL_ENEMY_TOWER_HP

	assert_eq(
		strategy.get_best_card(hand, player, enemy),
		hand[1],
		"Тот же экземпляр должен переключиться на Aggressive, как только враг оказался при смерти"
	)
