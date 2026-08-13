extends Control
## Главное меню и точки входа в игровые режимы.

const DefaultAIStrategyScript = preload("res://data/resources/default_ai_strategy.gd")
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")
const BuilderAIStrategyScript = preload("res://data/resources/builder_ai_strategy.gd")
const EconomistAIStrategyScript = preload("res://data/resources/economist_ai_strategy.gd")
const BossAIStrategyScript = preload("res://data/resources/boss_ai_strategy.gd")
const MainMenuBackdropScript = preload("res://ui/main_menu_backdrop.gd")
const TITLE_FONT: FontFile = preload("res://fonts/YesevaOne-Regular.ttf")

const GAME_TITLE := "Башни магов: Дуэль"
const GAME_TITLE_PRIMARY := "БАШНИ МАГОВ"
const GAME_TITLE_SECONDARY := "ДУЭЛЬ"
const INK := Color("#101522")
const TEXT_PRIMARY := Color("#f6f0e4")
const TEXT_MUTED := Color("#b7b3ad")

const DEBUG_STRATEGY_NAMES := ["Сбалансированный", "Агрессор", "Строитель", "Экономист", "Босс"]
const DEBUG_STRATEGY_SCRIPTS := [
	DefaultAIStrategyScript,
	AggressiveAIStrategyScript,
	BuilderAIStrategyScript,
	EconomistAIStrategyScript,
	BossAIStrategyScript,
]

var _menu_panel: PanelContainer
var _continue_button: Button
var _campaign_button: Button
var _battle_button: Button
var _profile_button: Button
var _settings_button: Button
var _version_label: Label


func _ready() -> void:
	_build_ui()
	_version_label.text = BuildVersion.get_display_string()

	var has_saved_run := RunSaveManager.has_saved_run()
	var progress_text := _read_saved_run_progress() if has_saved_run else ""
	_configure_run_actions(has_saved_run, progress_text)

	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	call_deferred("_focus_primary_action")

	if OS.is_debug_build():
		_generate_debug_ai_picker_bar()


func _build_ui() -> void:
	if _menu_panel:
		return

	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := MainMenuBackdropScript.new()
	backdrop.name = "CinematicBackdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var veil := ColorRect.new()
	veil.name = "ContrastVeil"
	veil.color = Color(0.02, 0.025, 0.055, 0.18)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	_menu_panel = PanelContainer.new()
	_menu_panel.name = "MenuPanel"
	_menu_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_menu_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 30)
	panel_margin.add_theme_constant_override("margin_right", 30)
	panel_margin.add_theme_constant_override("margin_top", 26)
	panel_margin.add_theme_constant_override("margin_bottom", 26)
	_menu_panel.add_child(panel_margin)

	var stack := VBoxContainer.new()
	stack.name = "MenuStack"
	stack.add_theme_constant_override("separation", 10)
	panel_margin.add_child(stack)

	var eyebrow := Label.new()
	eyebrow.text = "КАРТОЧНАЯ СТРАТЕГИЯ"
	eyebrow.add_theme_color_override("font_color", UIColors.GOLD)
	eyebrow.add_theme_font_size_override("font_size", 13)
	stack.add_child(eyebrow)

	var logo := Label.new()
	logo.name = "Logo"
	logo.text = GAME_TITLE_PRIMARY
	logo.add_theme_font_override("font", TITLE_FONT)
	logo.add_theme_color_override("font_color", TEXT_PRIMARY)
	logo.add_theme_font_size_override("font_size", 42)
	stack.add_child(logo)

	var title_suffix := Label.new()
	title_suffix.name = "TitleSuffix"
	title_suffix.text = GAME_TITLE_SECONDARY
	title_suffix.add_theme_color_override("font_color", UIColors.GOLD)
	title_suffix.add_theme_font_size_override("font_size", 20)
	stack.add_child(title_suffix)

	var tagline := Label.new()
	tagline.text = "Возведи башню. Сломи стену.\nПереиграй соперника."
	tagline.add_theme_color_override("font_color", TEXT_MUTED)
	tagline.add_theme_font_size_override("font_size", 17)
	stack.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	stack.add_child(spacer)

	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.custom_minimum_size = Vector2(0.0, 72.0)
	_continue_button.pressed.connect(_on_continue_pressed)
	stack.add_child(_continue_button)

	_campaign_button = Button.new()
	_campaign_button.name = "CampaignButton"
	_campaign_button.text = "Новый забег"
	_campaign_button.custom_minimum_size = Vector2(0.0, 54.0)
	_campaign_button.pressed.connect(_on_campaign_pressed)
	stack.add_child(_campaign_button)

	_battle_button = Button.new()
	_battle_button.name = "BattleButton"
	_battle_button.text = "Быстрый бой"
	_battle_button.tooltip_text = "Одиночная дуэль против случайного архетипа ИИ"
	_battle_button.custom_minimum_size = Vector2(0.0, 52.0)
	_battle_button.pressed.connect(_on_battle_pressed)
	_apply_button_style(_battle_button, false)
	stack.add_child(_battle_button)

	var secondary_row := HBoxContainer.new()
	secondary_row.name = "SecondaryActions"
	secondary_row.add_theme_constant_override("separation", 10)
	stack.add_child(secondary_row)

	_profile_button = Button.new()
	_profile_button.name = "ProfileButton"
	_profile_button.text = "Профиль"
	_profile_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_button.custom_minimum_size = Vector2(0.0, 48.0)
	_profile_button.pressed.connect(_on_profile_pressed)
	_apply_button_style(_profile_button, false, true)
	secondary_row.add_child(_profile_button)

	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.text = "Настройки"
	_settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_button.custom_minimum_size = Vector2(0.0, 48.0)
	_settings_button.pressed.connect(_on_settings_pressed)
	_apply_button_style(_settings_button, false, true)
	secondary_row.add_child(_settings_button)

	var footer := Label.new()
	footer.text = "Одна карта может решить исход дуэли."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.72, 0.70, 0.67, 0.72))
	footer.add_theme_font_size_override("font_size", 12)
	stack.add_child(footer)

	_version_label = Label.new()
	_version_label.name = "VersionLabel"
	_version_label.text = "dev"
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_version_label.add_theme_color_override("font_color", Color(0.90, 0.87, 0.81, 0.64))
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_version_label.offset_left = -244.0
	_version_label.offset_top = 14.0
	_version_label.offset_right = -18.0
	_version_label.offset_bottom = 36.0
	add_child(_version_label)


func _run_cta_state(has_saved_run: bool, progress_text: String = "") -> Dictionary:
	var safe_progress := progress_text.strip_edges()
	if safe_progress.is_empty():
		safe_progress = "Сохранённый забег"
	return {
		"continue_visible": has_saved_run,
		"continue_disabled": not has_saved_run,
		"continue_text": "Продолжить забег\n%s" % safe_progress,
		"new_run_is_primary": not has_saved_run,
	}


func _configure_run_actions(has_saved_run: bool, progress_text: String = "") -> void:
	var state := _run_cta_state(has_saved_run, progress_text)
	_continue_button.visible = state.continue_visible
	_continue_button.disabled = state.continue_disabled
	_continue_button.text = state.continue_text
	_apply_button_style(_continue_button, has_saved_run)

	_campaign_button.text = "Новый забег"
	_campaign_button.custom_minimum_size.y = 54.0 if has_saved_run else 66.0
	_apply_button_style(_campaign_button, state.new_run_is_primary)


func _read_saved_run_progress() -> String:
	var data = ResourceLoader.load(RunSaveManager.SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if data == null or not (data is RunSaveData):
		return "Сохранённый забег"
	return _format_run_progress(data.world_map_data)


func _format_run_progress(map_data: WorldMapData) -> String:
	if map_data == null or map_data.floor_count <= 0:
		return "Сохранённый забег"

	var next_floor := 1
	var current_index := map_data.current_node_index
	if current_index >= 0 and current_index < map_data.map_nodes.size():
		var current_node = map_data.map_nodes[current_index]
		if current_node is MapNodeData:
			next_floor = current_node.floor_index + 1
			if current_node.is_completed:
				next_floor += 1
	next_floor = clampi(next_floor, 1, map_data.floor_count)
	return "Этаж %d из %d" % [next_floor, map_data.floor_count]


func _focus_primary_action() -> void:
	if not is_inside_tree():
		return
	if _continue_button.visible and not _continue_button.disabled:
		_continue_button.grab_focus()
	else:
		_campaign_button.grab_focus()


func _apply_responsive_layout() -> void:
	if not _menu_panel:
		return
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var portrait := viewport_size.x < viewport_size.y * 0.9

	if portrait:
		_menu_panel.anchor_left = 0.0
		_menu_panel.anchor_top = 1.0
		_menu_panel.anchor_right = 1.0
		_menu_panel.anchor_bottom = 1.0
		_menu_panel.offset_left = 14.0
		_menu_panel.offset_right = -14.0
		_menu_panel.offset_top = -minf(590.0, viewport_size.y * 0.62)
		_menu_panel.offset_bottom = -14.0
	else:
		var panel_width := minf(470.0, viewport_size.x * 0.43)
		var panel_height := minf(590.0, viewport_size.y - 48.0)
		var left := maxf(28.0, viewport_size.x * 0.045)
		var top := (viewport_size.y - panel_height) * 0.5
		_menu_panel.anchor_left = 0.0
		_menu_panel.anchor_top = 0.0
		_menu_panel.anchor_right = 0.0
		_menu_panel.anchor_bottom = 0.0
		_menu_panel.offset_left = left
		_menu_panel.offset_top = top
		_menu_panel.offset_right = left + panel_width
		_menu_panel.offset_bottom = top + panel_height


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.085, 0.92)
	style.border_color = Color(0.91, 0.67, 0.31, 0.46)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _button_style(background: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_right = 9
	style.corner_radius_bottom_left = 9
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _apply_button_style(button: Button, primary: bool, quiet: bool = false) -> void:
	if primary:
		button.add_theme_stylebox_override("normal", _button_style(UIColors.GOLD, UIColors.GOLD, 1))
		button.add_theme_stylebox_override(
			"hover", _button_style(UIColors.GOLD_HOVER, UIColors.GOLD_HOVER, 1)
		)
		button.add_theme_stylebox_override(
			"pressed", _button_style(UIColors.GOLD_PRESSED, UIColors.GOLD, 1)
		)
		button.add_theme_stylebox_override("focus", _button_style(UIColors.GOLD, Color.WHITE, 2))
		button.add_theme_color_override("font_color", INK)
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", INK)
		button.add_theme_color_override("font_focus_color", INK)
		button.add_theme_font_size_override("font_size", 20)
	else:
		var alpha := 0.36 if quiet else 0.68
		button.add_theme_stylebox_override(
			"normal",
			_button_style(Color(0.10, 0.13, 0.20, alpha), Color(0.67, 0.62, 0.55, 0.42), 1)
		)
		button.add_theme_stylebox_override(
			"hover", _button_style(Color(0.18, 0.21, 0.29, 0.96), UIColors.GOLD, 1)
		)
		button.add_theme_stylebox_override(
			"pressed", _button_style(Color(0.07, 0.09, 0.15, 0.96), UIColors.GOLD, 1)
		)
		button.add_theme_stylebox_override(
			"focus", _button_style(Color(0.13, 0.16, 0.24, 0.96), UIColors.GOLD, 2)
		)
		button.add_theme_color_override("font_color", TEXT_PRIMARY)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
		button.add_theme_color_override("font_focus_color", Color.WHITE)
		button.add_theme_font_size_override("font_size", 17 if quiet else 18)

	button.add_theme_stylebox_override(
		"disabled", _button_style(Color(0.10, 0.11, 0.15, 0.46), Color(0.35, 0.35, 0.38, 0.34), 1)
	)
	button.add_theme_color_override("font_disabled_color", Color(0.65, 0.64, 0.62, 0.55))


func _on_continue_pressed():
	if not RunSaveManager.load_run():
		print("[ERROR] Continue pressed but no valid saved run found")
		return
	get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")


func _on_campaign_pressed():
	print("Campaign pressed - loading world map")

	MatchSettings.world_map_data = WorldMapGenerator.generate_map(randi())

	MatchSettings.run_deck = MatchManager.build_starting_run_deck()

	MatchSettings.run_gold = MatchManager.STARTING_RUN_GOLD

	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0

	MatchSettings.run_artifacts = []

	var err = get_tree().change_scene_to_file("res://ui/map/world_map_screen.tscn")
	print("Change scene result: ", err)


func _on_battle_pressed():
	_start_test_battle(MatchManager.pick_random_regular_ai_strategy())


func _start_test_battle(enemy_ai_strategy: Resource = null) -> void:
	print("Battle pressed - loading battle screen")
	_prepare_test_battle_settings(enemy_ai_strategy)
	get_tree().change_scene_to_file("res://ui/battle/battle_screen.tscn")


func _prepare_test_battle_settings(enemy_ai_strategy: Resource = null) -> void:
	var p_data = PlayerData.new()
	var e_data = PlayerData.new()
	if enemy_ai_strategy:
		e_data.ai_strategy = enemy_ai_strategy
	MatchSettings.player_data = p_data
	MatchSettings.enemy_data = e_data

	MatchSettings.came_from_map = false
	MatchSettings.current_map_node = null
	MatchSettings.run_deck = []
	MatchSettings.run_gold = 0
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0
	MatchSettings.run_artifacts = []


func _generate_debug_ai_picker_bar() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugOverlay"
	layer.layer = 100
	add_child(layer)

	var picker := MenuButton.new()
	picker.name = "DebugAIPicker"
	picker.text = "DBG · ИИ"
	picker.tooltip_text = "Запустить быстрый бой против выбранного профиля ИИ"
	picker.custom_minimum_size = Vector2(112.0, 44.0)
	picker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	picker.offset_left = -132.0
	picker.offset_top = 46.0
	picker.offset_right = -18.0
	picker.offset_bottom = 90.0
	_apply_button_style(picker, false, true)
	layer.add_child(picker)

	var popup := picker.get_popup()
	for index in range(DEBUG_STRATEGY_NAMES.size()):
		popup.add_item(DEBUG_STRATEGY_NAMES[index], index)
	popup.id_pressed.connect(_on_debug_strategy_selected)


func _on_debug_strategy_selected(strategy_index: int) -> void:
	if strategy_index < 0 or strategy_index >= DEBUG_STRATEGY_SCRIPTS.size():
		return
	_start_test_battle(DEBUG_STRATEGY_SCRIPTS[strategy_index].new())


func _on_settings_pressed():
	get_tree().change_scene_to_file("res://ui/settings/settings_screen.tscn")


func _on_profile_pressed():
	get_tree().change_scene_to_file("res://ui/profile/profile_screen.tscn")
