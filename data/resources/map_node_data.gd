class_name MapNodeData
extends Resource
## Данные узла маршрута.

enum NodeType { BATTLE, ELITE_BATTLE, SHOP, REST, EVENT, BOSS }

@export var node_type: NodeType
@export var position: Vector2
@export var connected_nodes: Array[Resource]
@export var is_completed: bool = false

@export var floor_index: int = 0
