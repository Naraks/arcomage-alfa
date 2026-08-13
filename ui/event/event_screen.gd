extends Control
## Экран выбора в случайном событии.

const EventIllustrationScript = preload("res://ui/event/event_illustration.gd")
const EVENTS_DIRECTORY := "res://data/events"

var _event: EventData
var _choice_resolved := false
var _gold_label: Label
var _options_list: VBoxContainer
var _result_panel: VBoxContainer
var _result_label: Label


func _ready() -> void:
	_event = load(_pick_random_event_path())
	_build_ui()


func _pick_random_event_path() -> String:
	var paths := _all_event_paths()
	if paths.is_empty():
		return ""
	var map_data = MatchSettings.world_map_data
	if map_data == null:
		return paths[randi() % paths.size()]
	if map_data.event_draw_pile.is_empty():
		map_data.event_draw_pile.assign(paths)
		map_data.event_draw_pile.shuffle()
	var path: String = map_data.event_draw_pile.pop_back()
	if is_inside_tree():
		RunSaveManager.save_run()
	return path


func _all_event_paths() -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(EVENTS_DIRECTORY):
		var resource_name := _event_resource_name(file_name)
		if not resource_name.is_empty():
			paths.append("%s/%s" % [EVENTS_DIRECTORY, resource_name])
	paths.sort()
	return paths


func _event_resource_name(file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return file_name
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".remap")
	return ""


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "wide" if ResponsiveLayout.is_wide_by_aspect(viewport_size) else "stacked"


func _content_minimum_size_for_viewport(viewport_size: Vector2) -> Vector2:
	return Vector2(maxf(280.0, viewport_size.x - 48.0), maxf(320.0, viewport_size.y - 32.0))


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.038, 0.032)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var content: BoxContainer
	if _layout_mode_for_size(get_viewport_rect().size) == "wide":
		content = HBoxContainer.new()
	else:
		content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = _content_minimum_size_for_viewport(get_viewport_rect().size)
	scroll.add_child(content)

	content.add_child(_build_story_panel())
	content.add_child(_build_decision_panel())
	_refresh_options()


func _build_story_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.9
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var illustration = EventIllustrationScript.new()
	illustration.configure(_event.event_title)
	illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(illustration)

	var title := Label.new()
	title.text = _event.event_title
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UIColors.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)

	var description := Label.new()
	description.text = _event.event_description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 18)
	box.add_child(description)
	return panel


func _build_decision_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.1
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var prompt := Label.new()
	prompt.text = "ВАШЕ РЕШЕНИЕ"
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(prompt)
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 18)
	header.add_child(_gold_label)
	_update_gold_label()

	_options_list = VBoxContainer.new()
	_options_list.add_theme_constant_override("separation", 10)
	_options_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_options_list)

	_result_panel = VBoxContainer.new()
	_result_panel.add_theme_constant_override("separation", 14)
	_result_panel.visible = false
	box.add_child(_result_panel)
	var result_title := Label.new()
	result_title.text = "ПОСЛЕДСТВИЕ"
	result_title.add_theme_font_size_override("font_size", 20)
	_result_panel.add_child(result_title)
	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_panel.add_child(_result_label)
	var continue_button := Button.new()
	continue_button.text = "Продолжить путь →"
	continue_button.custom_minimum_size.y = 52
	continue_button.pressed.connect(_return_to_map)
	_result_panel.add_child(continue_button)
	return panel


func _update_gold_label() -> void:
	_gold_label.text = "Золото: %d" % MatchSettings.run_gold


func _refresh_options() -> void:
	for child in _options_list.get_children():
		child.queue_free()
	for option in _event.options:
		_options_list.add_child(_build_option_panel(option))


func _build_option_panel(option: Dictionary) -> PanelContainer:
	var state := _option_state(option, MatchSettings.run_gold)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var button := Button.new()
	button.text = String(option.get("text", ""))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 50
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.disabled = not state.available or _choice_resolved
	button.tooltip_text = state.unavailable_reason
	button.pressed.connect(_on_option_chosen.bind(option))
	box.add_child(button)
	var details := Label.new()
	details.text = _option_details_text(state)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_color_override(
		"font_color", Color(0.94, 0.55, 0.42) if not state.available else Color(0.75, 0.72, 0.66)
	)
	box.add_child(details)
	return panel


func _gold_delta(outcome: Dictionary) -> int:
	var delta := 0
	for effect in outcome.get("effects", []):
		if effect.get("type") == "gold":
			delta += int(effect.get("value", 0))
	return delta


func _min_gold_delta(option: Dictionary) -> int:
	var worst := 0
	var first := true
	for outcome in option.get("outcomes", []):
		var delta := _gold_delta(outcome)
		if first or delta < worst:
			worst = delta
			first = false
	return worst


func _guaranteed_gold_cost(option: Dictionary) -> int:
	var outcomes: Array = option.get("outcomes", [])
	if outcomes.is_empty():
		return 0
	var shared_delta := _gold_delta(outcomes[0])
	for outcome in outcomes:
		if _gold_delta(outcome) != shared_delta:
			return 0
	return maxi(0, -shared_delta)


func _option_state(option: Dictionary, available_gold: int) -> Dictionary:
	var outcomes: Array = option.get("outcomes", [])
	var required_reserve := maxi(0, -_min_gold_delta(option))
	var shortfall := maxi(0, required_reserve - available_gold)
	return {
		"available": shortfall == 0,
		"shortfall": shortfall,
		"guaranteed_cost": _guaranteed_gold_cost(option),
		"required_reserve": required_reserve,
		"is_risky": outcomes.size() > 1,
		"unavailable_reason": "Не хватает %d золота" % shortfall if shortfall > 0 else "",
	}


func _option_details_text(state: Dictionary) -> String:
	var parts: Array[String] = []
	if state.guaranteed_cost > 0:
		parts.append("Цена: %d золота" % state.guaranteed_cost)
	elif state.required_reserve > 0:
		parts.append("Нужен запас: %d золота" % state.required_reserve)
	else:
		parts.append("Без затрат")
	parts.append("⚠ Риск: результат неизвестен" if state.is_risky else "✓ Результат гарантирован")
	if not state.available:
		parts.append(state.unavailable_reason)
	return "  •  ".join(parts)


func _resolve_outcome(outcomes: Array) -> Dictionary:
	var roll := randi() % 100
	var cumulative := 0
	for outcome in outcomes:
		cumulative += int(outcome.get("chance", 0))
		if roll < cumulative:
			return outcome
	return outcomes[-1] if not outcomes.is_empty() else {}


func _apply_effects(effects: Array) -> void:
	for effect in effects:
		var type: String = effect.get("type", "")
		var value: int = effect.get("value", 0)
		match type:
			"gold":
				MatchSettings.run_gold = max(0, MatchSettings.run_gold + value)
			"add_card":
				var card = load(effect.get("card_path", ""))
				if card:
					MatchSettings.run_deck.append(card)
			"run_tower_bonus":
				MatchSettings.run_tower_bonus += value
			"run_quarry_bonus":
				MatchSettings.run_quarry_bonus += value
			"run_magic_bonus":
				MatchSettings.run_magic_bonus += value
			"run_dungeon_bonus":
				MatchSettings.run_dungeon_bonus += value


func _apply_option_once(option: Dictionary) -> Dictionary:
	if _choice_resolved:
		return {}
	_choice_resolved = true
	var outcome := _resolve_outcome(option.get("outcomes", []))
	_apply_effects(outcome.get("effects", []))
	return outcome


func _on_option_chosen(option: Dictionary) -> void:
	var outcome := _apply_option_once(option)
	if outcome.is_empty():
		return
	_update_gold_label()
	_options_list.visible = false
	_result_label.text = outcome.get("result_text", "")
	_result_panel.visible = true


func _return_to_map() -> void:
	MatchSettings.complete_current_map_node()
	get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
