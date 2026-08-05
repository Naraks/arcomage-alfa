extends Control
## ARC-014: узел «Событие» (docs/game_design_doc.md 7.1). Случайное EventData
## из data/events показывает текст + 2-3 варианта; выбор разыгрывает исход
## (возможен риск — несколько outcomes с вероятностями), применяет эффекты к
## MatchSettings и показывает результат перед возвратом на карту. Разметка
## строится кодом в _ready(), как и в ui/shop/shop_screen.gd.

const EVENTS_DIRECTORY := "res://data/events"

var _event: EventData
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
	# Фиксируем выбор немедленно: перезагрузка страницы не должна позволять
	# перебрасывать событие или возвращать его обратно в очередь.
	if is_inside_tree():
		RunSaveManager.save_run()
	return path


func _all_event_paths() -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(EVENTS_DIRECTORY):
		if file_name.ends_with(".tres"):
			paths.append("%s/%s" % [EVENTS_DIRECTORY, file_name])
	paths.sort()
	return paths


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.12)
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

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = _event.event_title
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_gold_label)
	_update_gold_label()

	var description := Label.new()
	description.text = _event.event_description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	root_vbox.add_child(description)

	_options_list = VBoxContainer.new()
	_options_list.add_theme_constant_override("separation", 8)
	root_vbox.add_child(_options_list)

	_result_panel = VBoxContainer.new()
	_result_panel.add_theme_constant_override("separation", 12)
	_result_panel.visible = false
	root_vbox.add_child(_result_panel)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_result_panel.add_child(_result_label)

	var continue_button := Button.new()
	continue_button.text = "Продолжить"
	continue_button.pressed.connect(_return_to_map)
	_result_panel.add_child(continue_button)

	_refresh_options()


func _update_gold_label() -> void:
	_gold_label.text = "Золото: %d" % MatchSettings.run_gold


func _refresh_options() -> void:
	for child in _options_list.get_children():
		child.queue_free()

	for option in _event.options:
		var button := Button.new()
		button.text = _option_label(option)
		button.disabled = MatchSettings.run_gold + _min_gold_delta(option) < 0
		button.pressed.connect(_on_option_chosen.bind(option))
		_options_list.add_child(button)


func _option_label(option: Dictionary) -> String:
	var outcomes: Array = option.get("outcomes", [])
	var marker := "⚠ Риск" if outcomes.size() > 1 else "✓ Гарантированно"
	return "%s · %s" % [marker, option.get("text", "")]


## Худший возможный расход золота среди всех outcomes варианта — на нём
## основано, дизейблить ли кнопку (варианты с риском могут иметь и
## гарантированную, и рискованную денежную часть одновременно).
func _min_gold_delta(option: Dictionary) -> int:
	var worst := 0
	var first := true
	for outcome in option.get("outcomes", []):
		var delta := 0
		for effect in outcome.get("effects", []):
			if effect.get("type") == "gold":
				delta += int(effect.get("value", 0))
		if first or delta < worst:
			worst = delta
			first = false
	return worst


## Выбирает исход варианта по вероятности (chance в сумме 100 по outcomes).
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


func _on_option_chosen(option: Dictionary) -> void:
	var outcome := _resolve_outcome(option.get("outcomes", []))
	_apply_effects(outcome.get("effects", []))
	_update_gold_label()

	_options_list.visible = false
	_result_label.text = outcome.get("result_text", "")
	_result_panel.visible = true


## Как shop_screen._on_back_pressed(): помечаем узел пройденным и обновляем
## current_node_index, иначе соседние узлы не откроются.
func _return_to_map() -> void:
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
