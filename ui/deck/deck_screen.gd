extends Control
## Просмотр состава колоды.

@export var embedded_in_profile := false

var _deck_list: VBoxContainer
var _source_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	if not embedded_in_profile:
		var bg := ColorRect.new()
		bg.color = Color(0.1, 0.1, 0.12)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := 12 if embedded_in_profile else 24
	root_margin.add_theme_constant_override("margin_left", margin)
	root_margin.add_theme_constant_override("margin_right", margin)
	root_margin.add_theme_constant_override("margin_top", margin)
	root_margin.add_theme_constant_override("margin_bottom", margin)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	root_margin.add_child(root_vbox)

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	if not embedded_in_profile:
		var title := Label.new()
		title.text = "КОЛОДА"
		title.add_theme_font_size_override("font_size", 28)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(title)

	_source_label = Label.new()
	_source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_source_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_deck_list = VBoxContainer.new()
	_deck_list.add_theme_constant_override("separation", 6)
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_deck_list)

	if not embedded_in_profile:
		var back_button := Button.new()
		back_button.text = "Назад в меню"
		back_button.pressed.connect(_on_back_pressed)
		root_vbox.add_child(back_button)

	_refresh(_load_deck_to_show())


func _load_deck_to_show() -> Array[CardData]:
	if RunSaveManager.has_saved_run():
		RunSaveManager.load_run()
		_source_label.text = "Колода текущего забега"
		return MatchSettings.run_deck
	_source_label.text = "Нет активного забега — превью стартовой колоды новой кампании"
	return MatchManager.build_starting_run_deck()


func _refresh(cards: Array[CardData]) -> void:
	for child in _deck_list.get_children():
		child.queue_free()

	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Колода пуста"
		_deck_list.add_child(empty_label)
		return

	for entry in _group_cards(cards):
		var card: CardData = entry["card"]
		var count: int = entry["count"]
		var row := Label.new()
		row.text = "%s ×%d (cost %d)" % [card.card_name, count, card.cost]
		_deck_list.add_child(row)


func _group_cards(cards: Array[CardData]) -> Array:
	var counts: Dictionary = {}
	var order: Array[CardData] = []
	for card in cards:
		if not counts.has(card):
			counts[card] = 0
			order.append(card)
		counts[card] += 1

	order.sort_custom(_compare_cards)

	var result: Array = []
	for card in order:
		result.append({"card": card, "count": counts[card]})
	return result


func _compare_cards(a: CardData, b: CardData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.card_name < b.card_name


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
