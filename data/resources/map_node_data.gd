class_name MapNodeData
extends Resource

## Порядок значений синхронизирован с распределением вероятностей в
## docs/world_map_design.md — при добавлении нового типа обновить и документ.
enum NodeType { BATTLE, ELITE_BATTLE, SHOP, REST, EVENT, BOSS }

@export var node_type: NodeType
@export var position: Vector2
@export var connected_nodes: Array[Resource]
@export var is_completed: bool = false

## ARC-029: глубина узла на карте (0-based, совпадает с индексом этажа в
## WorldMapGenerator._build_floor()/generate_map()) — используется для
## масштабирования сложности противника (world_map_screen.gd,
## _apply_node_difficulty()). Заполняется генератором при создании узла;
## для узлов, созданных не через генератор (тестовые/отладочные), остаётся
## дефолтным 0 — тот же эффект, что и раньше (без бонуса за глубину).
@export var floor_index: int = 0
