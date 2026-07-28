extends Control
## ARC-013: узел «Отдых» (docs/game_design_doc.md 7.1). Выбор одной из двух
## ПОСТОЯННЫХ НА ЭТОТ ЗАБЕГ опций — не разовое лечение player_data (Башня/
## Стена/ресурсы/генераторы всегда сбрасываются к базовым значениям в начале
## боя, см. 4.5), а модификатор в MatchSettings, который match_manager
## .setup_match() применяет при старте каждого боя забега.

const TOWER_BONUS_AMOUNT := 5
const GENERATOR_BONUS_AMOUNT := 1

const GENERATOR_LABELS := {
	"quarry": "Карьер (генератор Кирпичей)",
	"magic": "Магическая академия (генератор Гемов)",
	"dungeon": "Подземелье (генератор Зверей)",
}

var _offered_generator: String = "quarry"


func _ready() -> void:
	_offered_generator = _pick_random_generator()
	_build_ui()


func _pick_random_generator() -> String:
	var keys: Array = GENERATOR_LABELS.keys()
	return keys[randi() % keys.size()]


func _generator_label(key: String) -> String:
	return GENERATOR_LABELS.get(key, key)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.1)
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
	title.text = "ОТДЫХ"
	title.add_theme_font_size_override("font_size", 28)
	root_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Выберите одно постоянное усиление на этот забег:"
	root_vbox.add_child(subtitle)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	columns.add_child(
		_make_option_panel(
			"Заложить фундамент",
			"Башня стартует на +%d в каждом бою этого забега" % TOWER_BONUS_AMOUNT,
			_on_tower_option_chosen
		)
	)
	columns.add_child(
		_make_option_panel(
			"Улучшить рудник",
			"%s стартует на +%d уровня в каждом бою этого забега"
			% [_generator_label(_offered_generator), GENERATOR_BONUS_AMOUNT],
			_on_generator_option_chosen
		)
	)


func _make_option_panel(title_text: String, description_text: String, on_chosen: Callable) -> Panel:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	var description_label := Label.new()
	description_label.text = description_text
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(description_label)

	var choose_button := Button.new()
	choose_button.text = "Выбрать"
	choose_button.pressed.connect(on_chosen)
	vbox.add_child(choose_button)

	return panel


func _on_tower_option_chosen() -> void:
	_apply_tower_bonus()
	_return_to_map()


func _on_generator_option_chosen() -> void:
	_apply_generator_bonus(_offered_generator)
	_return_to_map()


## Отделено от _return_to_map() (трогает get_tree()), чтобы тестировалось без
## добавления в дерево сцены (tests/test_rest_screen.gd).
func _apply_tower_bonus() -> void:
	MatchSettings.run_tower_bonus += TOWER_BONUS_AMOUNT


func _apply_generator_bonus(key: String) -> void:
	match key:
		"quarry":
			MatchSettings.run_quarry_bonus += GENERATOR_BONUS_AMOUNT
		"magic":
			MatchSettings.run_magic_bonus += GENERATOR_BONUS_AMOUNT
		"dungeon":
			MatchSettings.run_dungeon_bonus += GENERATOR_BONUS_AMOUNT


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
