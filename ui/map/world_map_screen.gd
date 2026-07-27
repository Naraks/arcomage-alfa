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

	# Отрисовка узлов
	for node in map_data.map_nodes:
		var button = Button.new()
		button.text = MapNodeData.NodeType.keys()[node.node_type]
		button.position = node.position
		button.custom_minimum_size = Vector2(50, 50)
		button.disabled = node.is_completed
		button.pressed.connect(_on_node_pressed.bind(node))
		add_child(button)
		print("Added button at: ", node.position)


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
