extends Node
## Состояние текущего матча и забега.

var player_data: PlayerData
var enemy_data: PlayerData
var world_map_data

var came_from_map: bool = false
var current_map_node: MapNodeData

var run_deck: Array[CardData] = []

var run_gold: int = 0

var run_tower_bonus: int = 0
var run_quarry_bonus: int = 0
var run_magic_bonus: int = 0
var run_dungeon_bonus: int = 0

var run_artifacts: Array[ArtifactData] = []

var run_victory: bool = false


func complete_current_map_node() -> void:
	if current_map_node:
		current_map_node.is_completed = true
		if world_map_data:
			var node_index: int = world_map_data.map_nodes.find(current_map_node)
			if node_index != -1:
				world_map_data.current_node_index = node_index
	current_map_node = null
