extends Control
## Выбор награды после победы.

const MapNodeData = preload("res://data/resources/map_node_data.gd")

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
var _slot_panels: Array[Panel] = []
var _confirm_button: Button


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

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(row)

	_slot_panels = []
	for i in range(_slots.size()):
		var panel := _make_slot_panel(_slots[i], i)
		row.add_child(panel)
		_slot_panels.append(panel)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root_vbox.add_child(actions)

	var skip_button := Button.new()
	skip_button.text = tr("UI_REWARD_SKIP")
	skip_button.pressed.connect(_on_skip_pressed)
	actions.add_child(skip_button)

	_confirm_button = Button.new()
	_confirm_button.text = tr("UI_REWARD_CONFIRM")
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	actions.add_child(_confirm_button)


func _make_slot_panel(slot: Dictionary, index: int) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(180, 220)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var name_label := Label.new()
	var desc_label := Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var tag_label := Label.new()
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if slot.get("kind") == "artifact":
		var artifact: ArtifactData = slot["artifact"]
		name_label.text = artifact.get_display_name()
		desc_label.text = artifact.get_display_description()
		tag_label.text = tr("UI_REWARD_ARTIFACT_TAG")
		panel.modulate = Color(1.0, 0.9, 0.5)
	else:
		var card: CardData = slot["card"]
		name_label.text = card.get_display_name()
		desc_label.text = card.get_display_description()
		tag_label.text = tr("UI_REWARD_COST_TAG") % card.cost

	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	vbox.add_child(tag_label)
	vbox.add_child(desc_label)

	var select_button := Button.new()
	select_button.text = tr("COMMON_SELECT")
	select_button.pressed.connect(_on_slot_pressed.bind(index))
	vbox.add_child(select_button)

	return panel


func _on_slot_pressed(index: int) -> void:
	_selected_index = index
	for i in range(_slot_panels.size()):
		_slot_panels[i].self_modulate = Color(1.4, 1.4, 1.0) if i == index else Color.WHITE
	_confirm_button.disabled = false


func _on_confirm_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _slots.size():
		return
	_apply_slot(_slots[_selected_index])
	_return_to_map()


func _apply_slot(slot: Dictionary) -> void:
	if slot.get("kind") == "artifact":
		MatchSettings.run_artifacts.append(slot["artifact"])
		ProfileManager.record_artifact_collected(slot["artifact"])
	else:
		MatchSettings.run_deck.append(slot["card"])


func _on_skip_pressed() -> void:
	_return_to_map()


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
