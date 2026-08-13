extends Control
## Итоги завершённого забега.

const MapNodeData = preload("res://data/resources/map_node_data.gd")

const FAME_PER_FLOOR := 10
const FAME_PER_ELITE := 15
const FAME_BOSS_VICTORY_BONUS := 100

var _ui_built := false


func _ready() -> void:
	var floors_passed := _count_completed_nodes()
	var elites_defeated := _count_completed_elites()
	var fame_earned := _calculate_fame(floors_passed, elites_defeated, MatchSettings.run_victory)

	ProfileManager.add_fame(fame_earned)
	ProfileManager.record_run_finished(MatchSettings.run_victory)

	_build_ui(floors_passed, elites_defeated, fame_earned)


func _count_completed_nodes() -> int:
	if not MatchSettings.world_map_data:
		return 0
	var count := 0
	for node in MatchSettings.world_map_data.map_nodes:
		if node.is_completed:
			count += 1
	return count


func _count_completed_elites() -> int:
	if not MatchSettings.world_map_data:
		return 0
	var count := 0
	for node in MatchSettings.world_map_data.map_nodes:
		if node.is_completed and node.node_type == MapNodeData.NodeType.ELITE_BATTLE:
			count += 1
	return count


func _calculate_fame(floors_passed: int, elites_defeated: int, is_victory: bool) -> int:
	var fame := floors_passed * FAME_PER_FLOOR + elites_defeated * FAME_PER_ELITE
	if is_victory:
		fame += FAME_BOSS_VICTORY_BONUS
	return fame


func _build_ui(floors_passed: int, elites_defeated: int, fame_earned: int) -> void:
	if _ui_built:
		return
	_ui_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
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
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_theme_constant_override("separation", 12)
	root_margin.add_child(root_vbox)

	var title := Label.new()
	title.text = "ПОБЕДА НАД БОССОМ!" if MatchSettings.run_victory else "ЗАБЕГ ОКОНЧЕН"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root_vbox.add_child(title)

	_add_stat_label(root_vbox, "Пройдено этажей: %d" % floors_passed)
	_add_stat_label(root_vbox, "Побеждено элит: %d" % elites_defeated)
	_add_stat_label(root_vbox, "Золото забега (не сохранится): %d" % MatchSettings.run_gold)
	_add_stat_label(root_vbox, "Собрано артефактов: %d" % MatchSettings.run_artifacts.size())
	for artifact in MatchSettings.run_artifacts:
		_add_stat_label(root_vbox, "  · %s" % artifact.artifact_name)

	var fame_label := Label.new()
	fame_label.text = (
		"Слава за забег: +%d (всего: %d)" % [fame_earned, ProfileManager.profile.get("fame", 0)]
	)
	fame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fame_label.add_theme_font_size_override("font_size", 20)
	root_vbox.add_child(fame_label)

	var menu_button := Button.new()
	menu_button.text = "В главное меню"
	menu_button.pressed.connect(_on_menu_pressed)
	root_vbox.add_child(menu_button)


func _add_stat_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)


func _on_menu_pressed() -> void:
	RunSaveManager.clear_run()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
