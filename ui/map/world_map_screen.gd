extends Control

const WorldMapData = preload("res://data/resources/world_map_data.gd")
const MapNodeData = preload("res://data/resources/map_node_data.gd")

@export var map_data: Resource


func _ready() -> void:
	print("WorldMapScreen _ready")
	if not map_data:
		map_data = MatchSettings.world_map_data

	if map_data:
		_generate_map_ui()


func _generate_map_ui() -> void:
	print("Generating map UI, nodes count: ", map_data.map_nodes.size())
	# Отрисовка путей
	for node in map_data.map_nodes:
		for connected in node.connected_nodes:
			var line = Line2D.new()
			line.points = [node.position + Vector2(25, 25), connected.position + Vector2(25, 25)]
			line.width = 2
			line.default_color = Color.WHITE
			add_child(line)

	# ARC-011: кликабельны только узлы, соединённые с current_node_index и ещё
	# не пройденные — остальные задизейблены и визуально приглушены.
	var available_nodes: Array = _compute_available_nodes()

	# Отрисовка узлов
	for node in map_data.map_nodes:
		var button = Button.new()
		button.text = MapNodeData.NodeType.keys()[node.node_type]
		button.position = node.position
		button.custom_minimum_size = Vector2(50, 50)

		var is_available: bool = available_nodes.has(node)
		button.disabled = not is_available
		_style_node_button(button, node, is_available)

		button.pressed.connect(_on_node_pressed.bind(node))
		add_child(button)
		print("Added button at: ", node.position)


## Доступные для клика узлы — соединённые с текущей позицией на карте
## (map_data.current_node_index) и ещё не пройденные. current_node_index == -1
## — сентинел WorldMapGenerator "забег только начался": тогда доступны узлы
## первого этажа, у которых нет ни одной входящей связи ни от одного узла карты.
func _compute_available_nodes() -> Array:
	if map_data.current_node_index == -1:
		var roots: Array = []
		for node in map_data.map_nodes:
			if not _has_incoming_edge(node):
				roots.append(node)
		return roots

	var index: int = map_data.current_node_index
	if index < 0 or index >= map_data.map_nodes.size():
		return []

	var current_node = map_data.map_nodes[index]
	var reachable: Array = []
	for node in current_node.connected_nodes:
		if not node.is_completed:
			reachable.append(node)
	return reachable


func _has_incoming_edge(target_node: Resource) -> bool:
	for node in map_data.map_nodes:
		if node.connected_nodes.has(target_node):
			return true
	return false


## Доступные узлы — обычный вид. Пройденные — приглушённо-зелёные (для
## наглядности маршрута за спиной). Всё остальное недоступное — тусклое,
## с иконкой замка перед названием типа узла.
func _style_node_button(button: Button, node: Resource, is_available: bool) -> void:
	if is_available:
		button.modulate = Color.WHITE
	elif node.is_completed:
		button.modulate = Color(0.5, 0.8, 0.5, 1.0)
	else:
		button.modulate = Color(0.45, 0.45, 0.45, 1.0)
		button.text = "🔒 " + button.text


func _on_node_pressed(node: Resource) -> void:
	print("Node pressed: ", node.node_type)

	if node.node_type == MapNodeData.NodeType.BATTLE:
		# Заглушка для PlayerData
		var p_data = PlayerData.new()
		var e_data = PlayerData.new()
		MatchSettings.player_data = p_data
		MatchSettings.enemy_data = e_data

		# ARC-002: помечаем, что бой начат с карты — battle_screen прочитает это
		# в _on_match_ended(), чтобы вернуть игрока сюда и отметить узел пройденным.
		MatchSettings.came_from_map = true
		MatchSettings.current_map_node = node

		get_tree().change_scene_to_file("res://ui/battle/battle_screen.tscn")
	else:
		print("Other node types not yet implemented: ", node.node_type)
