extends Node

var player_data: PlayerData
var enemy_data: PlayerData
var world_map_data

# ARC-002: связка "бой <-> карта мира". battle_screen._on_match_ended() читает
# came_from_map, чтобы после боя, начатого с карты, вернуться на неё и
# пометить current_map_node пройденным — вместо локального тестового Restart.
var came_from_map: bool = false
var current_map_node: MapNodeData
