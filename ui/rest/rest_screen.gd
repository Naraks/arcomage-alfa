extends Control
## Выбор постоянного усиления в узле отдыха.

const TOWER_BONUS_AMOUNT := 5
const GENERATOR_BONUS_AMOUNT := 1
const MAX_TOWER_BONUS := 25
const MAX_GENERATOR_BONUS := 5
const TOWER_ICON := preload("res://art/rest/tower_foundation.png")
const GENERATOR_ICON := preload("res://art/rest/magic_source.png")

const GENERATOR_LABELS := {
	"quarry": "Карьер (Кирпичи)",
	"magic": "Магическая академия (Гемы)",
	"dungeon": "Подземелье (Звери)",
}

var _offered_generator: String = "quarry"
var _selected_option := ""
var _choice_resolved := false
var _option_panels: Array[PanelContainer] = []
var _confirm_button: Button
var _selection_hint: Label


func _ready() -> void:
	_offered_generator = _pick_random_generator()
	_build_ui()


func _pick_random_generator() -> String:
	var keys: Array = GENERATOR_LABELS.keys()
	return keys[randi() % keys.size()]


func _generator_label(key: String) -> String:
	return GENERATOR_LABELS.get(key, key)


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "wide" if ResponsiveLayout.is_wide_by_aspect(viewport_size) else "stacked"


func _current_generator_bonus(key: String) -> int:
	match key:
		"quarry":
			return MatchSettings.run_quarry_bonus
		"magic":
			return MatchSettings.run_magic_bonus
		"dungeon":
			return MatchSettings.run_dungeon_bonus
	return 0


func _option_state(option_key: String) -> Dictionary:
	var before := 0
	var amount := 0
	var maximum := 0
	if option_key == "tower":
		before = MatchSettings.run_tower_bonus
		amount = TOWER_BONUS_AMOUNT
		maximum = MAX_TOWER_BONUS
	else:
		before = _current_generator_bonus(_offered_generator)
		amount = GENERATOR_BONUS_AMOUNT
		maximum = MAX_GENERATOR_BONUS
	var after := mini(before + amount, maximum)
	var available := before < maximum
	return {
		"before": before,
		"after": after,
		"maximum": maximum,
		"available": available,
		"unavailable_reason": "Достигнут максимум: +%d" % maximum if not available else "",
	}


func _preview_text(option_key: String) -> String:
	var state := _option_state(option_key)
	if not state.available:
		return state.unavailable_reason
	return "Бонус: +%d → +%d" % [state.before, state.after]


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.055, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 20)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 16)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size.x = maxf(280.0, viewport_size.x - 40.0)
	scroll.add_child(root)

	var title := Label.new()
	title.text = "ПРИВАЛ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UIColors.GOLD)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Выберите одно усиление"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	root.add_child(subtitle)

	var duration := Label.new()
	duration.text = "Действует во всех следующих боях до конца текущего забега"
	duration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duration.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	duration.add_theme_color_override("font_color", Color(0.7, 0.76, 0.65))
	root.add_child(duration)

	var options: BoxContainer
	if _layout_mode_for_size(viewport_size) == "wide":
		options = HBoxContainer.new()
	else:
		options = VBoxContainer.new()
	options.add_theme_constant_override("separation", 16)
	options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(options)

	_option_panels = []
	var tower_panel := _make_option_panel(
		"tower", TOWER_ICON, "Заложить фундамент", "Башня начинает каждый бой выше."
	)
	options.add_child(tower_panel)
	_option_panels.append(tower_panel)
	var generator_panel := _make_option_panel(
		"generator",
		GENERATOR_ICON,
		"Улучшить источник",
		"%s начинает каждый бой уровнем выше." % _generator_label(_offered_generator)
	)
	options.add_child(generator_panel)
	_option_panels.append(generator_panel)

	_selection_hint = Label.new()
	_selection_hint.text = "Сначала выберите вариант. Бонус применяется после подтверждения."
	_selection_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_selection_hint)

	var confirm_row := HBoxContainer.new()
	confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(confirm_row)
	_confirm_button = Button.new()
	_confirm_button.text = "Подтвердить усиление"
	_confirm_button.disabled = true
	_confirm_button.custom_minimum_size = Vector2(320, 54)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_row.add_child(_confirm_button)


func _make_option_panel(
	option_key: String, icon_texture: Texture2D, title_text: String, description_text: String
) -> PanelContainer:
	var state := _option_state(option_key)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(260, 210)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(88, 88)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var description := Label.new()
	description.text = description_text
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var preview := Label.new()
	preview.text = _preview_text(option_key)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 20)
	preview.add_theme_color_override(
		"font_color", Color(0.92, 0.48, 0.38) if not state.available else Color(0.55, 0.85, 0.5)
	)
	box.add_child(preview)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var select := Button.new()
	select.text = "Недоступно" if not state.available else "Выбрать"
	select.disabled = not state.available
	select.tooltip_text = state.unavailable_reason
	select.pressed.connect(_on_option_selected.bind(option_key))
	box.add_child(select)
	return panel


func _on_option_selected(option_key: String) -> void:
	if _choice_resolved or not _option_state(option_key).available:
		return
	_selected_option = option_key
	for i in range(_option_panels.size()):
		var selected_index := 0 if option_key == "tower" else 1
		_option_panels[i].self_modulate = (
			Color(1.18, 1.12, 0.82) if i == selected_index else Color.WHITE
		)
	_confirm_button.disabled = false
	var selected_title := "Заложить фундамент" if option_key == "tower" else "Улучшить источник"
	_selection_hint.text = "Выбрано: %s" % selected_title


func _apply_selected_once() -> bool:
	if _choice_resolved or _selected_option.is_empty():
		return false
	if not _option_state(_selected_option).available:
		return false
	_choice_resolved = true
	if _selected_option == "tower":
		_apply_tower_bonus()
	else:
		_apply_generator_bonus(_offered_generator)
	return true


func _on_confirm_pressed() -> void:
	if not _apply_selected_once():
		return
	_confirm_button.disabled = true
	_return_to_map()


func _apply_tower_bonus() -> void:
	MatchSettings.run_tower_bonus = mini(
		MatchSettings.run_tower_bonus + TOWER_BONUS_AMOUNT, MAX_TOWER_BONUS
	)


func _apply_generator_bonus(key: String) -> void:
	match key:
		"quarry":
			MatchSettings.run_quarry_bonus = mini(
				MatchSettings.run_quarry_bonus + GENERATOR_BONUS_AMOUNT, MAX_GENERATOR_BONUS
			)
		"magic":
			MatchSettings.run_magic_bonus = mini(
				MatchSettings.run_magic_bonus + GENERATOR_BONUS_AMOUNT, MAX_GENERATOR_BONUS
			)
		"dungeon":
			MatchSettings.run_dungeon_bonus = mini(
				MatchSettings.run_dungeon_bonus + GENERATOR_BONUS_AMOUNT, MAX_GENERATOR_BONUS
			)


func _return_to_map() -> void:
	MatchSettings.complete_current_map_node()
	get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
