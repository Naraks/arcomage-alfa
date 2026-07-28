class_name RunSaveData
extends Resource

## ARC-018: снимок состояния текущего забега для автосохранения в user://.
## Поля — прямое зеркало того подмножества MatchSettings, которое переживает
## переход между узлами карты (см. core/match_settings.gd). Игрок/противник
## текущего боя (player_data/enemy_data/came_from_map/current_map_node)
## намеренно не входят — сохранение делается только между узлами
## (world_map_screen._ready(), см. core/run_save_manager.gd), когда боя нет и
## current_map_node уже сброшен в null самими screen'ами (shop/rest/event/
## reward) перед возвратом на карту.

@export var world_map_data: WorldMapData
@export var run_deck: Array[CardData] = []
@export var run_gold: int = 0
@export var run_tower_bonus: int = 0
@export var run_quarry_bonus: int = 0
@export var run_magic_bonus: int = 0
@export var run_dungeon_bonus: int = 0
@export var run_artifacts: Array[ArtifactData] = []
