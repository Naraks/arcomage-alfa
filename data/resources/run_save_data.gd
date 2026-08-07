class_name RunSaveData
extends Resource
## Снимок состояния забега.

@export var world_map_data: WorldMapData
@export var run_deck: Array[CardData] = []
@export var run_gold: int = 0
@export var run_tower_bonus: int = 0
@export var run_quarry_bonus: int = 0
@export var run_magic_bonus: int = 0
@export var run_dungeon_bonus: int = 0
@export var run_artifacts: Array[ArtifactData] = []
