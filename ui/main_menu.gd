extends Control

const WorldMapData = preload("res://data/resources/world_map_data.gd")
const MapNodeData = preload("res://data/resources/map_node_data.gd")


func _on_continue_pressed():
	print("Continue pressed - functionality not yet implemented")


func _on_campaign_pressed():
	print("Campaign pressed - loading world map")

	# Инициализация тестовой карты
	var map = WorldMapData.new()
	var node1 = MapNodeData.new()
	node1.node_type = MapNodeData.NodeType.BATTLE
	node1.position = Vector2(100, 100)

	var node2 = MapNodeData.new()
	node2.node_type = MapNodeData.NodeType.BATTLE
	node2.position = Vector2(300, 100)

	node1.connected_nodes.append(node2)

	map.map_nodes.append(node1)
	map.map_nodes.append(node2)

	MatchSettings.world_map_data = map

	var err = get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
	print("Change scene result: ", err)


func _on_battle_pressed():
	print("Battle pressed - loading battle screen")
	# Temporary setup for a direct battle
	var p_data = PlayerData.new()
	var e_data = PlayerData.new()
	MatchSettings.player_data = p_data
	MatchSettings.enemy_data = e_data
	get_tree().change_scene_to_file("res://ui/battle/battle_screen.tscn")


func _on_deck_pressed():
	print("Deck pressed - functionality not yet implemented")
