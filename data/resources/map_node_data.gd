class_name MapNodeData
extends Resource

## Порядок значений синхронизирован с распределением вероятностей в
## docs/world_map_design.md — при добавлении нового типа обновить и документ.
enum NodeType { BATTLE, ELITE_BATTLE, SHOP, REST, EVENT, BOSS }

@export var node_type: NodeType
@export var position: Vector2
@export var connected_nodes: Array[Resource]
@export var is_completed: bool = false
