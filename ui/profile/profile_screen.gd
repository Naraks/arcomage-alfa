extends Control
## Общая оболочка разделов профиля.

const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")
const TAB_TITLES := ["Прокачка", "Статистика", "Колода"]
const MIN_TOUCH_TARGET := 44.0
const PORTRAIT_BREAKPOINT := 760.0

static var _last_tab_index := 0

var _tabs: TabContainer
var _fame_label: Label
var _profile_label: Label
var _collection_label: Label
var _side_nav: VBoxContainer
var _bottom_nav: HBoxContainer
var _side_buttons: Array[Button] = []
var _bottom_buttons: Array[Button] = []
var _leaving := false


func _ready() -> void:
	_tabs = $Tabs
	_tabs.current_tab = clampi(_last_tab_index, 0, _tabs.get_tab_count() - 1)
	_build_shell()
	_connect_content_state()
	_update_shared_state()
	_update_navigation_state()
	_apply_layout(get_viewport_rect().size)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if not _active_buttons().is_empty():
		_active_buttons()[_tabs.current_tab].grab_focus()


func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.05, 0.065)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

	var header_panel := PanelContainer.new()
	header_panel.name = "SharedHeader"
	header_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_panel.offset_left = 12
	header_panel.offset_top = 10
	header_panel.offset_right = -12
	header_panel.offset_bottom = 86
	add_child(header_panel)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 12)
	header_margin.add_theme_constant_override("margin_right", 12)
	header_margin.add_theme_constant_override("margin_top", 6)
	header_margin.add_theme_constant_override("margin_bottom", 6)
	header_panel.add_child(header_margin)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	header_margin.add_child(header)
	var primary_row := HBoxContainer.new()
	primary_row.add_theme_constant_override("separation", 10)
	header.add_child(primary_row)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "Назад"
	back_button.custom_minimum_size = Vector2(108, MIN_TOUCH_TARGET)
	back_button.pressed.connect(_on_back_pressed)
	primary_row.add_child(back_button)

	var title := Label.new()
	title.text = "ПРОФИЛЬ"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UIColors.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	primary_row.add_child(title)

	_fame_label = Label.new()
	_fame_label.add_theme_font_size_override("font_size", 20)
	_fame_label.add_theme_color_override("font_color", UIColors.GOLD)
	_fame_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	primary_row.add_child(_fame_label)

	var context_row := HBoxContainer.new()
	header.add_child(context_row)
	_profile_label = Label.new()
	_profile_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_label.add_theme_color_override("font_color", Color("bcb6c2"))
	context_row.add_child(_profile_label)
	_collection_label = Label.new()
	_collection_label.add_theme_color_override("font_color", Color("bcb6c2"))
	context_row.add_child(_collection_label)

	_side_nav = VBoxContainer.new()
	_side_nav.name = "SideNavigation"
	_side_nav.add_theme_constant_override("separation", 8)
	add_child(_side_nav)

	_bottom_nav = HBoxContainer.new()
	_bottom_nav.name = "BottomNavigation"
	_bottom_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_nav.add_theme_constant_override("separation", 6)
	add_child(_bottom_nav)

	for index in range(TAB_TITLES.size()):
		_side_buttons.append(_make_tab_button(TAB_TITLES[index], index, true))
		_bottom_buttons.append(_make_tab_button(TAB_TITLES[index], index, false))


func _make_tab_button(title: String, index: int, side: bool) -> Button:
	var button := Button.new()
	button.name = "%sTab%d" % ["Side" if side else "Bottom", index]
	button.text = title
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, MIN_TOUCH_TARGET)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_select_tab.bind(index))
	(_side_nav if side else _bottom_nav).add_child(button)
	return button


func _connect_content_state() -> void:
	var upgrades = _tabs.get_child(0)
	if upgrades.has_signal("profile_state_changed"):
		upgrades.profile_state_changed.connect(_update_shared_state)


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "mobile" if viewport_size.x < PORTRAIT_BREAKPOINT else "desktop"


func _apply_layout(viewport_size: Vector2) -> void:
	var mobile := _layout_mode_for_size(viewport_size) == "mobile"
	_side_nav.visible = not mobile
	_bottom_nav.visible = mobile

	if mobile:
		_side_nav.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tabs.offset_left = 10
		_tabs.offset_top = 96
		_tabs.offset_right = -10
		_tabs.offset_bottom = -64
		_bottom_nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_bottom_nav.offset_left = 10
		_bottom_nav.offset_top = -58
		_bottom_nav.offset_right = -10
		_bottom_nav.offset_bottom = -8
	else:
		_side_nav.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		_side_nav.offset_left = 14
		_side_nav.offset_top = 102
		_side_nav.offset_right = 208
		_side_nav.offset_bottom = -14
		_tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tabs.offset_left = 220
		_tabs.offset_top = 96
		_tabs.offset_right = -14
		_tabs.offset_bottom = -14
		_bottom_nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_update_navigation_state()


func _select_tab(index: int) -> bool:
	if _tabs == null or index < 0 or index >= _tabs.get_tab_count():
		return false
	_tabs.current_tab = index
	_last_tab_index = index
	_update_shared_state()
	_update_navigation_state()
	return true


func _update_navigation_state() -> void:
	if _tabs == null:
		return
	for index in range(_side_buttons.size()):
		_side_buttons[index].button_pressed = index == _tabs.current_tab
		_bottom_buttons[index].button_pressed = index == _tabs.current_tab


func _active_buttons() -> Array[Button]:
	return _bottom_buttons if _bottom_nav and _bottom_nav.visible else _side_buttons


func _profile_identifier() -> String:
	var value: String = (
		str(
			ProfileManager.profile.get(
				"display_name", ProfileManager.profile.get("profile_id", "Локальный профиль")
			)
		)
		. strip_edges()
	)
	return value if not value.is_empty() else "Локальный профиль"


func _collection_progress_text() -> String:
	var rare_total := 0
	for path in MatchManager.ALL_CARD_PATHS:
		var card: CardData = load(path)
		if card and card.rarity == CardData.Rarity.RARE:
			rare_total += 1
	var cards_open: int = ProfileManager.profile.get("unlocked_cards", []).size()
	var artifacts_open: int = ProfileManager.profile.get("unlocked_artifacts", []).size()
	return (
		"Коллекция: карты %d/%d · артефакты %d/%d"
		% [
			cards_open,
			rare_total,
			artifacts_open,
			RewardScreenScript.ALL_ARTIFACT_PATHS.size(),
		]
	)


func _update_shared_state() -> void:
	if _fame_label:
		_fame_label.text = "Слава: %d" % ProfileManager.profile.get("fame", 0)
	if _profile_label:
		_profile_label.text = _profile_identifier()
	if _collection_label:
		_collection_label.text = _collection_progress_text()


func _on_viewport_size_changed() -> void:
	_apply_layout(get_viewport_rect().size)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_back_pressed() -> bool:
	if _leaving:
		return false
	_leaving = true
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	return true
