extends GutTest
## Юнит-тесты WorldMapGenerator (ARC-010, критерии приёмки docs/dev_plan_tickets.md).
##
## Генератор — чистая функция от seed без обращения к сцене/синглтонам, поэтому
## тесты вызывают WorldMapGenerator.generate_map() напрямую. Этажи в получившемся
## WorldMapData не хранятся отдельным полем на узле — тест реконструирует их
## послойным BFS от узлов без входящих связей, что заодно проверяет саму
## "слоистость" графа (рёбра строго между соседними этажами).

const MapNodeData = preload("res://data/resources/map_node_data.gd")


func test_generate_map_is_deterministic_for_same_seed() -> void:
	var map_a = WorldMapGenerator.generate_map(12345)
	var map_b = WorldMapGenerator.generate_map(12345)

	assert_eq(map_a.floor_count, map_b.floor_count, "floor_count должен совпадать для одного seed")
	assert_eq(_node_types(map_a), _node_types(map_b), "последовательность типов узлов должна совпадать")
	assert_eq(_edge_signature(map_a), _edge_signature(map_b), "структура связей должна совпадать")


func test_generate_map_different_seeds_can_differ() -> void:
	# Не строгая гарантия (веса могут случайно совпасть), но с 20 разными сидами
	# хотя бы одна пара должна дать разные графы — иначе seed вообще ни на что
	# не влияет, и генератор сломан сильнее, чем можно проверить одним тестом.
	var signatures := {}
	for seed_value in range(20):
		var map = WorldMapGenerator.generate_map(seed_value)
		signatures[str(_node_types(map))] = true

	assert_gt(signatures.size(), 1, "20 разных сидов не должны давать один и тот же граф")


func test_generate_map_100_seeds_satisfy_all_invariants() -> void:
	for seed_value in range(100):
		var map = WorldMapGenerator.generate_map(seed_value)
		_assert_map_is_valid(map, seed_value)


func _assert_map_is_valid(map, seed_value: int) -> void:
	assert_between(
		map.floor_count,
		WorldMapGenerator.MIN_FLOOR_COUNT,
		WorldMapGenerator.MAX_FLOOR_COUNT,
		"seed %d: floor_count вне [%d,%d]"
		% [seed_value, WorldMapGenerator.MIN_FLOOR_COUNT, WorldMapGenerator.MAX_FLOOR_COUNT]
	)

	var floors: Array = _group_by_floor(map)
	assert_eq(
		floors.size(),
		map.floor_count,
		"seed %d: число реконструированных этажей не совпадает с floor_count" % seed_value
	)

	var boss_floor: Array = floors[floors.size() - 1]
	assert_eq(boss_floor.size(), 1, "seed %d: этаж босса должен содержать ровно 1 узел" % seed_value)
	if boss_floor.size() == 1:
		assert_eq(
			boss_floor[0].node_type,
			MapNodeData.NodeType.BOSS,
			"seed %d: последний узел карты должен быть BOSS" % seed_value
		)

	for i in range(floors.size() - 1):
		var floor_nodes: Array = floors[i]
		assert_between(
			floor_nodes.size(),
			WorldMapGenerator.MIN_NODES_PER_FLOOR,
			WorldMapGenerator.MAX_NODES_PER_FLOOR,
			"seed %d этаж %d: размер этажа вне [%d,%d]"
			% [
				seed_value,
				i,
				WorldMapGenerator.MIN_NODES_PER_FLOOR,
				WorldMapGenerator.MAX_NODES_PER_FLOOR,
			]
		)

		var has_battle := false
		for node in floor_nodes:
			if (
				node.node_type == MapNodeData.NodeType.BATTLE
				or node.node_type == MapNodeData.NodeType.ELITE_BATTLE
			):
				has_battle = true
		assert_true(has_battle, "seed %d этаж %d: нет ни одного узла боя" % [seed_value, i])

		if i == floors.size() - 2:
			var has_rest := false
			var has_shop := false
			for node in floor_nodes:
				if node.node_type == MapNodeData.NodeType.REST:
					has_rest = true
				if node.node_type == MapNodeData.NodeType.SHOP:
					has_shop = true
			assert_true(has_rest, "seed %d: предпоследний этаж без гарантированного REST" % seed_value)
			assert_false(has_shop, "seed %d: SHOP запрещён на предпоследнем этаже" % seed_value)

		if i > 0:
			for node in floor_nodes:
				assert_true(
					_has_incoming(map, node),
					"seed %d этаж %d: узел без входящих связей (сирота)" % [seed_value, i]
				)

	for node in map.map_nodes:
		assert_true(_can_reach_boss(node), "seed %d: узел без пути до BOSS" % seed_value)


## Реконструирует этажи послойным BFS от узлов без входящих связей — не
## полагается на внутреннее устройство генератора, только на публичный
## контракт (map_nodes/connected_nodes/node_type).
func _group_by_floor(map) -> Array:
	var incoming_count: Dictionary = {}
	for node in map.map_nodes:
		incoming_count[node] = 0
	for node in map.map_nodes:
		for target in node.connected_nodes:
			incoming_count[target] += 1

	var floors: Array = []
	var current_layer: Array = []
	for node in map.map_nodes:
		if incoming_count[node] == 0:
			current_layer.append(node)

	var safety_limit: int = map.map_nodes.size() + 1
	while not current_layer.is_empty() and safety_limit > 0:
		floors.append(current_layer)
		var next_set: Dictionary = {}
		for node in current_layer:
			for target in node.connected_nodes:
				next_set[target] = true
		current_layer = next_set.keys()
		safety_limit -= 1

	return floors


func _has_incoming(map, target_node) -> bool:
	for node in map.map_nodes:
		if node.connected_nodes.has(target_node):
			return true
	return false


func _can_reach_boss(start_node) -> bool:
	var visited: Dictionary = {}
	var queue: Array = [start_node]

	while not queue.is_empty():
		var node = queue.pop_front()
		if node.node_type == MapNodeData.NodeType.BOSS:
			return true
		if visited.has(node):
			continue
		visited[node] = true
		for target in node.connected_nodes:
			queue.append(target)

	return false


func _node_types(map) -> Array:
	var types: Array = []
	for node in map.map_nodes:
		types.append(node.node_type)
	return types


func _edge_signature(map) -> Array:
	var edges: Array = []
	for node in map.map_nodes:
		var target_indices: Array = []
		for target in node.connected_nodes:
			target_indices.append(map.map_nodes.find(target))
		target_indices.sort()
		edges.append(target_indices)
	return edges
