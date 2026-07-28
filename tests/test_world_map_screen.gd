extends GutTest
## Юнит-тесты WorldMapScreen._compute_available_nodes() (ARC-011, критерии
## приёмки docs/dev_plan_tickets.md).
##
## world_map_screen.gd — не autoload и без class_name (обычный Control-скрипт
## сцены world_map_screen.tscn), поэтому экземпляр создаётся через load().new()
## и НЕ добавляется в дерево сцены: _ready()/_generate_map_ui() при этом не
## вызываются (они трогают сцену — Line2D/Button), а _compute_available_nodes()
## читает только map_data (граф Resource-ов), сцена ему не нужна.

const WorldMapScreenScript = preload("res://ui/map/world_map_screen.gd")
const WorldMapData = preload("res://data/resources/world_map_data.gd")
const MapNodeData = preload("res://data/resources/map_node_data.gd")


func _make_node(node_type: int, completed: bool = false) -> MapNodeData:
	var node := MapNodeData.new()
	node.node_type = node_type
	node.is_completed = completed
	return node


func test_available_nodes_are_roots_when_current_index_is_sentinel() -> void:
	# current_node_index == -1 — сентинел WorldMapGenerator "забег только начался".
	var root_a := _make_node(MapNodeData.NodeType.BATTLE)
	var root_b := _make_node(MapNodeData.NodeType.EVENT)
	var floor2 := _make_node(MapNodeData.NodeType.BATTLE)
	root_a.connected_nodes = [floor2]
	root_b.connected_nodes = [floor2]

	var map := WorldMapData.new()
	map.map_nodes = [root_a, root_b, floor2]
	map.current_node_index = -1

	var screen = WorldMapScreenScript.new()
	screen.map_data = map

	var available: Array = screen._compute_available_nodes()

	assert_true(available.has(root_a), "Узел без входящих связей должен быть доступен на старте")
	assert_true(available.has(root_b), "Узел без входящих связей должен быть доступен на старте")
	assert_false(available.has(floor2), "Узел с входящей связью не должен быть доступен на старте")

	screen.free()


func test_available_nodes_are_connected_to_current_and_not_completed() -> void:
	var current := _make_node(MapNodeData.NodeType.BATTLE, true)
	var next_open := _make_node(MapNodeData.NodeType.EVENT)
	var next_completed := _make_node(MapNodeData.NodeType.BATTLE, true)
	current.connected_nodes = [next_open, next_completed]

	var map := WorldMapData.new()
	map.map_nodes = [current, next_open, next_completed]
	map.current_node_index = 0

	var screen = WorldMapScreenScript.new()
	screen.map_data = map

	var available: Array = screen._compute_available_nodes()

	assert_true(available.has(next_open), "Соединённый непройденный узел должен быть доступен")
	assert_false(
		available.has(next_completed), "Соединённый, но уже пройденный узел не должен быть доступен"
	)
	assert_false(
		available.has(current), "Текущий узел не входит в свои же connected_nodes — сам по себе недоступен"
	)

	screen.free()


# --- _apply_node_difficulty (ARC-017: усиленный противник на элите/боссе) ---


func test_apply_node_difficulty_battle_leaves_enemy_stats_unchanged() -> void:
	var screen = WorldMapScreenScript.new()
	var enemy := TestFixtures.make_player()
	var orig_tower_hp := enemy.tower_hp

	screen._apply_node_difficulty(enemy, MapNodeData.NodeType.BATTLE)

	assert_eq(enemy.tower_hp, orig_tower_hp, "Обычный бой не должен усиливать противника")

	screen.free()


## ARC-027: обычный бой получает случайный профиль ИИ из всех четырёх — раньше
## (до ARC-027) ai_strategy для BATTLE вообще не выставлялся. Проверяем много
## раз подряд: (а) результат всегда один из четырёх ожидаемых классов, (б) за
## достаточное число попыток встречается больше одного класса — иначе это не
## "случайный", а один захардкоженный тип, который просто прошёл проверку (a).
func test_apply_node_difficulty_battle_assigns_random_strategy_from_all_four() -> void:
	var screen = WorldMapScreenScript.new()
	var seen_types := {}

	for i in range(200):
		var enemy := TestFixtures.make_player()
		screen._apply_node_difficulty(enemy, MapNodeData.NodeType.BATTLE)
		var strategy = enemy.ai_strategy
		assert_true(
			(
				strategy is DefaultAIStrategy
				or strategy is AggressiveAIStrategy
				or strategy is BuilderAIStrategy
				or strategy is EconomistAIStrategy
			),
			"BATTLE должен назначать один из четырёх известных профилей ИИ"
		)
		seen_types[strategy.get_script()] = true

	assert_true(seen_types.size() > 1, "За 200 попыток должно встретиться больше одного типа стратегии")

	screen.free()


func test_apply_node_difficulty_elite_boosts_stats() -> void:
	var screen = WorldMapScreenScript.new()
	var enemy := TestFixtures.make_player()
	var orig_tower_hp := enemy.tower_hp
	var orig_wall_hp := enemy.wall_hp
	var orig_quarry := enemy.quarry

	screen._apply_node_difficulty(enemy, MapNodeData.NodeType.ELITE_BATTLE)

	assert_eq(enemy.tower_hp, orig_tower_hp + WorldMapScreenScript.ELITE_TOWER_BONUS)
	assert_eq(enemy.wall_hp, orig_wall_hp + WorldMapScreenScript.ELITE_WALL_BONUS)
	assert_eq(enemy.quarry, orig_quarry + WorldMapScreenScript.ELITE_GENERATOR_BONUS)

	screen.free()


## ARC-027: элита — случайно Aggressive ИЛИ Builder (буквально "усиленная
## версия (Aggressive/Builder)" из описания тикета), не всегда один и тот же
## класс, как было временным приближением в ARC-017.
func test_apply_node_difficulty_elite_assigns_random_strategy_from_aggressive_or_builder() -> void:
	var screen = WorldMapScreenScript.new()
	var seen_types := {}

	for i in range(100):
		var enemy := TestFixtures.make_player()
		screen._apply_node_difficulty(enemy, MapNodeData.NodeType.ELITE_BATTLE)
		var strategy = enemy.ai_strategy
		assert_true(
			strategy is AggressiveAIStrategy or strategy is BuilderAIStrategy,
			"ELITE_BATTLE должен назначать только Aggressive или Builder"
		)
		seen_types[strategy.get_script()] = true

	assert_true(seen_types.size() > 1, "За 100 попыток должны встретиться оба класса")

	screen.free()


func test_apply_node_difficulty_boss_is_stronger_than_elite() -> void:
	var screen = WorldMapScreenScript.new()
	var enemy := TestFixtures.make_player()
	var orig_tower_hp := enemy.tower_hp

	screen._apply_node_difficulty(enemy, MapNodeData.NodeType.BOSS)

	assert_eq(enemy.tower_hp, orig_tower_hp + WorldMapScreenScript.BOSS_TOWER_BONUS)
	assert_true(WorldMapScreenScript.BOSS_TOWER_BONUS > WorldMapScreenScript.ELITE_TOWER_BONUS)
	assert_true(
		enemy.ai_strategy is BossAIStrategy,
		"ARC-027: босс всегда получает гибридную BossAIStrategy, не Aggressive напрямую"
	)

	screen.free()


func test_available_nodes_empty_when_current_index_out_of_range() -> void:
	var map := WorldMapData.new()
	map.map_nodes = [_make_node(MapNodeData.NodeType.BATTLE)]
	map.current_node_index = 99

	var screen = WorldMapScreenScript.new()
	screen.map_data = map

	assert_eq(
		screen._compute_available_nodes().size(),
		0,
		"Некорректный current_node_index не должен приводить к ошибке/крашу — просто нет доступных узлов"
	)

	screen.free()
