class_name WorldMapGenerator
extends RefCounted
## Процедурный генератор карты мира (ARC-010). Реализует схему из
## docs/world_map_design.md: 12-15 этажей, 2-4 узла на этаж, ветвящиеся и
## сходящиеся пути без "сирот" (узлов без входящих связей), гарантированный
## путь до BOSS с любого узла карты, детерминизм по seed.
##
## Единственная точка входа — статический generate_map(seed_value). Функция
## чистая: одинаковый seed_value всегда даёт одинаковый WorldMapData (тот же
## floor_count, те же типы узлов, те же связи) — это используется юнит-тестом
## (tests/test_world_map_generator.gd) и в будущем позволит воспроизводить
## "дневные забеги" с общим сидом.

const MapNodeData = preload("res://data/resources/map_node_data.gd")
const WorldMapData = preload("res://data/resources/world_map_data.gd")

const MIN_FLOOR_COUNT := 12
const MAX_FLOOR_COUNT := 15
const MIN_NODES_PER_FLOOR := 2
const MAX_NODES_PER_FLOOR := 4

## Базовые веса типов узлов для обычного этажа (не первого, не предпоследнего).
const BASE_WEIGHTS := {
	MapNodeData.NodeType.BATTLE: 45,
	MapNodeData.NodeType.ELITE_BATTLE: 15,
	MapNodeData.NodeType.SHOP: 10,
	MapNodeData.NodeType.REST: 15,
	MapNodeData.NodeType.EVENT: 15,
}

## Первый этаж: только BATTLE/EVENT — игрок ещё не готов к элите/тратам золота.
const FIRST_FLOOR_WEIGHTS := {
	MapNodeData.NodeType.BATTLE: 70,
	MapNodeData.NodeType.EVENT: 30,
}

const FLOOR_SPACING_Y := 140.0
const LANE_SPACING_X := 160.0
const TOP_MARGIN_Y := 100.0
const CENTER_X := 400.0


## Генерирует полную карту забега по seed_value. `current_node_index` в
## результате всегда -1 — сентинел "игрок ещё не встал ни на один узел",
## доступны узлы первого этажа (у них нет входящих связей). ARC-011 должен
## трактовать -1 как "показать все узлы без входящих рёбер".
static func generate_map(seed_value: int) -> Resource:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var floor_count: int = rng.randi_range(MIN_FLOOR_COUNT, MAX_FLOOR_COUNT)
	var last_regular_floor: int = floor_count - 2

	var floors: Array = []
	for floor_index in range(floor_count - 1):
		var node_count: int = rng.randi_range(MIN_NODES_PER_FLOOR, MAX_NODES_PER_FLOOR)
		var floor_nodes: Array = _build_floor(rng, floor_index, last_regular_floor, node_count)
		floors.append(floor_nodes)

	var boss_node := MapNodeData.new()
	boss_node.node_type = MapNodeData.NodeType.BOSS
	boss_node.position = Vector2(CENTER_X, TOP_MARGIN_Y + (floor_count - 1) * FLOOR_SPACING_Y)
	floors.append([boss_node])

	for floor_index in range(floors.size() - 1):
		_connect_floors(rng, floors[floor_index], floors[floor_index + 1])

	var map := WorldMapData.new()
	map.floor_count = floor_count
	map.seed = seed_value
	map.current_node_index = -1
	for floor_nodes in floors:
		for node in floor_nodes:
			map.map_nodes.append(node)

	return map


## Строит один обычный этаж: подбирает тип каждого узла по весам, затем
## принудительно чинит два инварианта, которые веса могут случайно нарушить
## (docs/world_map_design.md, раздел 4): наличие боя и, на предпоследнем
## этаже, наличие REST.
static func _build_floor(
	rng: RandomNumberGenerator, floor_index: int, last_regular_floor: int, node_count: int
) -> Array:
	var weights: Dictionary = _weights_for_floor(floor_index, last_regular_floor)
	var floor_nodes: Array = []

	for lane in range(node_count):
		var node := MapNodeData.new()
		node.node_type = _pick_weighted_type(rng, weights)
		node.position = _lane_position(floor_index, lane, node_count)
		floor_nodes.append(node)

	_ensure_has_battle(rng, floor_nodes)
	if floor_index == last_regular_floor:
		_ensure_has_rest(rng, floor_nodes)

	return floor_nodes


static func _weights_for_floor(floor_index: int, last_regular_floor: int) -> Dictionary:
	if floor_index == 0:
		return FIRST_FLOOR_WEIGHTS.duplicate()

	var weights: Dictionary = BASE_WEIGHTS.duplicate()
	if floor_index <= 1:
		weights.erase(MapNodeData.NodeType.ELITE_BATTLE)
	if floor_index == last_regular_floor:
		weights.erase(MapNodeData.NodeType.SHOP)
	return weights


## Возвращает значение NodeType (int) выбранное по весам из weights.
static func _pick_weighted_type(rng: RandomNumberGenerator, weights: Dictionary) -> int:
	var total := 0
	for weight in weights.values():
		total += weight

	var roll: int = rng.randi_range(1, total)
	var cumulative := 0
	for node_type in weights:
		cumulative += weights[node_type]
		if roll <= cumulative:
			return node_type

	return weights.keys()[0]


## Полностью "мирный" этаж запрещён — это боевая игра (docs/world_map_design.md).
static func _ensure_has_battle(rng: RandomNumberGenerator, floor_nodes: Array) -> void:
	for node in floor_nodes:
		if (
			node.node_type == MapNodeData.NodeType.BATTLE
			or node.node_type == MapNodeData.NodeType.ELITE_BATTLE
		):
			return

	var forced_index: int = rng.randi_range(0, floor_nodes.size() - 1)
	floor_nodes[forced_index].node_type = MapNodeData.NodeType.BATTLE


## Предпоследний этаж обязан давать шанс отдохнуть перед боссом. Выбирает
## индекс, отличный от уже гарантированного BATTLE/ELITE_BATTLE, чтобы не
## затирать инвариант, обеспеченный _ensure_has_battle — на этажах с
## MIN_NODES_PER_FLOOR (2) узлами индексов ровно достаточно для обоих правил.
static func _ensure_has_rest(rng: RandomNumberGenerator, floor_nodes: Array) -> void:
	for node in floor_nodes:
		if node.node_type == MapNodeData.NodeType.REST:
			return

	var candidates: Array = []
	for i in range(floor_nodes.size()):
		if (
			floor_nodes[i].node_type != MapNodeData.NodeType.BATTLE
			and floor_nodes[i].node_type != MapNodeData.NodeType.ELITE_BATTLE
		):
			candidates.append(i)

	var forced_index: int = (
		candidates[rng.randi_range(0, candidates.size() - 1)]
		if not candidates.is_empty()
		else rng.randi_range(0, floor_nodes.size() - 1)
	)
	floor_nodes[forced_index].node_type = MapNodeData.NodeType.REST


static func _lane_position(floor_index: int, lane: int, node_count: int) -> Vector2:
	var total_width: float = (node_count - 1) * LANE_SPACING_X
	var start_x: float = CENTER_X - total_width / 2.0
	return Vector2(start_x + lane * LANE_SPACING_X, TOP_MARGIN_Y + floor_index * FLOOR_SPACING_Y)


## Соединяет этаж с "лейном" (нормализованной позицией 0..1) следующего этажа:
## каждый узел всегда получает хотя бы одно исходящее ребро к ближайшему по
## лейну узлу следующего этажа (иногда — второе, к соседнему по близости, для
## ветвления), что минимизирует пересечения "в обратную сторону". После этого
## любой узел следующего этажа без входящих рёбер (сирота) принудительно
## получает ребро от ближайшего по лейну узла текущего этажа.
##
## Особый случай — предпоследний этаж перед BOSS: там ровно один узел на
## следующем этаже, и с ним соединяются все узлы текущего этажа (иначе гарантия
## пути до босса потребовала бы отдельной проверки).
static func _connect_floors(
	rng: RandomNumberGenerator, current_floor: Array, next_floor: Array
) -> void:
	if next_floor.size() == 1:
		for node in current_floor:
			node.connected_nodes.append(next_floor[0])
		return

	for i in range(current_floor.size()):
		var lane: float = _normalized_lane(i, current_floor.size())
		var order: Array = _order_by_lane_distance(lane, next_floor.size())

		current_floor[i].connected_nodes.append(next_floor[order[0]])
		if order.size() > 1 and rng.randf() < 0.4:
			current_floor[i].connected_nodes.append(next_floor[order[1]])

	for j in range(next_floor.size()):
		var has_incoming := false
		for node in current_floor:
			if node.connected_nodes.has(next_floor[j]):
				has_incoming = true
				break

		if not has_incoming:
			var lane: float = _normalized_lane(j, next_floor.size())
			var nearest_index: int = _order_by_lane_distance(lane, current_floor.size())[0]
			current_floor[nearest_index].connected_nodes.append(next_floor[j])


static func _normalized_lane(index: int, count: int) -> float:
	if count <= 1:
		return 0.5
	return float(index) / float(count - 1)


## Возвращает индексы 0..count-1, отсортированные по близости их нормализованного
## лейна к target_lane (ближайший — первым).
static func _order_by_lane_distance(target_lane: float, count: int) -> Array:
	var indices: Array = range(count)
	indices.sort_custom(
		func(a, b):
			var da: float = abs(_normalized_lane(a, count) - target_lane)
			var db: float = abs(_normalized_lane(b, count) - target_lane)
			return da < db
	)
	return indices
