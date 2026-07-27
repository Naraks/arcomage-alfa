extends Control

@export var card_scene: PackedScene = preload("res://entities/card/card.tscn")

var e_tower_visuals: VBoxContainer
var e_wall_visuals: VBoxContainer
var p_tower_visuals: VBoxContainer
var p_wall_visuals: VBoxContainer

@onready var p_tower_bar: ProgressBar = %PlayerTowerBar
@onready var p_wall_bar: ProgressBar = %PlayerWallBar
@onready var e_tower_bar: ProgressBar = %EnemyTowerBar
@onready var e_wall_bar: ProgressBar = %EnemyWallBar

@onready var bricks_label: Label = %BricksLabel
@onready var gems_label: Label = %GemsLabel
@onready var beasts_label: Label = %BeastsLabel

@onready var e_bricks_label: Label = %EnemyBricksLabel
@onready var e_gems_label: Label = %EnemyGemsLabel
@onready var e_beasts_label: Label = %EnemyBeastsLabel

@onready var hand_container: HBoxContainer = %HandContainer
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	# Подписываемся на события
	GameEvents.match_started.connect(_on_match_started)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.health_changed.connect(self._on_health_changed)
	GameEvents.match_ended.connect(_on_match_ended)

	# Тестовый запуск матча, если мы в этой сцене напрямую
	_setup_visual_containers()
	if MatchSettings.player_data:
		MatchManager.setup_match(MatchSettings.player_data, MatchSettings.enemy_data)
	else:
		_test_setup()


func _setup_visual_containers() -> void:
	# Enemy visuals container
	var enemy_visuals_hbox = HBoxContainer.new()
	enemy_visuals_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	e_tower_bar.get_parent().add_child(enemy_visuals_hbox)

	e_wall_visuals = VBoxContainer.new()
	e_wall_visuals.alignment = BoxContainer.ALIGNMENT_END
	enemy_visuals_hbox.add_child(e_wall_visuals)

	e_tower_visuals = VBoxContainer.new()
	e_tower_visuals.alignment = BoxContainer.ALIGNMENT_END
	enemy_visuals_hbox.add_child(e_tower_visuals)

	# Player visuals container
	var player_visuals_hbox = HBoxContainer.new()
	player_visuals_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p_tower_bar.get_parent().add_child(player_visuals_hbox)

	p_tower_visuals = VBoxContainer.new()
	p_tower_visuals.alignment = BoxContainer.ALIGNMENT_END
	player_visuals_hbox.add_child(p_tower_visuals)

	p_wall_visuals = VBoxContainer.new()
	p_wall_visuals.alignment = BoxContainer.ALIGNMENT_END
	player_visuals_hbox.add_child(p_wall_visuals)


func _update_visuals(container: VBoxContainer, amount: int, color: Color) -> void:
	amount = max(0, amount)
	# Ensure count is correct: Remove panels from the TOP (Index 0)
	while container.get_child_count() > amount:
		var child = container.get_child(0)
		container.remove_child(child)
		child.free()

	# Add new panels at the BOTTOM if we don't have enough
	while container.get_child_count() < amount:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(20, 10)
		container.add_child(panel)

	# Update style and color for all panels to ensure consistency
	for panel in container.get_children():
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color.WHITE
		panel.add_theme_stylebox_override("panel", style)


func _on_match_ended(winner: PlayerData) -> void:
	var layer = CanvasLayer.new()
	add_child(layer)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 200)
	layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var is_victory = winner == MatchManager.player_data

	var label = Label.new()
	label.text = "Victory!" if is_victory else "Defeat!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var button = Button.new()

	if MatchSettings.came_from_map:
		# ARC-002: бой начат с карты мира — возвращаемся туда вместо локального
		# Restart. Победа помечает узел пройденным; поражение просто возвращает
		# на карту, узел остаётся доступен для повторной попытки.
		button.text = "Вернуться на карту"
		button.pressed.connect(
			func():
				if is_victory and MatchSettings.current_map_node:
					MatchSettings.current_map_node.is_completed = true
				MatchSettings.came_from_map = false
				MatchSettings.current_map_node = null
				get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
		)
	else:
		button.text = "Restart"
		button.pressed.connect(
			func():
				layer.queue_free()
				MatchManager.player_hand = []
				MatchManager.enemy_hand = []
				_test_setup()
		)

	vbox.add_child(button)


func _test_setup() -> void:
	# Баг: раньше переиспользовал MatchSettings.player_data/enemy_data, если они
	# были заданы — на Restart после поражения это были те же самые, уже
	# побитые PlayerData из проигранного матча (tower_hp/wall_hp не сбрасывались,
	# только рука). _test_setup() вызывается либо для прямого дебаг-запуска сцены
	# (тогда MatchSettings.player_data и так null), либо из Restart — в обоих
	# случаях нужны свежие данные, а не то, что осталось от предыдущего боя.
	var p := PlayerData.new()
	var e := PlayerData.new()
	e.ai_strategy = load("res://data/resources/aggressive_ai_strategy.gd").new()
	MatchManager.setup_match(p, e)


func _on_match_started(_player: PlayerData, _enemy: PlayerData) -> void:
	print("[DEBUG] Match started!")
	update_all_ui()
	refresh_hand()


func _on_resource_changed(_player: PlayerData, _type: String, _amount: int) -> void:
	update_all_ui()


func _on_turn_started(player: PlayerData) -> void:
	update_all_ui()
	if player == MatchManager.player_data:
		status_label.text = "YOUR TURN"
		refresh_hand()
	else:
		status_label.text = "ENEMY TURN"


func _on_health_changed(_player: Resource, amount: int) -> void:
	update_all_ui()
	if amount < 0:  # Тряска при получении урона
		var original_position = position
		var tween = create_tween()
		tween.tween_property(self, "position", original_position + Vector2(10, 0), 0.05)
		tween.tween_property(self, "position", original_position - Vector2(10, 0), 0.05)
		tween.tween_property(self, "position", original_position, 0.05)


func update_all_ui() -> void:
	var p = MatchManager.player_data
	var e = MatchManager.enemy_data

	if not p or not e:
		return

	p_tower_bar.value = p.tower_hp
	p_wall_bar.value = p.wall_hp
	e_tower_bar.value = e.tower_hp
	e_wall_bar.value = e.wall_hp

	_update_visuals(e_tower_visuals, e.tower_hp, Color.GRAY)
	_update_visuals(e_wall_visuals, e.wall_hp, Color.DARK_GRAY)
	_update_visuals(p_tower_visuals, p.tower_hp, Color.GRAY)
	_update_visuals(p_wall_visuals, p.wall_hp, Color.DARK_GRAY)

	bricks_label.text = "Bricks: %d (+%d)" % [p.bricks, p.quarry]
	gems_label.text = "Gems: %d (+%d)" % [p.gems, p.magic]
	beasts_label.text = "Beasts: %d (+%d)" % [p.beasts, p.dungeon]

	e_bricks_label.text = "Bricks: %d (+%d)" % [e.bricks, e.quarry]
	e_gems_label.text = "Gems: %d (+%d)" % [e.gems, e.magic]
	e_beasts_label.text = "Beasts: %d (+%d)" % [e.beasts, e.dungeon]


func refresh_hand() -> void:
	print("[DEBUG] Refreshing hand, cards count: ", MatchManager.player_hand.size())
	# Очищаем старую руку
	for child in hand_container.get_children():
		child.queue_free()

	# Добавляем карты из MatchManager
	for card in MatchManager.player_hand:
		add_card_to_hand(card)


func add_card_to_hand(card_data: CardData) -> void:
	var card_node = card_scene.instantiate()
	hand_container.add_child(card_node)
	card_node.card_data = card_data
	card_node.card_clicked.connect(_on_card_clicked)
	card_node.card_right_clicked.connect(_on_card_right_clicked)


func _on_card_clicked(card_node: Node) -> void:
	var card_data = card_node.card_data
	print("[DEBUG] Card clicked: ", card_data.card_name)
	if MatchManager.current_state != MatchManager.State.PLAYER_TURN:
		print("[DEBUG] Not player turn! Current state: ", MatchManager.current_state)
		return

	# Проверка ресурсов
	if not MatchManager.can_afford(card_data, MatchManager.player_data):
		print("[DEBUG] Not enough resources!")
		var tween = create_tween()
		var original_pos = card_node.position
		tween.tween_property(card_node, "position", original_pos + Vector2(10, 0), 0.05)
		tween.tween_property(card_node, "position", original_pos - Vector2(10, 0), 0.05)
		tween.tween_property(card_node, "position", original_pos, 0.05)
		return

	# Анимация проигрывания карты
	card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(card_node, "position", Vector2(400, 300), 0.3).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(card_node, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(card_node, "modulate:a", 0.0, 0.3)
	await tween.finished

	MatchManager.play_card_by_index(card_node.get_index(), MatchManager.player_data)
	refresh_hand()


func _on_card_right_clicked(card_node: Node) -> void:
	print("[DEBUG] Card right clicked: ", card_node.card_data.card_name)
	if MatchManager.current_state != MatchManager.State.PLAYER_TURN:
		return

	MatchManager.discard_card_by_index(card_node.get_index(), MatchManager.player_data)
	refresh_hand()
