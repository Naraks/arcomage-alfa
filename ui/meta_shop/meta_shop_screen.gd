extends Control
## Покупка постоянных улучшений и открытие карт.

signal profile_state_changed

const UPGRADE_ORDER := ["tower", "wall", "quarry", "magic", "dungeon", "hand_size"]

@export var embedded_in_profile := false

var _fame_label: Label
var _upgrade_list: VBoxContainer
var _unlock_list: VBoxContainer


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

	if not embedded_in_profile:
		var header := HBoxContainer.new()
		root_vbox.add_child(header)

		var title := Label.new()
		title.text = "МАГАЗИН ПРОКАЧКИ"
		title.add_theme_font_size_override("font_size", 28)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(title)

		_fame_label = Label.new()
		_fame_label.add_theme_font_size_override("font_size", 22)
		header.add_child(_fame_label)
		_update_fame_label()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 20)
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)

	var upgrades_title := Label.new()
	upgrades_title.text = "ПРОКАЧКА"
	upgrades_title.add_theme_font_size_override("font_size", 18)
	scroll_vbox.add_child(upgrades_title)

	_upgrade_list = VBoxContainer.new()
	_upgrade_list.add_theme_constant_override("separation", 8)
	_upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_child(_upgrade_list)

	var unlocks_title := Label.new()
	unlocks_title.text = "ОТКРЫТИЯ"
	unlocks_title.add_theme_font_size_override("font_size", 18)
	scroll_vbox.add_child(unlocks_title)

	_unlock_list = VBoxContainer.new()
	_unlock_list.add_theme_constant_override("separation", 8)
	_unlock_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_child(_unlock_list)

	if not embedded_in_profile:
		var back_button := Button.new()
		back_button.text = "Назад в меню"
		back_button.pressed.connect(_on_back_pressed)
		root_vbox.add_child(back_button)

	_refresh_upgrade_list()
	_refresh_unlock_list()


func _update_fame_label() -> void:
	if _fame_label:
		_fame_label.text = "Слава: %d" % ProfileManager.profile.get("fame", 0)


func _row_label_text(key: String) -> String:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG.get(key, {})
	if def.is_empty():
		return ""
	var level := ProfileManager.get_upgrade_level(key)
	var max_level: int = def["max_level"]
	var per_level: int = def["per_level"]
	var shown_value: int = per_level if level < max_level else per_level * level
	return "%s — %s (ур. %d/%d)" % [def["name"], def["desc"] % shown_value, level, max_level]


func _buy_button_text(key: String) -> String:
	var cost := ProfileManager.get_upgrade_next_cost(key)
	if cost < 0:
		return "МАКС."
	return "Купить за %d" % cost


func _refresh_upgrade_list() -> void:
	for child in _upgrade_list.get_children():
		child.queue_free()

	for key in UPGRADE_ORDER:
		_upgrade_list.add_child(_make_upgrade_row(key))


func _make_upgrade_row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = _row_label_text(key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = _buy_button_text(key)
	var next_cost := ProfileManager.get_upgrade_next_cost(key)
	buy_button.disabled = next_cost < 0 or not ProfileManager.can_afford_upgrade(key)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	row.add_child(buy_button)

	return row


func _on_buy_pressed(key: String) -> void:
	if not ProfileManager.purchase_upgrade(key):
		return
	_update_fame_label()
	_refresh_upgrade_list()
	profile_state_changed.emit()


func _rare_card_paths() -> Array:
	var result: Array = []
	for path in MatchManager.ALL_CARD_PATHS:
		var card: CardData = load(path)
		if card and card.rarity == CardData.Rarity.RARE:
			result.append(path)
	return result


func _unlock_row_text(path: String) -> String:
	var card: CardData = load(path)
	if not card:
		return ""
	var status := "разблокирована" if ProfileManager.is_card_unlocked(card) else "заблокирована"
	return "%s (cost %d, %s)" % [card.card_name, card.cost, status]


func _unlock_button_text(path: String) -> String:
	var card: CardData = load(path)
	var cost := ProfileManager.get_card_unlock_cost(card)
	if cost < 0:
		return "Открыто"
	return "Открыть за %d" % cost


func _refresh_unlock_list() -> void:
	for child in _unlock_list.get_children():
		child.queue_free()

	var paths := _rare_card_paths()
	if paths.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Нет редких карт для разблокировки"
		_unlock_list.add_child(empty_label)
		return

	for path in paths:
		_unlock_list.add_child(_make_unlock_row(path))


func _make_unlock_row(path: String) -> HBoxContainer:
	var card: CardData = load(path)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = _unlock_row_text(path)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var buy_button := Button.new()
	buy_button.name = "UnlockButton"
	buy_button.text = _unlock_button_text(path)
	var cost := ProfileManager.get_card_unlock_cost(card)
	buy_button.disabled = cost < 0 or not ProfileManager.can_afford_card_unlock(card)
	buy_button.pressed.connect(_on_unlock_pressed.bind(path))
	row.add_child(buy_button)

	return row


func _on_unlock_pressed(path: String) -> void:
	var card: CardData = load(path)
	if not ProfileManager.unlock_card(card):
		return
	_update_fame_label()
	_refresh_unlock_list()
	profile_state_changed.emit()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
