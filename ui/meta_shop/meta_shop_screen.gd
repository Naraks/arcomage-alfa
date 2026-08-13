extends Control
## Дерево постоянных улучшений и открытий редких карт.

signal profile_state_changed

const CARD_SCENE := preload("res://entities/card/card.tscn")
const UPGRADE_ORDER := ["tower", "wall", "quarry", "magic", "dungeon", "hand_size"]
const UPGRADE_GROUPS := {
	"Основание": ["tower", "wall"],
	"Ресурсы": ["quarry", "magic", "dungeon"],
	"Утилити": ["hand_size"],
}
const GROUP_ORDER := ["Основание", "Ресурсы", "Утилити"]
const PORTRAIT_BREAKPOINT := 760.0
const STATE_COLORS := {
	"affordable": Color("74d680"),
	"locked": Color("d8a76f"),
	"max": Color("b9b3c2"),
}

@export var embedded_in_profile := false

var _fame_label: Label
var _upgrade_list: VBoxContainer
var _unlock_list: VBoxContainer
var _feedback_label: Label
var _upgrade_grids: Array[GridContainer] = []
var _unlock_grid: GridContainer


func _ready() -> void:
	_build_ui()
	_apply_layout(get_viewport_rect().size)
	get_viewport().size_changed.connect(_on_viewport_size_changed)


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
	for side in ["left", "right", "top", "bottom"]:
		root_margin.add_theme_constant_override("margin_" + side, margin)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	root_margin.add_child(root_vbox)
	if not embedded_in_profile:
		_build_standalone_header(root_vbox)

	var intro := Label.new()
	intro.text = "ДЕРЕВО МАСТЕРСТВА"
	intro.add_theme_font_size_override("font_size", 22)
	intro.add_theme_color_override("font_color", Color("f1cf7a"))
	root_vbox.add_child(intro)

	_feedback_label = Label.new()
	_feedback_label.name = "PurchaseFeedback"
	_feedback_label.text = "Выберите следующую цель развития."
	_feedback_label.add_theme_color_override("font_color", Color("bcb6c2"))
	root_vbox.add_child(_feedback_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_upgrade_list = VBoxContainer.new()
	_upgrade_list.add_theme_constant_override("separation", 18)
	_upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_upgrade_list)
	_unlock_list = VBoxContainer.new()
	_unlock_list.add_theme_constant_override("separation", 10)
	_unlock_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_unlock_list)

	if not embedded_in_profile:
		var back_button := Button.new()
		back_button.text = "Назад в меню"
		back_button.pressed.connect(_on_back_pressed)
		root_vbox.add_child(back_button)
	_refresh_upgrade_list()
	_refresh_unlock_list()


func _build_standalone_header(root: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "ПРОФИЛЬ"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_fame_label = Label.new()
	_fame_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_fame_label)
	_update_fame_label()


func _update_fame_label() -> void:
	if _fame_label:
		_fame_label.text = "Слава: %d" % ProfileManager.profile.get("fame", 0)


func _upgrade_state(key: String) -> String:
	if ProfileManager.get_upgrade_next_cost(key) < 0:
		return "max"
	return "affordable" if ProfileManager.can_afford_upgrade(key) else "locked"


func _state_text(state: String) -> String:
	match state:
		"affordable":
			return "✓ ДОСТУПНО"
		"max":
			return "★ МАКСИМУМ"
		_:
			return "🔒 НУЖНО БОЛЬШЕ СЛАВЫ"


func _row_label_text(key: String) -> String:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG.get(key, {})
	if def.is_empty():
		return ""
	var level := ProfileManager.get_upgrade_level(key)
	var max_level: int = def["max_level"]
	var shown_value: int = def["per_level"] if level < max_level else def["per_level"] * level
	return "%s — %s (ур. %d/%d)" % [def["name"], def["desc"] % shown_value, level, max_level]


func _buy_button_text(key: String) -> String:
	var cost := ProfileManager.get_upgrade_next_cost(key)
	return "МАКС." if cost < 0 else "Купить · %d славы" % cost


func _refresh_upgrade_list() -> void:
	for child in _upgrade_list.get_children():
		child.queue_free()
	_upgrade_grids.clear()
	for group_name in GROUP_ORDER:
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 8)
		_upgrade_list.add_child(section)
		var title := Label.new()
		title.text = group_name.to_upper()
		title.add_theme_font_size_override("font_size", 18)
		section.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_child(grid)
		_upgrade_grids.append(grid)
		for key in UPGRADE_GROUPS[group_name]:
			grid.add_child(_make_upgrade_row(key))


func _make_upgrade_row(key: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Upgrade_" + key
	panel.custom_minimum_size = Vector2(280, 172)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_meta("state", _upgrade_state(key))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG[key]
	var level := ProfileManager.get_upgrade_level(key)
	var title := Label.new()
	title.text = def["name"]
	title.add_theme_font_size_override("font_size", 19)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var progress := Label.new()
	progress.name = "LevelLabel"
	progress.text = "УРОВЕНЬ %d / %d" % [level, def["max_level"]]
	box.add_child(progress)
	var effect := Label.new()
	effect.name = "NextEffectLabel"
	effect.text = (
		"Итоговый эффект: %s" % (def["desc"] % (def["per_level"] * level))
		if level >= def["max_level"]
		else "Следующий эффект: %s" % (def["desc"] % def["per_level"])
	)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(effect)
	var state := _upgrade_state(key)
	var status := Label.new()
	status.name = "StateLabel"
	status.text = _state_text(state)
	status.add_theme_color_override("font_color", STATE_COLORS[state])
	box.add_child(status)
	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = _buy_button_text(key)
	buy_button.custom_minimum_size.y = 44
	buy_button.disabled = state != "affordable"
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	box.add_child(buy_button)
	return panel


func _on_buy_pressed(key: String) -> void:
	if not ProfileManager.purchase_upgrade(key):
		return
	_update_fame_label()
	_feedback_label.text = (
		"Улучшение «%s» приобретено. Следующая цель обновлена."
		% ProfileManager.UPGRADE_CATALOG[key]["name"]
	)
	_feedback_label.add_theme_color_override("font_color", Color("74d680"))
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
	return "Открыто" if cost < 0 else "Открыть · %d славы" % cost


func _refresh_unlock_list() -> void:
	for child in _unlock_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "ОТКРЫТИЯ · РЕДКИЕ КАРТЫ"
	title.add_theme_font_size_override("font_size", 18)
	_unlock_list.add_child(title)
	_unlock_grid = GridContainer.new()
	_unlock_grid.columns = 2
	_unlock_grid.add_theme_constant_override("h_separation", 12)
	_unlock_grid.add_theme_constant_override("v_separation", 12)
	_unlock_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unlock_list.add_child(_unlock_grid)
	var paths := _rare_card_paths()
	if paths.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Нет редких карт для разблокировки"
		_unlock_grid.add_child(empty_label)
		return
	for path in paths:
		_unlock_grid.add_child(_make_unlock_row(path))


func _make_unlock_row(path: String) -> PanelContainer:
	var card: CardData = load(path)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 350)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var unlocked := ProfileManager.is_card_unlocked(card)
	var affordable := ProfileManager.can_afford_card_unlock(card)
	panel.set_meta("state", "max" if unlocked else ("affordable" if affordable else "locked"))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var preview = CARD_SCENE.instantiate()
	preview.name = "CardPreview"
	preview.card_data = card
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.tooltip_text = "Предпросмотр: карта не добавляется в колоду автоматически."
	box.add_child(preview)
	var status := Label.new()
	status.name = "StateLabel"
	status.text = (
		"★ ОТКРЫТО" if unlocked else ("✓ ДОСТУПНО" if affordable else "🔒 НУЖНО БОЛЬШЕ СЛАВЫ")
	)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", STATE_COLORS[panel.get_meta("state")])
	box.add_child(status)
	var button := Button.new()
	button.name = "UnlockButton"
	button.text = _unlock_button_text(path)
	button.custom_minimum_size.y = 44
	button.disabled = unlocked or not affordable
	button.pressed.connect(_on_unlock_pressed.bind(path))
	box.add_child(button)
	return panel


func _on_unlock_pressed(path: String) -> void:
	var card: CardData = load(path)
	if not ProfileManager.unlock_card(card):
		return
	_update_fame_label()
	_feedback_label.text = "Редкая карта «%s» открыта. Следующая цель обновлена." % card.card_name
	_feedback_label.add_theme_color_override("font_color", Color("74d680"))
	_refresh_unlock_list()
	profile_state_changed.emit()


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "mobile" if viewport_size.x < PORTRAIT_BREAKPOINT else "desktop"


func _apply_layout(viewport_size: Vector2) -> void:
	var columns := 1 if _layout_mode_for_size(viewport_size) == "mobile" else 2
	for grid in _upgrade_grids:
		grid.columns = columns
	if _unlock_grid:
		_unlock_grid.columns = columns


func _on_viewport_size_changed() -> void:
	_apply_layout(get_viewport_rect().size)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
