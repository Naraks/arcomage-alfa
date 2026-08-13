extends Control
## Просмотр состава колоды.

@export var embedded_in_profile := false

var _deck_list: VBoxContainer
var _source_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	if _source_label:
		return
	var root_margin := EmbeddedScreenLayout.build_shell(self, embedded_in_profile)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	root_margin.add_child(root_vbox)

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	if not embedded_in_profile:
		var title := Label.new()
		title.text = tr("UI_DECK_TITLE")
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
		back_button.text = tr("COMMON_BACK_TO_MENU")
		back_button.pressed.connect(_on_back_pressed)
		root_vbox.add_child(back_button)

	_refresh(_resolve_deck_to_show())


## Не просто геттер: при отсутствии активного забега в памяти подгружает его с
## диска (RunSaveManager.load_run() перезаписывает MatchSettings.*) — но только
## тогда, когда живого состояния ещё нет, чтобы не затереть несохранённый
## прогресс уже идущего забега (например, покупки в магазине ещё не
## сброшены на диск на момент открытия вкладки колоды в профиле).
func _resolve_deck_to_show() -> Array[CardData]:
	if MatchSettings.world_map_data != null:
		_source_label.text = tr("UI_DECK_SOURCE_RUN")
		return MatchSettings.run_deck
	if RunSaveManager.has_saved_run():
		RunSaveManager.load_run()
		_source_label.text = tr("UI_DECK_SOURCE_RUN")
		return MatchSettings.run_deck
	_source_label.text = tr("UI_DECK_SOURCE_PREVIEW")
	return MatchManager.build_starting_run_deck()


func _refresh(cards: Array[CardData]) -> void:
	for child in _deck_list.get_children():
		child.queue_free()

	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("UI_DECK_EMPTY")
		_deck_list.add_child(empty_label)
		return

	for entry in _group_cards(cards):
		var card: CardData = entry["card"]
		var count: int = entry["count"]
		var row := Label.new()
		row.text = tr("UI_DECK_ROW_FORMAT") % [card.get_display_name(), count, card.cost]
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
	return CardSortUtils.compare_by_type_cost_name(a, b)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
