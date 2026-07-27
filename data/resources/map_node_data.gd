class_name MapNodeData
extends Resource

enum NodeType { BATTLE, ELITE_BATTLE, SHOP, REST }

@export var node_type: NodeType
@export var position: Vector2
@export var connected_nodes: Array[Resource]
@export var is_completed: bool = false
