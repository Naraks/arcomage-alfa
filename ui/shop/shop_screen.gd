extends Control
## ARC-012, UI 06/13 (#101): магазин забега с витриной на общем компоненте Card,
## явными состояниями покупки и отдельной безопасной чисткой колоды.
## Удаление требует подтверждения и не позволяет оставить забег без карт.

const CARD_SCENE := preload("res://entities/card/card.tscn")
const CARD_PRICE_MULTIPLIER := 2
const REMOVE_CARD_PRICE := 5
const MIN_DECK_SIZE := 1
const SHOP_OFFER_MIN := 3
const SHOP_OFFER_MAX := 5
const PORTRAIT_BREAKPOINT := 800.0

var _shop_offer: Array[CardData] = []
var _bought_cards: Dictionary = {}
var _transaction_in_progress := false
var _pending_remove_index := -1
var _gold_label: Label
var _buy_list: HFlowContainer
var _remove_list: VBoxContainer
var _remove_dialog: ConfirmationDialog


func _ready() -> void:
	if _shop_offer.is_empty():
		_shop_offer = MatchManager.build_shop_offer(randi_range(SHOP_OFFER_MIN, SHOP_OFFER_MAX))
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.045, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	page.add_theme_constant_override("separation", 12)
	add_child(page)

	var header := HBoxContainer.new()
	page.add_child(header)
	var title := Label.new()
	title.text = "МАГАЗИН"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 22)
	_gold_label.add_theme_color_override("font_color", Color("f1c75b"))
	header.add_child(_gold_label)
	_update_gold_label()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)

	_add_section_title(
		content, "ВИТРИНА КАРТ", "Выберите карту — цена и доступность указаны рядом с покупкой."
	)
	_buy_list = HFlowContainer.new()
	_buy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_list.add_theme_constant_override("h_separation", 14)
	_buy_list.add_theme_constant_override("v_separation", 14)
	content.add_child(_buy_list)

	var separator := HSeparator.new()
	content.add_child(separator)
	_add_section_title(
		content,
		"ЧИСТКА КОЛОДЫ",
		"Удаление стоит %d золота и всегда требует подтверждения." % REMOVE_CARD_PRICE
	)
	_remove_list = VBoxContainer.new()
	_remove_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_remove_list.add_theme_constant_override("separation", 8)
	content.add_child(_remove_list)

	var back_button := Button.new()
	back_button.text = "Уйти на карту →"
	back_button.custom_minimum_size.y = 48
	back_button.pressed.connect(_on_back_pressed)
	page.add_child(back_button)

	_remove_dialog = ConfirmationDialog.new()
	_remove_dialog.title = "Подтвердить чистку колоды"
	_remove_dialog.ok_button_text = "Удалить за %d золота" % REMOVE_CARD_PRICE
	_remove_dialog.cancel_button_text = "Отмена"
	_remove_dialog.confirmed.connect(_confirm_removal)
	_remove_dialog.canceled.connect(_cancel_removal)
	add_child(_remove_dialog)

	_refresh_all()


func _add_section_title(parent: Control, heading: String, explanation: String) -> void:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("e3c87d"))
	box.add_child(label)
	var help := Label.new()
	help.text = explanation
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", Color("aaa9a2"))
	box.add_child(help)


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "portrait" if viewport_size.x < PORTRAIT_BREAKPOINT else "wide"


func _update_gold_label() -> void:
	if _gold_label:
		_gold_label.text = "Золото: %d" % MatchSettings.run_gold


func _card_price(card: CardData) -> int:
	return max(1, card.cost * CARD_PRICE_MULTIPLIER)


func _offer_state(card: CardData) -> Dictionary:
	var price := _card_price(card)
	if _bought_cards.has(card.get_instance_id()):
		return {"available": false, "bought": true, "reason": "Уже куплено", "price": price}
	if MatchSettings.run_gold < price:
		return {
			"available": false, "bought": false, "reason": "Недостаточно золота", "price": price
		}
	return {"available": true, "bought": false, "reason": "Доступно", "price": price}


func _refresh_all() -> void:
	_update_gold_label()
	_refresh_buy_list()
	_refresh_remove_list()


func _refresh_buy_list() -> void:
	if not _buy_list:
		return
	for child in _buy_list.get_children():
		child.queue_free()
	for card in _shop_offer:
		_buy_list.add_child(_make_offer_panel(card))


func _make_offer_panel(card: CardData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 315)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var card_view = CARD_SCENE.instantiate()
	card_view.card_data = card
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(card_view)
	var state := _offer_state(card)
	var status := Label.new()
	status.text = state.reason
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override(
		"font_color", Color("74d680") if state.available else Color("d09a76")
	)
	box.add_child(status)
	var buy_button := Button.new()
	buy_button.text = "Купить · %d золота" % state.price
	buy_button.custom_minimum_size.y = 46
	buy_button.disabled = not state.available
	buy_button.pressed.connect(_on_buy_pressed.bind(card))
	box.add_child(buy_button)
	return panel


func _refresh_remove_list() -> void:
	if not _remove_list:
		return
	for child in _remove_list.get_children():
		child.queue_free()
	var indexed: Array = []
	for i in range(MatchSettings.run_deck.size()):
		indexed.append({"card": MatchSettings.run_deck[i], "index": i})
	indexed.sort_custom(func(a, b): return _compare_cards(a.card, b.card))
	for entry in indexed:
		var card: CardData = entry.card
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "%s  ·  стоимость карты: %d" % [card.card_name, card.cost]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(name_label)
		var remove_button := Button.new()
		remove_button.text = "Удалить · %d золота" % REMOVE_CARD_PRICE
		var reason := _removal_block_reason(entry.index)
		remove_button.disabled = not reason.is_empty()
		remove_button.tooltip_text = reason
		remove_button.pressed.connect(_request_removal.bind(entry.index))
		row.add_child(remove_button)
		_remove_list.add_child(row)
	if MatchSettings.run_deck.is_empty():
		var empty := Label.new()
		empty.text = "Колода пуста — удалять нечего."
		_remove_list.add_child(empty)
	elif MatchSettings.run_deck.size() <= MIN_DECK_SIZE:
		var warning := Label.new()
		warning.text = "Последнюю карту удалить нельзя: колода должна оставаться пригодной для боя."
		warning.add_theme_color_override("font_color", Color("d09a76"))
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_remove_list.add_child(warning)


func _compare_cards(a: CardData, b: CardData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.card_name < b.card_name


func _try_buy_card(card: CardData) -> bool:
	if _transaction_in_progress or card == null or not card in _shop_offer:
		return false
	var state := _offer_state(card)
	if not state.available:
		return false
	_transaction_in_progress = true
	MatchSettings.run_gold -= state.price
	MatchSettings.run_deck.append(card)
	_bought_cards[card.get_instance_id()] = true
	_transaction_in_progress = false
	return true


func _on_buy_pressed(card: CardData) -> void:
	if _try_buy_card(card):
		_refresh_all()


func _removal_block_reason(deck_index: int) -> String:
	if deck_index < 0 or deck_index >= MatchSettings.run_deck.size():
		return "Карта больше не находится в колоде"
	if MatchSettings.run_deck.size() <= MIN_DECK_SIZE:
		return "Нельзя удалить последнюю карту"
	if MatchSettings.run_gold < REMOVE_CARD_PRICE:
		return "Недостаточно золота"
	return ""


func _request_removal(deck_index: int) -> bool:
	if _transaction_in_progress or not _removal_block_reason(deck_index).is_empty():
		return false
	_pending_remove_index = deck_index
	if _remove_dialog:
		var card: CardData = MatchSettings.run_deck[deck_index]
		_remove_dialog.dialog_text = (
			"Удалить «%s» из колоды?\nИтоговая цена: %d золота.\nЭто действие нельзя отменить."
			% [card.card_name, REMOVE_CARD_PRICE]
		)
		_remove_dialog.popup_centered(Vector2i(440, 210))
	return true


func _confirm_removal() -> bool:
	if _transaction_in_progress or _pending_remove_index < 0:
		return false
	var deck_index := _pending_remove_index
	_pending_remove_index = -1
	if not _removal_block_reason(deck_index).is_empty():
		return false
	_transaction_in_progress = true
	MatchSettings.run_gold -= REMOVE_CARD_PRICE
	MatchSettings.run_deck.remove_at(deck_index)
	_transaction_in_progress = false
	_refresh_all()
	return true


func _cancel_removal() -> void:
	_pending_remove_index = -1


func _on_back_pressed() -> void:
	if MatchSettings.current_map_node:
		MatchSettings.current_map_node.is_completed = true
		if MatchSettings.world_map_data:
			var node_index: int = MatchSettings.world_map_data.map_nodes.find(
				MatchSettings.current_map_node
			)
			if node_index != -1:
				MatchSettings.world_map_data.current_node_index = node_index
	MatchSettings.current_map_node = null
	get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
