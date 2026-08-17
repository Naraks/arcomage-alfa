extends Control
## Выбор награды после победы.

const MapNodeData = preload("res://data/resources/map_node_data.gd")
const CARD_SCENE := preload("res://entities/card/card.tscn")

const REGULAR_SLOT_COUNT := 3
const ELITE_ARTIFACT_CHANCE := 30

const HIGH_RARITY_CARD_PATHS := [
	"res://data/cards/bricks_siege_engine.tres",
	"res://data/cards/gems_armageddon.tres",
]

const ALL_ARTIFACT_PATHS := [
	"res://data/artifacts/dwarf_pickaxe.tres",
	"res://data/artifacts/spiky_wall.tres",
	"res://data/artifacts/mana_sphere.tres",
	"res://data/artifacts/horn_of_plenty.tres",
	"res://data/artifacts/book_of_wisdom.tres",
	"res://data/artifacts/lucky_coin.tres",
	"res://data/artifacts/founders_blessing.tres",
	"res://data/artifacts/predator_fang.tres",
]

var _slots: Array[Dictionary] = []
var _selected_index: int = -1
var _slot_panels: Array[Button] = []
var _confirm_button: Button
var _skip_dialog: ConfirmationDialog
var _draft_list: BoxContainer
var _is_resolved := false


func _ready() -> void:
	var node_type: int = (
		MatchSettings.current_map_node.node_type
		if MatchSettings.current_map_node
		else MapNodeData.NodeType.BATTLE
	)
	_slots = _build_reward_slots(node_type)
	_build_ui()


func _build_reward_slots(node_type: int) -> Array[Dictionary]:
	match node_type:
		MapNodeData.NodeType.ELITE_BATTLE:
			return _build_elite_slots()
		MapNodeData.NodeType.BOSS:
			return _build_boss_slots()
		_:
			return _build_battle_slots()


func _build_battle_slots() -> Array[Dictionary]:
	var paths := _unlocked_paths(MatchManager.ALL_CARD_PATHS)
	paths.shuffle()

	var slots: Array[Dictionary] = []
	for i in range(mini(REGULAR_SLOT_COUNT, paths.size())):
		slots.append(_card_slot(paths[i]))
	return slots


func _build_elite_slots() -> Array[Dictionary]:
	var common_paths := _unlocked_paths(MatchManager.ALL_CARD_PATHS)
	common_paths.shuffle()

	var slots: Array[Dictionary] = []
	for i in range(mini(2, common_paths.size())):
		slots.append(_card_slot(common_paths[i]))
	var high_rarity_index := slots.size()
	slots.append(_card_slot(HIGH_RARITY_CARD_PATHS[randi() % HIGH_RARITY_CARD_PATHS.size()]))

	var available := _available_artifacts()
	if not available.is_empty() and randi() % 100 < ELITE_ARTIFACT_CHANCE and high_rarity_index > 0:
		var replace_index := randi() % high_rarity_index
		slots[replace_index] = _artifact_slot(available[randi() % available.size()])

	return slots


func _build_boss_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for path in HIGH_RARITY_CARD_PATHS:
		slots.append(_card_slot(path))

	var available := _available_artifacts()
	if not available.is_empty():
		slots.append(_artifact_slot(available[randi() % available.size()]))
	else:
		var common_paths := _unlocked_paths(MatchManager.ALL_CARD_PATHS)
		common_paths.shuffle()
		if not common_paths.is_empty():
			slots.append(_card_slot(common_paths[0]))

	return slots


func _unlocked_paths(paths: Array) -> Array:
	var result: Array = []
	for path in paths:
		var card: CardData = load(path)
		if card and ProfileManager.is_card_unlocked(card):
			result.append(path)
	return result


func _card_slot(path: String) -> Dictionary:
	return {"kind": "card", "card": load(path)}


func _artifact_slot(artifact: ArtifactData) -> Dictionary:
	return {"kind": "artifact", "artifact": artifact}


func _available_artifacts() -> Array:
	var owned: Array = MatchSettings.run_artifacts
	var available: Array = []
	for path in ALL_ARTIFACT_PATHS:
		var artifact: ArtifactData = load(path)
		if not owned.has(artifact):
			available.append(artifact)
	return available


func _build_ui() -> void:
	if _confirm_button:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 24)
	root_margin.add_theme_constant_override("margin_right", 24)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	root_margin.add_child(root_vbox)

	var title := Label.new()
	title.text = tr("UI_REWARD_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = tr("UI_REWARD_SUBTITLE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_draft_list = BoxContainer.new()
	_draft_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_draft_list.add_theme_constant_override("separation", 24)
	_draft_list.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(_draft_list)

	_slot_panels = []
	for i in range(_slots.size()):
		var panel := _make_slot_panel(_slots[i], i)
		_draft_list.add_child(panel)
		_slot_panels.append(panel)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root_vbox.add_child(actions)

	var skip_button := Button.new()
	skip_button.text = tr("UI_REWARD_SKIP")
	skip_button.flat = true
	skip_button.add_theme_color_override("font_color", Color("aaa9a2"))
	skip_button.pressed.connect(_on_skip_pressed)
	actions.add_child(skip_button)

	_confirm_button = Button.new()
	_confirm_button.text = tr("UI_REWARD_CONFIRM")
	_confirm_button.disabled = true
	_confirm_button.add_theme_color_override("font_color", Color("21180c"))
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = UIColors.GOLD
	confirm_style.set_corner_radius_all(8)
	confirm_style.content_margin_left = 20
	confirm_style.content_margin_right = 20
	_confirm_button.add_theme_stylebox_override("normal", confirm_style)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	actions.add_child(_confirm_button)

	_skip_dialog = ConfirmationDialog.new()
	_skip_dialog.title = tr("UI_REWARD_SKIP_DIALOG_TITLE")
	_skip_dialog.dialog_text = tr("UI_REWARD_SKIP_DIALOG_TEXT")
	_skip_dialog.ok_button_text = tr("UI_REWARD_SKIP_DIALOG_CONFIRM")
	_skip_dialog.cancel_button_text = tr("COMMON_CANCEL")
	_skip_dialog.confirmed.connect(_on_skip_confirmed)
	add_child(_skip_dialog)

	resized.connect(_update_layout)
	_update_layout()


func _make_slot_panel(slot: Dictionary, index: int) -> Button:
	var panel := Button.new()
	panel.custom_minimum_size = Vector2(190, 290)
	panel.focus_mode = Control.FOCUS_ALL
	panel.tooltip_text = tr("UI_REWARD_CARD_HINT")
	panel.pressed.connect(_on_slot_pressed.bind(index))
	_apply_slot_style(panel, false)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	if slot.get("kind") == "artifact":
		var artifact: ArtifactData = slot["artifact"]
		var name_label := Label.new()
		name_label.text = artifact.get_display_name()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		vbox.add_child(name_label)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(128, 128)
		icon.texture = artifact.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon)
		var tag_label := Label.new()
		tag_label.text = tr("UI_REWARD_ARTIFACT_TAG")
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_label.add_theme_color_override("font_color", UIColors.GOLD)
		vbox.add_child(tag_label)
		var desc_label := Label.new()
		desc_label.text = artifact.get_display_description()
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc_label)
		panel.modulate = Color(1.0, 0.9, 0.5)
	else:
		var card: CardData = slot["card"]
		var card_view := CARD_SCENE.instantiate()
		card_view.card_data = card
		_set_mouse_filter_recursive(card_view, Control.MOUSE_FILTER_IGNORE)
		vbox.add_child(card_view)
		var metadata := Label.new()
		metadata.text = "%s · %s" % [_resource_name(card.type), _rarity_name(card.rarity)]
		metadata.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metadata.add_theme_color_override("font_color", _resource_color(card.type))
		vbox.add_child(metadata)
		panel.mouse_entered.connect(_set_card_preview.bind(card_view, true))
		panel.mouse_exited.connect(_set_card_preview.bind(card_view, false))
		panel.focus_entered.connect(_set_card_preview.bind(card_view, true))
		panel.focus_exited.connect(_set_card_preview.bind(card_view, false))

	return panel


func _on_slot_pressed(index: int) -> void:
	if _is_resolved:
		return
	_selected_index = index
	for i in range(_slot_panels.size()):
		_apply_slot_style(_slot_panels[i], i == index)
	if _confirm_button:
		_confirm_button.disabled = false


func _on_confirm_pressed() -> void:
	if not _confirm_selection():
		return
	_return_to_map()


func _confirm_selection() -> bool:
	if _is_resolved or _selected_index < 0 or _selected_index >= _slots.size():
		return false
	_is_resolved = true
	_apply_slot(_slots[_selected_index])
	_disable_actions()
	return true


func _apply_slot(slot: Dictionary) -> void:
	if slot.get("kind") == "artifact":
		MatchSettings.run_artifacts.append(slot["artifact"])
		ProfileManager.record_artifact_collected(slot["artifact"])
	else:
		MatchSettings.run_deck.append(slot["card"])


func _on_skip_pressed() -> void:
	if not _is_resolved:
		_skip_dialog.popup_centered()


func _on_skip_confirmed() -> void:
	if _confirm_skip():
		_return_to_map()


func _confirm_skip() -> bool:
	if _is_resolved:
		return false
	_is_resolved = true
	_disable_actions()
	return true


func _disable_actions() -> void:
	if _confirm_button:
		_confirm_button.disabled = true
	for panel in _slot_panels:
		panel.disabled = true


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "portrait" if not ResponsiveLayout.is_wide_by_aspect(viewport_size) else "wide"


func _update_layout() -> void:
	if _draft_list:
		_draft_list.vertical = _layout_mode_for_size(size) == "portrait"


func _apply_slot_style(panel: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("332d24") if selected else Color("171816")
	style.border_color = UIColors.GOLD if selected else Color("55534a")
	style.set_border_width_all(4 if selected else 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("normal", style)
	panel.add_theme_stylebox_override("focus", style)


func _set_card_preview(card_view: Control, visible: bool) -> void:
	card_view.scale = Vector2(1.12, 1.12) if visible else Vector2.ONE
	card_view.z_index = 10 if visible else 0


func _set_mouse_filter_recursive(node: Control, filter: Control.MouseFilter) -> void:
	node.mouse_filter = filter
	for child in node.get_children():
		if child is Control:
			_set_mouse_filter_recursive(child, filter)


func _resource_name(type: CardData.ResourceType) -> String:
	match type:
		CardData.ResourceType.GEMS:
			return tr("UI_RESOURCE_GEMS")
		CardData.ResourceType.BEASTS:
			return tr("UI_RESOURCE_BEASTS")
		_:
			return tr("UI_RESOURCE_BRICKS")


func _resource_color(type: CardData.ResourceType) -> Color:
	match type:
		CardData.ResourceType.GEMS:
			return Color("7590ff")
		CardData.ResourceType.BEASTS:
			return Color("73d982")
		_:
			return Color("ef756d")


func _rarity_name(rarity: CardData.Rarity) -> String:
	match rarity:
		CardData.Rarity.UNCOMMON:
			return tr("UI_CARD_RARITY_UNCOMMON")
		CardData.Rarity.RARE:
			return tr("UI_CARD_RARITY_RARE")
		_:
			return tr("UI_CARD_RARITY_COMMON")


func _return_to_map() -> void:
	var was_boss: bool = (
		MatchSettings.current_map_node != null
		and MatchSettings.current_map_node.node_type == MapNodeData.NodeType.BOSS
	)

	MatchSettings.complete_current_map_node()
	MatchSettings.came_from_map = false

	if was_boss:
		MatchSettings.run_victory = true
		get_tree().change_scene_to_file("res://ui/run_summary/run_summary_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
