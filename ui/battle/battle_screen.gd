extends Control
## Интерфейс боя и синхронизация с состоянием матча.

const MapNodeData = preload("res://data/resources/map_node_data.gd")

const MAX_VISUAL_BLOCKS := 20

const CARD_DENIED_SOUND = preload("res://audio/sfx/card_denied.wav")

@export var card_scene: PackedScene = preload("res://entities/card/card.tscn")

var e_tower_visuals: VBoxContainer
var e_wall_visuals: VBoxContainer
var p_tower_visuals: VBoxContainer
var p_wall_visuals: VBoxContainer

var _card_play_in_progress := false

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
@onready var deck_pile_button: Button = %DeckPileButton


func _ready() -> void:
	AudioManager.play_battle_music()
	GameEvents.match_started.connect(_on_match_started)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.damage_applied.connect(_on_damage_applied)
	GameEvents.value_built.connect(_on_value_built)
	GameEvents.match_ended.connect(_on_match_ended)

	deck_pile_button.pressed.connect(_on_deck_pile_pressed)

	_setup_visual_containers()
	if MatchSettings.player_data:
		MatchManager.setup_match(
			MatchSettings.player_data, MatchSettings.enemy_data, MatchSettings.run_deck
		)
	else:
		_test_setup()


func _setup_visual_containers() -> void:
	var enemy_visuals_hbox = HBoxContainer.new()
	enemy_visuals_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	e_tower_bar.get_parent().add_child(enemy_visuals_hbox)

	e_wall_visuals = VBoxContainer.new()
	e_wall_visuals.alignment = BoxContainer.ALIGNMENT_END
	enemy_visuals_hbox.add_child(e_wall_visuals)

	e_tower_visuals = VBoxContainer.new()
	e_tower_visuals.alignment = BoxContainer.ALIGNMENT_END
	enemy_visuals_hbox.add_child(e_tower_visuals)

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
	var visible_amount = clampi(amount, 0, MAX_VISUAL_BLOCKS)
	while container.get_child_count() > visible_amount:
		var child = container.get_child(0)
		container.remove_child(child)
		child.free()

	while container.get_child_count() < visible_amount:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(20, 10)
		container.add_child(panel)

	for panel in container.get_children():
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color.WHITE
		panel.add_theme_stylebox_override("panel", style)


func _center_control(control: Control, target_size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.custom_minimum_size = target_size
	control.offset_left = -target_size.x / 2.0
	control.offset_top = -target_size.y / 2.0
	control.offset_right = target_size.x / 2.0
	control.offset_bottom = target_size.y / 2.0


func _on_match_ended(winner: PlayerData) -> void:
	var layer = CanvasLayer.new()
	add_child(layer)

	var panel = Panel.new()
	_center_control(panel, Vector2(300, 200))
	layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var is_victory = winner == MatchManager.player_data

	var label = Label.new()
	label.text = tr("UI_BATTLE_VICTORY") if is_victory else tr("UI_BATTLE_DEFEAT")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var button = Button.new()

	if MatchSettings.came_from_map and is_victory:
		button.text = tr("UI_BATTLE_CLAIM_REWARD")
		button.pressed.connect(
			func(): get_tree().change_scene_to_file("res://ui/reward/reward_screen.tscn")
		)
	elif MatchSettings.came_from_map:
		var is_boss_defeat: bool = (
			MatchSettings.current_map_node != null
			and MatchSettings.current_map_node.node_type == MapNodeData.NodeType.BOSS
		)
		button.text = (
			tr("UI_BATTLE_RUN_SUMMARY") if is_boss_defeat else tr("UI_BATTLE_RETURN_TO_MAP")
		)
		button.pressed.connect(
			func():
				MatchSettings.came_from_map = false
				MatchSettings.current_map_node = null
				if is_boss_defeat:
					MatchSettings.run_victory = false
					get_tree().change_scene_to_file("res://ui/run_summary/run_summary_screen.tscn")
				else:
					get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
		)
	else:
		button.text = tr("UI_BATTLE_RESTART")
		button.pressed.connect(
			func():
				layer.queue_free()
				MatchManager.player_hand = []
				MatchManager.enemy_hand = []
				_test_setup()
		)

	vbox.add_child(button)


func _on_deck_pile_pressed() -> void:
	_show_card_list_popup(
		tr("UI_BATTLE_DECK_POPUP_TITLE") % MatchManager.deck.size(), MatchManager.deck
	)


func _show_card_list_popup(title_text: String, cards: Array) -> void:
	var layer = CanvasLayer.new()
	add_child(layer)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(
		func(event):
			if (
				event is InputEventMouseButton
				and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
			):
				layer.queue_free()
	)
	layer.add_child(backdrop)

	var panel = Panel.new()
	_center_control(panel, Vector2(720, 520))
	backdrop.add_child(panel)

	var root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 16)
	root_margin.add_theme_constant_override("margin_top", 16)
	root_margin.add_theme_constant_override("margin_right", 16)
	root_margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(root_margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	root_margin.add_child(root_vbox)

	var header = HBoxContainer.new()
	root_vbox.add_child(header)

	var title_label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_button = Button.new()
	close_button.text = tr("COMMON_CLOSE")
	close_button.pressed.connect(func(): layer.queue_free())
	header.add_child(close_button)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	if cards.is_empty():
		var empty_label = Label.new()
		empty_label.text = tr("UI_BATTLE_EMPTY_LIST")
		grid.add_child(empty_label)
	else:
		var sorted_cards: Array = cards.duplicate()
		sorted_cards.sort_custom(_compare_cards_for_view)
		for card_data in sorted_cards:
			var card_node = card_scene.instantiate()
			grid.add_child(card_node)
			card_node.card_data = card_data


func _compare_cards_for_view(a: CardData, b: CardData) -> bool:
	return CardSortUtils.compare_by_type_cost_name(a, b)


func _test_setup() -> void:
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
		refresh_hand()
		if not MatchManager.player_hand.is_empty() and not _has_playable_card():
			status_label.text = tr("UI_BATTLE_NO_PLAYABLE_CARDS")
		else:
			status_label.text = tr("UI_BATTLE_YOUR_TURN")
	else:
		status_label.text = tr("UI_BATTLE_ENEMY_TURN")


func _has_playable_card() -> bool:
	for card in MatchManager.player_hand:
		if MatchManager.can_afford(card, MatchManager.player_data):
			return true
	return false


func _on_damage_applied(_target: PlayerData, _amount: int, _hit_wall: bool) -> void:
	update_all_ui()
	var original_position = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_position - Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)


func _on_value_built(_target: PlayerData, _amount: int, _part: String) -> void:
	update_all_ui()


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

	bricks_label.text = "%d (+%d)" % [p.bricks, p.quarry]
	gems_label.text = "%d (+%d)" % [p.gems, p.magic]
	beasts_label.text = "%d (+%d)" % [p.beasts, p.dungeon]

	e_bricks_label.text = "%d (+%d)" % [e.bricks, e.quarry]
	e_gems_label.text = "%d (+%d)" % [e.gems, e.magic]
	e_beasts_label.text = "%d (+%d)" % [e.beasts, e.dungeon]

	deck_pile_button.text = tr("UI_BATTLE_DECK_BUTTON") % MatchManager.deck.size()
	deck_pile_button.tooltip_text = tr("UI_BATTLE_DECK_TOOLTIP")


func refresh_hand() -> void:
	print("[DEBUG] Refreshing hand, cards count: ", MatchManager.player_hand.size())
	for child in hand_container.get_children():
		child.queue_free()

	for card in MatchManager.player_hand:
		add_card_to_hand(card)


func add_card_to_hand(card_data: CardData) -> void:
	var card_node = card_scene.instantiate()
	hand_container.add_child(card_node)
	card_node.card_data = card_data
	card_node.card_clicked.connect(_on_card_clicked)
	card_node.card_right_clicked.connect(_on_card_right_clicked)


func _on_card_clicked(card_node: Node) -> void:
	if _card_play_in_progress:
		return

	var card_data = card_node.card_data
	print("[DEBUG] Card clicked: ", card_data.card_name)
	if MatchManager.current_state != MatchManager.State.PLAYER_TURN:
		print("[DEBUG] Not player turn! Current state: ", MatchManager.current_state)
		return

	if not MatchManager.can_afford(card_data, MatchManager.player_data):
		print("[DEBUG] Not enough resources!")
		AudioManager.play_sfx(CARD_DENIED_SOUND, -3.0)
		var tween = create_tween()
		var original_pos = card_node.position
		tween.tween_property(card_node, "position", original_pos + Vector2(10, 0), 0.05)
		tween.tween_property(card_node, "position", original_pos - Vector2(10, 0), 0.05)
		tween.tween_property(card_node, "position", original_pos, 0.05)
		return

	_card_play_in_progress = true
	card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(card_node, "position", Vector2(400, 300), 0.3).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(card_node, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(card_node, "modulate:a", 0.0, 0.3)
	await tween.finished

	MatchManager.play_card_by_index(card_node.get_index(), MatchManager.player_data)
	refresh_hand()
	_card_play_in_progress = false


func _on_card_right_clicked(card_node: Node) -> void:
	if _card_play_in_progress:
		return

	print("[DEBUG] Card right clicked: ", card_node.card_data.card_name)
	if MatchManager.current_state != MatchManager.State.PLAYER_TURN:
		return

	MatchManager.discard_card_by_index(card_node.get_index(), MatchManager.player_data)
	refresh_hand()
