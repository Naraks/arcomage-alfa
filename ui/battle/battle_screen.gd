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
@onready var deck_pile_button: Button = %DeckPileButton


func _ready() -> void:
	# Подписываемся на события
	GameEvents.match_started.connect(_on_match_started)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.damage_applied.connect(_on_damage_applied)
	GameEvents.value_built.connect(_on_value_built)
	GameEvents.match_ended.connect(_on_match_ended)

	# ARC-016: просмотр колоды по клику на её "рубашку" внизу слева.
	deck_pile_button.pressed.connect(_on_deck_pile_pressed)

	# Тестовый запуск матча, если мы в этой сцене напрямую
	_setup_visual_containers()
	if MatchSettings.player_data:
		# ARC-016: run_deck пуст для тестового боя из главного меню (main_menu.gd
		# явно сбрасывает его) — setup_match() тогда сама уйдёт на старую
		# тестовую колоду.
		MatchManager.setup_match(MatchSettings.player_data, MatchSettings.enemy_data, MatchSettings.run_deck)
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


## ARC-080: раньше рендерился один Panel(20x10) на каждую единицу HP без
## ограничения сверху. wall_hp ничем не капается в бою (build_wall копится
## весь матч) — колонка блоков разрасталась на сотни пикселей, раздувала
## верхний StatsHBox и выталкивала остальной UI (в т.ч. ресурсы игрока) за
## пределы экрана. Теперь высота колонки жёстко ограничена MAX_VISUAL_BLOCKS.
const MAX_VISUAL_BLOCKS := 20


func _update_visuals(container: VBoxContainer, amount: int, color: Color) -> void:
	var visible_amount = clampi(amount, 0, MAX_VISUAL_BLOCKS)
	# Ensure count is correct: Remove panels from the TOP (Index 0)
	while container.get_child_count() > visible_amount:
		var child = container.get_child(0)
		container.remove_child(child)
		child.free()

	# Add new panels at the BOTTOM if we don't have enough
	while container.get_child_count() < visible_amount:
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
					# ARC-011: world_map_screen считает доступные для клика узлы от
					# current_node_index — без этого обновления игрок так и остался
					# бы "запертым" на первом этаже после первой же победы.
					if MatchSettings.world_map_data:
						var node_index: int = MatchSettings.world_map_data.map_nodes.find(
							MatchSettings.current_map_node
						)
						if node_index != -1:
							MatchSettings.world_map_data.current_node_index = node_index
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


## ARC-016: просмотр содержимого колоды (MatchManager.deck) — read-only,
## открывается кликом по "рубашке" внизу слева (%DeckPileButton).
func _on_deck_pile_pressed() -> void:
	_show_card_list_popup("Колода (%d)" % MatchManager.deck.size(), MatchManager.deck)


## Общий попап "список карт" — переиспользуем и для будущих "Сброс"/"Просмотр
## награды" и т.п., не только для колоды. Карты рендерятся через entities/card
## (card_scene) как в руке, но без подписки на card_clicked/card_right_clicked —
## это read-only просмотр, клик по карте здесь ничего не делает.
func _show_card_list_popup(title_text: String, cards: Array) -> void:
	var layer = CanvasLayer.new()
	add_child(layer)

	# Полноэкранная полупрозрачная подложка — клик по ней (не по панели поверх
	# неё) закрывает попап. Panel сверху по умолчанию останавливает mouse-ввод
	# (MOUSE_FILTER_STOP), поэтому клики внутри попапа сюда не доходят.
	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(
		func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				layer.queue_free()
	)
	layer.add_child(backdrop)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(720, 520)
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
	close_button.text = "Закрыть"
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
		empty_label.text = "Пусто"
		grid.add_child(empty_label)
	else:
		# Сортируем по типу ресурса, затем по стоимости — так проще пробежаться
		# глазами по колоде, чем по её реальному (перемешанному) порядку тяги,
		# который в любом случае не должен "спойлерить" следующую карту.
		var sorted_cards: Array = cards.duplicate()
		sorted_cards.sort_custom(_compare_cards_for_view)
		for card_data in sorted_cards:
			var card_node = card_scene.instantiate()
			grid.add_child(card_node)
			card_node.card_data = card_data


func _compare_cards_for_view(a: CardData, b: CardData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.card_name < b.card_name


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


func _on_damage_applied(_target: Resource, _amount: int, _hit_wall: bool) -> void:
	update_all_ui()
	# Тряска экрана при получении урона (ARC-004: раньше определялась по знаку
	# amount у health_changed; теперь damage_applied сам по себе — только урон).
	var original_position = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_position - Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)


func _on_value_built(_target: Resource, _amount: int, _part: String) -> void:
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

	bricks_label.text = "Bricks: %d (+%d)" % [p.bricks, p.quarry]
	gems_label.text = "Gems: %d (+%d)" % [p.gems, p.magic]
	beasts_label.text = "Beasts: %d (+%d)" % [p.beasts, p.dungeon]

	e_bricks_label.text = "Bricks: %d (+%d)" % [e.bricks, e.quarry]
	e_gems_label.text = "Gems: %d (+%d)" % [e.gems, e.magic]
	e_beasts_label.text = "Beasts: %d (+%d)" % [e.beasts, e.dungeon]

	# ARC-016: счётчик на "рубашке" колоды внизу слева.
	deck_pile_button.text = "Колода\n%d" % MatchManager.deck.size()


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
