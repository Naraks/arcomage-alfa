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

## ARC-012: золото забега (temp-валюта одного забега, НЕ мета-валюта "Слава").
## Тратится в ui/shop/shop_screen.gd. Стартовое значение — MatchManager.STARTING_RUN_GOLD.
var run_gold: int = 0

## ARC-013: постоянные усиления забега с узлов «Отдых» — модификаторы, которые
## match_manager.setup_match() прибавляет к player_data при старте каждого боя
## (не разовое лечение: player_data пересоздаётся с нуля перед каждым боем).
var run_tower_bonus: int = 0
var run_quarry_bonus: int = 0
var run_magic_bonus: int = 0
var run_dungeon_bonus: int = 0

## ARC-015: артефакты, собранные за забег (награда за бой, ARC-014 упоминал
## этот пробел — до этого тикета их некуда было выдавать). match_manager
## .setup_match() копирует их в player_data.active_artifacts при старте
## каждого боя; core/artifact_manager.gd сам следит за триггерами.
var run_artifacts: Array[ArtifactData] = []
