class_name WorldMapData
extends Resource

## Схема карты зафиксирована в docs/world_map_design.md (ARC-009).
@export var map_nodes: Array[Resource]
@export var current_node_index: int = 0

## Число этажей карты (рекомендация: 12-15, см. docs/world_map_design.md).
## Используется генератором (ARC-010) как целевая глубина графа.
@export var floor_count: int = 0

## Сид генерации карты — обеспечивает детерминированность (ARC-010) и
## задел под общую карту для всех игроков в рамках "дневных забегов".
@export var seed: int = 0

## ARC-088: перемешанная очередь событий текущего забега. Путь удаляется
## при показе события; пока очередь не исчерпана, точные повторы невозможны.
## Поле лежит в WorldMapData, поэтому автоматически сохраняется вместе с
## остальным графом забега через RunSaveManager/ResourceSaver.
@export var event_draw_pile: Array[String] = []
