extends Control


func _ready() -> void:
	$VersionLabel.text = BuildVersion.get_display_string()


func _on_continue_pressed():
	print("Continue pressed - functionality not yet implemented")


func _on_campaign_pressed():
	print("Campaign pressed - loading world map")

	# ARC-010: процедурная генерация карты вместо хардкода из 2 узлов.
	# Сид не фиксируется здесь намеренно — обычный забег каждый раз получает
	# новую карту; фиксированный сид (для "дневных забегов") — задел на будущее.
	MatchSettings.world_map_data = WorldMapGenerator.generate_map(randi())

	# ARC-016: новый забег начинается со стартовой колоды — она же и есть
	# "колода забега", которую увидит match_manager.setup_match() в каждом
	# бою этой кампании, и которая будет расти от наград/магазина.
	MatchSettings.run_deck = MatchManager.build_starting_run_deck()

	var err = get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
	print("Change scene result: ", err)


func _on_battle_pressed():
	print("Battle pressed - loading battle screen")
	# Temporary setup for a direct battle
	var p_data = PlayerData.new()
	var e_data = PlayerData.new()
	MatchSettings.player_data = p_data
	MatchSettings.enemy_data = e_data

	# ARC-002: прямой тестовый бой из меню, не с карты — на случай, если
	# came_from_map остался true после предыдущего боя, начатого с карты.
	MatchSettings.came_from_map = false
	MatchSettings.current_map_node = null
	# ARC-016: не должна протечь колода забега из предыдущей кампании — это
	# отдельный тестовый бой, не часть забега, setup_match() должен взять
	# старую тестовую колоду.
	MatchSettings.run_deck = []

	get_tree().change_scene_to_file("res://ui/battle/battle_screen.tscn")


func _on_deck_pressed():
	print("Deck pressed - functionality not yet implemented")
