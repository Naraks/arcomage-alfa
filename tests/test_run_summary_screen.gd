extends GutTest
## Тесты итогов забега.

const RunSummaryScreenScript = preload("res://ui/run_summary/run_summary_screen.gd")
const WorldMapData = preload("res://data/resources/world_map_data.gd")
const MapNodeData = preload("res://data/resources/map_node_data.gd")


func before_each() -> void:
	MatchSettings.world_map_data = null


func after_each() -> void:
	MatchSettings.world_map_data = null


func _make_node(node_type: int, completed: bool) -> MapNodeData:
	var node := MapNodeData.new()
	node.node_type = node_type
	node.is_completed = completed
	return node


func test_count_completed_nodes_counts_only_completed() -> void:
	var screen = RunSummaryScreenScript.new()
	var map := WorldMapData.new()
	map.map_nodes = [
		_make_node(MapNodeData.NodeType.BATTLE, true),
		_make_node(MapNodeData.NodeType.SHOP, true),
		_make_node(MapNodeData.NodeType.EVENT, false),
	]
	MatchSettings.world_map_data = map

	assert_eq(screen._count_completed_nodes(), 2)

	screen.free()


func test_count_completed_elites_ignores_other_completed_types() -> void:
	var screen = RunSummaryScreenScript.new()
	var map := WorldMapData.new()
	map.map_nodes = [
		_make_node(MapNodeData.NodeType.ELITE_BATTLE, true),
		_make_node(MapNodeData.NodeType.ELITE_BATTLE, false),
		_make_node(MapNodeData.NodeType.BATTLE, true),
	]
	MatchSettings.world_map_data = map

	assert_eq(screen._count_completed_elites(), 1)

	screen.free()


func test_calculate_fame_scales_with_floors_and_elites() -> void:
	var screen = RunSummaryScreenScript.new()

	var fame := screen._calculate_fame(5, 2, false)

	assert_eq(
		fame, 5 * RunSummaryScreenScript.FAME_PER_FLOOR + 2 * RunSummaryScreenScript.FAME_PER_ELITE
	)

	screen.free()


func test_calculate_fame_adds_boss_victory_bonus() -> void:
	var screen = RunSummaryScreenScript.new()

	var fame_defeat := screen._calculate_fame(5, 2, false)
	var fame_victory := screen._calculate_fame(5, 2, true)

	assert_eq(fame_victory - fame_defeat, RunSummaryScreenScript.FAME_BOSS_VICTORY_BONUS)

	screen.free()
