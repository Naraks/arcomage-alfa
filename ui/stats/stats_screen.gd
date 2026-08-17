extends Control
## История игрока, рекорды и прогресс коллекции.

const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")

@export var embedded_in_profile := false

var _ui_built := false
var _records_grid: GridContainer


func _ready() -> void:
	_build_ui()


func _rare_card_paths() -> Array:
	var result: Array = []
	for path in MatchManager.ALL_CARD_PATHS:
		var card: CardData = load(path)
		if card and card.rarity == CardData.Rarity.RARE:
			result.append(path)
	return result


func _collection_progress(unlocked_key: String, total: int) -> Dictionary:
	var unlocked: Array = ProfileManager.profile.get(unlocked_key, [])
	var count := mini(unlocked.size(), total)
	return {
		"count": count,
		"total": total,
		"ratio": float(count) / float(total) if total > 0 else 0.0,
	}


func _unlocked_cards_text() -> String:
	var progress := _collection_progress("unlocked_cards", _rare_card_paths().size())
	return tr("UI_STATS_UNLOCKED_CARDS") % [progress.count, progress.total]


func _unlocked_artifacts_text() -> String:
	var progress := _collection_progress(
		"unlocked_artifacts", RewardScreenScript.ALL_ARTIFACT_PATHS.size()
	)
	return tr("UI_STATS_UNLOCKED_ARTIFACTS") % [progress.count, progress.total]


func _win_summary() -> Dictionary:
	var runs: int = maxi(0, ProfileManager.profile.get("total_runs", 0))
	var wins: int = clampi(ProfileManager.profile.get("total_wins", 0), 0, runs)
	return {
		"wins": wins,
		"runs": runs,
		"winrate": roundi(float(wins) / float(runs) * 100.0) if runs > 0 else -1,
	}


func _empty_goal_text() -> String:
	if ProfileManager.profile.get("total_runs", 0) <= 0:
		return tr("UI_STATS_EMPTY_FIRST_RUN")
	if ProfileManager.profile.get("total_wins", 0) <= 0:
		return tr("UI_STATS_EMPTY_FIRST_WIN")
	return ""


func _layout_mode_for_size(viewport_size: Vector2) -> String:
	return "mobile" if ResponsiveLayout.is_narrow_by_width(viewport_size) else "desktop"


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	var root_margin := EmbeddedScreenLayout.build_shell(self, embedded_in_profile)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)

	if not embedded_in_profile:
		var title := Label.new()
		title.text = tr("UI_STATS_TITLE")
		title.add_theme_font_size_override("font_size", 28)
		content.add_child(title)

	_add_history_panel(content)
	_add_records_section(content)
	_add_collection_section(content)

	var goal := _empty_goal_text()
	if not goal.is_empty():
		var empty_panel := PanelContainer.new()
		content.add_child(empty_panel)
		var empty_label := Label.new()
		empty_label.text = goal
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", UIColors.GOLD)
		empty_panel.add_child(empty_label)

	if not embedded_in_profile:
		var back_button := Button.new()
		back_button.text = tr("COMMON_BACK_TO_MENU")
		back_button.pressed.connect(_on_back_pressed)
		content.add_child(back_button)

	resized.connect(_update_layout)
	_update_layout()


func _add_history_panel(parent: VBoxContainer) -> void:
	var summary := _win_summary()
	var panel := PanelContainer.new()
	panel.name = "HistoryPanel"
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var heading := Label.new()
	heading.text = tr("UI_STATS_HISTORY_TITLE")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", UIColors.GOLD)
	box.add_child(heading)
	var primary := Label.new()
	primary.text = tr("UI_STATS_WINS_OF_RUNS") % [summary.wins, summary.runs]
	primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	primary.add_theme_font_size_override("font_size", 34)
	box.add_child(primary)
	if summary.winrate >= 0:
		var winrate := Label.new()
		winrate.name = "WinrateLabel"
		winrate.text = tr("UI_STATS_WINRATE") % summary.winrate
		winrate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(winrate)


func _add_records_section(parent: VBoxContainer) -> void:
	_add_section_title(parent, tr("UI_STATS_RECORDS_TITLE"))
	_records_grid = GridContainer.new()
	_records_grid.name = "RecordsGrid"
	_records_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_records_grid.add_theme_constant_override("h_separation", 12)
	_records_grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(_records_grid)
	_add_record(
		_records_grid,
		tr("UI_STATS_TOWER_RECORD"),
		str(ProfileManager.profile.get("max_tower_height", 0)),
		tr("UI_STATS_TOWER_RECORD_HINT")
	)
	if ProfileManager.profile.has("best_run_floors"):
		_add_record(
			_records_grid,
			tr("UI_STATS_BEST_RUN_RECORD"),
			tr("UI_STATS_BEST_RUN_VALUE") % ProfileManager.profile.get("best_run_floors", 0),
			tr("UI_STATS_BEST_RUN_HINT")
		)


func _add_record(parent: GridContainer, title: String, value: String, hint: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color("bcb6c2"))
	box.add_child(title_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 28)
	value_label.add_theme_color_override("font_color", UIColors.GOLD)
	box.add_child(value_label)
	var hint_label := Label.new()
	hint_label.text = hint
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint_label)


func _add_collection_section(parent: VBoxContainer) -> void:
	_add_section_title(parent, tr("UI_STATS_COLLECTION_TITLE"))
	var cards := _collection_progress("unlocked_cards", _rare_card_paths().size())
	_add_progress(parent, _unlocked_cards_text(), cards.ratio)
	var artifacts := _collection_progress(
		"unlocked_artifacts", RewardScreenScript.ALL_ARTIFACT_PATHS.size()
	)
	_add_progress(parent, _unlocked_artifacts_text(), artifacts.ratio)


func _add_progress(parent: VBoxContainer, text: String, ratio: float) -> void:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var label := Label.new()
	label.text = text
	box.add_child(label)
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 24
	progress.max_value = 100
	progress.value = ratio * 100.0
	progress.show_percentage = true
	progress.tooltip_text = text
	box.add_child(progress)


func _add_section_title(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)


func _update_layout() -> void:
	if _records_grid:
		_records_grid.columns = 1 if _layout_mode_for_size(size) == "mobile" else 2


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
