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
