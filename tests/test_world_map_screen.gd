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


func test_route_header_uses_browser_safe_separator() -> void:
	var scene: PackedScene = load("res://ui/map/world_map_screen.tscn")
	var screen = scene.instantiate()
	var title: Label = screen.get_node("Header/Title")

	assert_eq(title.text, "МАРШРУТ: СТАРТ — ФИНАЛ")
	assert_false("↓" in title.text, "Стрелка отсутствует в браузерном шрифте")

	screen.free()


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
		available.has(current),
		"Текущий узел не входит в свои же connected_nodes — сам по себе недоступен"
	)

	screen.free()


# --- UI 02/13 (#97): состояния, превью и защита переходов ---


func test_node_states_distinguish_current_available_completed_and_locked() -> void:
	var completed := _make_node(MapNodeData.NodeType.BATTLE, true)
	var current := _make_node(MapNodeData.NodeType.REST, true)
	var available := _make_node(MapNodeData.NodeType.SHOP)
	var locked := _make_node(MapNodeData.NodeType.EVENT)
	current.connected_nodes = [available]

	var map := WorldMapData.new()
	map.map_nodes = [completed, current, available, locked]
	map.current_node_index = 1
	var screen = WorldMapScreenScript.new()
	screen.map_data = map
	var available_nodes: Array = screen._compute_available_nodes()

	assert_eq(screen._node_state(current, available_nodes), WorldMapScreenScript.NodeState.CURRENT)
	assert_eq(
		screen._node_state(available, available_nodes), WorldMapScreenScript.NodeState.AVAILABLE
	)
	assert_eq(
		screen._node_state(completed, available_nodes), WorldMapScreenScript.NodeState.COMPLETED
	)
	assert_eq(screen._node_state(locked, available_nodes), WorldMapScreenScript.NodeState.LOCKED)

	screen.free()


func test_node_labels_and_images_include_stable_type_and_non_color_state() -> void:
	var node := _make_node(MapNodeData.NodeType.SHOP)
	var screen = WorldMapScreenScript.new()

	var available_label: String = screen._node_label(node, WorldMapScreenScript.NodeState.AVAILABLE)
	var locked_label: String = screen._node_label(node, WorldMapScreenScript.NodeState.LOCKED)

	assert_not_null(screen._node_icon(node), "Магазин должен иметь PNG-пиктограмму")
	assert_true(available_label.contains("Магазин"))
	assert_true(available_label.contains("ДОСТУПНО"))
	assert_true(
		locked_label.contains("ЗАКРЫТО"), "Состояние различается текстом, а не только цветом"
	)

	screen.free()


func test_event_preview_does_not_reveal_hidden_result() -> void:
	var event_node := _make_node(MapNodeData.NodeType.EVENT)
	event_node.floor_index = 3
	var screen = WorldMapScreenScript.new()

	var preview: String = screen._node_preview(event_node, WorldMapScreenScript.NodeState.AVAILABLE)

	assert_true(preview.contains("Этаж 4"))
	assert_true(preview.contains("Результат скрыт"))

	screen.free()


func test_can_enter_node_allows_only_reachable_uncompleted_nodes() -> void:
	var current := _make_node(MapNodeData.NodeType.BATTLE, true)
	var reachable := _make_node(MapNodeData.NodeType.REST)
	var unreachable := _make_node(MapNodeData.NodeType.SHOP)
	current.connected_nodes = [reachable]

	var map := WorldMapData.new()
	map.map_nodes = [current, reachable, unreachable]
	map.current_node_index = 0
	var screen = WorldMapScreenScript.new()
	screen.map_data = map

	assert_true(screen._can_enter_node(reachable))
	assert_false(screen._can_enter_node(current))
	assert_false(screen._can_enter_node(unreachable))

	screen.free()


func test_horizontal_layout_centers_route_on_wide_viewport() -> void:
	var left := _make_node(MapNodeData.NodeType.BATTLE)
	left.position = Vector2(160, 100)
	var right := _make_node(MapNodeData.NodeType.EVENT)
	right.position = Vector2(640, 100)
	var map := WorldMapData.new()
	map.map_nodes = [left, right]
	var screen = WorldMapScreenScript.new()
	screen.map_data = map

	var layout: Vector2 = screen._calculate_horizontal_layout(1280.0)
	var visual_center := (
		(
			left.position.x
			+ layout.x
			+ right.position.x
			+ layout.x
			+ WorldMapScreenScript.NODE_SIZE.x
		)
		/ 2.0
	)

	assert_eq(layout.y, 1280.0)
	assert_almost_eq(visual_center, 640.0, 0.01, "Маршрут должен быть по центру широкого экрана")

	screen.free()


func test_horizontal_layout_keeps_padding_and_scroll_on_narrow_viewport() -> void:
	var left := _make_node(MapNodeData.NodeType.BATTLE)
	left.position = Vector2(160, 100)
	var right := _make_node(MapNodeData.NodeType.EVENT)
	right.position = Vector2(640, 100)
	var map := WorldMapData.new()
	map.map_nodes = [left, right]
	var screen = WorldMapScreenScript.new()
	screen.map_data = map

	var layout: Vector2 = screen._calculate_horizontal_layout(360.0)

	assert_true(layout.y > 360.0, "Широкий маршрут должен включать горизонтальную прокрутку")
	assert_almost_eq(left.position.x + layout.x, 32.0, 0.01, "Слева сохраняется безопасное поле")

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

	assert_true(
		seen_types.size() > 1, "За 200 попыток должно встретиться больше одного типа стратегии"
	)

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


# --- ARC-029: рост сложности от floor_index, независимо от типа узла ---


func test_apply_node_difficulty_floor_zero_matches_old_behavior() -> void:
	# floor_index по умолчанию (0, как у любого узла не из генератора) не
	# должен ничего менять — совместимость со старыми вызовами/тестами.
	var screen = WorldMapScreenScript.new()
	var enemy := TestFixtures.make_player()
	var orig_tower_hp := enemy.tower_hp

	screen._apply_node_difficulty(enemy, MapNodeData.NodeType.BATTLE, 0)

	assert_eq(enemy.tower_hp, orig_tower_hp, "floor_index=0 не должен усиливать противника")

	screen.free()


func test_apply_node_difficulty_battle_scales_with_floor_index() -> void:
	var screen = WorldMapScreenScript.new()
	var enemy := TestFixtures.make_player()
	var orig_tower_hp := enemy.tower_hp
	var orig_wall_hp := enemy.wall_hp
	var orig_quarry := enemy.quarry
	var floor_index := 9

	screen._apply_node_difficulty(enemy, MapNodeData.NodeType.BATTLE, floor_index)

	assert_eq(
		enemy.tower_hp,
		orig_tower_hp + floor_index * WorldMapScreenScript.FLOOR_TOWER_HP_PER_FLOOR,
		"Даже обычный BATTLE должен масштабироваться от глубины карты (ARC-029)"
	)
	assert_eq(
		enemy.wall_hp, orig_wall_hp + floor_index * WorldMapScreenScript.FLOOR_WALL_HP_PER_FLOOR
	)
	assert_eq(
		enemy.quarry, orig_quarry + int(floor_index / WorldMapScreenScript.FLOOR_GENERATOR_INTERVAL)
	)

	screen.free()


## ARC-029 складывается АДДИТИВНО поверх ELITE/BOSS-бонусов (ARC-017) — не
## подменяет их и не пересчитывает заново.
func test_apply_node_difficulty_elite_combines_floor_and_elite_bonus() -> void:
	var screen = WorldMapScreenScript.new()
	var enemy := TestFixtures.make_player()
	var orig_tower_hp := enemy.tower_hp
	var floor_index := 6

	screen._apply_node_difficulty(enemy, MapNodeData.NodeType.ELITE_BATTLE, floor_index)

	assert_eq(
		enemy.tower_hp,
		(
			orig_tower_hp
			+ floor_index * WorldMapScreenScript.FLOOR_TOWER_HP_PER_FLOOR
			+ WorldMapScreenScript.ELITE_TOWER_BONUS
		),
		"Бонус за этаж должен складываться с фиксированным бонусом ELITE_BATTLE, а не заменять его"
	)

	screen.free()


func test_apply_node_difficulty_deeper_floor_is_strictly_stronger() -> void:
	var screen = WorldMapScreenScript.new()
	var shallow := TestFixtures.make_player()
	var deep := TestFixtures.make_player()

	screen._apply_node_difficulty(shallow, MapNodeData.NodeType.BATTLE, 1)
	screen._apply_node_difficulty(deep, MapNodeData.NodeType.BATTLE, 12)

	assert_true(
		deep.tower_hp > shallow.tower_hp,
		"Противник на дальнем этаже должен быть сильнее, чем на ближнем (акцептанс-критерий ARC-029)"
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
