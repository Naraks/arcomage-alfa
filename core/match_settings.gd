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

## ARC-012: золото забега (docs/game_design_doc.md 9.1 — временная валюта
## одного забега, НЕ мета-валюта "Слава" из Эпика F). Тратится в узле
## «Магазин» (ui/shop/shop_screen.gd) на покупку карт и удаление карт из
## run_deck. main_menu.gd задаёт стартовое значение в начале кампании
## (MatchManager.STARTING_RUN_GOLD — заглушка, см. её комментарий).
var run_gold: int = 0

## ARC-013: постоянные на этот забег усиления с узлов «Отдых» (design doc
## 4.5/7.1). Player_data пересоздаётся с нуля перед каждым боем (см.
## world_map_screen.gd), поэтому "полечить Стену/Башню" разово, как буквально
## написано в тикете, бессмысленно — design doc 4.5 явно говорит, что Башня/
## Стена/ресурсы/генераторы ВСЕГДА сбрасываются к базовым значениям в начале
## любого боя. Вместо этого — модификаторы, которые match_manager.setup_match()
## прибавляет поверх базовых значений player_data при старте КАЖДОГО следующего
## боя забега (тем же механизмом, что и бонусы ProfileManager). ui/rest/rest_screen.gd
## прибавляет к нужному полю при выборе одной из двух опций.
var run_tower_bonus: int = 0
var run_quarry_bonus: int = 0
var run_magic_bonus: int = 0
var run_dungeon_bonus: int = 0
