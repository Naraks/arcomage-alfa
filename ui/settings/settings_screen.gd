extends Control
## Настройки игры.

const MIN_TOUCH_TARGET := 44.0
const PANEL_MAX_WIDTH := 1040.0

var _volume_slider: HSlider
var _volume_value_label: Label
var _reset_confirmation: PanelContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	if _volume_slider:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.045, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		outer_margin.add_theme_constant_override("margin_%s" % side, 16)
	add_child(outer_margin)
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_margin.add_child(scroll)
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var panel_center := CenterContainer.new()
	panel_center.name = "PanelCenter"
	panel_center.custom_minimum_size.x = maxf(280.0, viewport_size.x - 32.0)
	panel_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel_center)

	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.custom_minimum_size.x = _panel_width_for_viewport(viewport_size)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 20)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UIColors.GOLD)
	content.add_child(title)
	content.add_child(_build_sound_section())
	content.add_child(_build_empty_section("ИГРА", "Игровых параметров пока нет."))
	content.add_child(
		_build_empty_section("ДОСТУПНОСТЬ", "Параметры доступности пока не добавлены.")
	)
	content.add_child(_build_reset_section())

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "Назад в меню"
	back_button.custom_minimum_size.y = MIN_TOUCH_TARGET
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.pressed.connect(_on_back_pressed)
	content.add_child(back_button)


func _build_sound_section() -> PanelContainer:
	var section := _make_section("ЗВУК")
	var box: VBoxContainer = section.get_meta("content")
	var label_row := HBoxContainer.new()
	label_row.add_theme_constant_override("separation", 12)
	box.add_child(label_row)
	var label := Label.new()
	label.text = "Общая громкость"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_row.add_child(label)
	_volume_value_label = Label.new()
	_volume_value_label.name = "VolumeValue"
	_volume_value_label.custom_minimum_size.x = 56
	_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_volume_value_label.text = _volume_percent_text(ProfileManager.get_volume())
	label_row.add_child(_volume_value_label)

	_volume_slider = HSlider.new()
	_volume_slider.name = "VolumeSlider"
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.value = ProfileManager.get_volume()
	_volume_slider.custom_minimum_size = Vector2(240, MIN_TOUCH_TARGET)
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.focus_mode = Control.FOCUS_ALL
	_volume_slider.tooltip_text = "Стрелки влево и вправо изменяют громкость на 5%"
	_volume_slider.value_changed.connect(_on_volume_changed)
	box.add_child(_volume_slider)
	return section


func _build_empty_section(title_text: String, message: String) -> PanelContainer:
	var section := _make_section(title_text)
	var box: VBoxContainer = section.get_meta("content")
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.68, 0.68, 0.72))
	box.add_child(label)
	return section


func _build_reset_section() -> PanelContainer:
	var section := _make_section("СБРОС")
	var box: VBoxContainer = section.get_meta("content")
	var explanation := Label.new()
	explanation.text = "Сбрасывает только настройки. Прогресс и статистика сохранятся."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)
	var reset_button := Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "Сбросить настройки"
	reset_button.custom_minimum_size.y = MIN_TOUCH_TARGET
	reset_button.focus_mode = Control.FOCUS_ALL
	reset_button.pressed.connect(_show_reset_confirmation)
	box.add_child(reset_button)

	_reset_confirmation = PanelContainer.new()
	_reset_confirmation.name = "ResetConfirmation"
	_reset_confirmation.visible = false
	box.add_child(_reset_confirmation)
	var confirm_box := VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 8)
	_reset_confirmation.add_child(confirm_box)
	var warning := Label.new()
	warning.text = _reset_summary_text()
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_color_override("font_color", Color(0.96, 0.64, 0.42))
	confirm_box.add_child(warning)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	confirm_box.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Отмена"
	cancel.custom_minimum_size.y = MIN_TOUCH_TARGET
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_hide_reset_confirmation)
	actions.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "Подтвердить сброс"
	confirm.custom_minimum_size.y = MIN_TOUCH_TARGET
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(_confirm_reset)
	actions.add_child(confirm)
	return section


func _make_section(title_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.82, 0.72, 0.48))
	box.add_child(title)
	panel.set_meta("content", box)
	return panel


func _volume_percent_text(value: float) -> String:
	return "%d%%" % round(value * 100)


func _panel_width_for_viewport(viewport_size: Vector2) -> float:
	return minf(PANEL_MAX_WIDTH, maxf(280.0, viewport_size.x - 32.0))


func _reset_summary_text() -> String:
	return "Будет сброшено: общая громкость → 100%. Продолжить?"


func _on_volume_changed(value: float) -> void:
	ProfileManager.set_volume(value)
	if _volume_value_label:
		_volume_value_label.text = _volume_percent_text(value)


func _show_reset_confirmation() -> void:
	_reset_confirmation.visible = true


func _hide_reset_confirmation() -> void:
	_reset_confirmation.visible = false


func _confirm_reset() -> void:
	ProfileManager.reset_settings()
	_volume_slider.set_value_no_signal(ProfileManager.get_volume())
	_volume_value_label.text = _volume_percent_text(ProfileManager.get_volume())
	_hide_reset_confirmation()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
