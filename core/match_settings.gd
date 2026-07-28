extends Node

var player_data: PlayerData
var enemy_data: PlayerData
var world_map_data

# ARC-002: связка "бой <-> карта мира". battle_screen._on_match_ended() читает
# came_from_map, чтобы после боя, начатого с карты, вернуться на неё и
# пометить current_map_node пройденным — вместо локального тестового Restart.
var came_from_map: bool = false
var current_map_node: MapNodeData

## ARC-016: колода забега — стартовый набор + карты, добранные в наградах/
## магазине (ARC-015/012). Персистентна в рамках одного забега (не
## обнуляется между боями на карте мира) — match_manager.setup_match() берёт
## отсюда шафл-копию для своей внутренней рабочей колоды, сама run_deck при
## этом не расходуется. Пустой массив = тестовый бой не из забега (main_menu
## "Битва") — тогда setup_match() использует старую тестовую колоду.
var run_deck: Array[CardData] = []
