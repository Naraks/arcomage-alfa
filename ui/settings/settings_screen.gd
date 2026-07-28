extends Control
## ARC-042: экран настроек — пока единственная настройка, громкость
## (ProfileManager.get_volume()/set_volume(), применяется к шине AudioServer
## "Master" и сохраняется в profile.settings через тот же save_profile(),
## что и остальной профиль). Открывается из главного меню (кнопка
## «Настройки»). Разметка строится кодом в _ready(), тот же паттерн, что в
## ui/shop/shop_screen.gd.
##
## Выбор языка — акцептанс-критерий ARC-042 явно помечает его как
## "опционально", и намеренно НЕ реализован: в проекте вообще нет
## инфраструктуры локализации (ни одного .csv/.po файла с переводами, весь
## текст во всех экранах — захардкоженные русские строки прямо в коде, см.
## любой из ui/*/*_screen.gd). Завести реальный выбор языка означало бы
## сначала построить с нуля систему переводов и прогнать через неё каждую
## строку в каждом экране — несоразмерно 3 SP этого тикета и вообще
## отдельная большая задача, не часть ARC-042.

var _volume_slider: HSlider
var _volume_value_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
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
	title.text = "НАСТРОЙКИ"
	title.add_theme_font_size_override("font_size", 28)
	root_vbox.add_child(title)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(volume_row)

	var volume_label := Label.new()
	volume_label.text = "Громкость"
	volume_row.add_child(volume_label)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.value = ProfileManager.get_volume()
	_volume_slider.custom_minimum_size = Vector2(200, 0)
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(_volume_slider)

	_volume_value_label = Label.new()
	_volume_value_label.custom_minimum_size = Vector2(48, 0)
	_volume_value_label.text = _volume_percent_text(_volume_slider.value)
	volume_row.add_child(_volume_value_label)

	var back_button := Button.new()
	back_button.text = "Назад в меню"
	back_button.pressed.connect(_on_back_pressed)
	root_vbox.add_child(back_button)


## "80%" из линейного 0.0..1.0 — round(), не int()/floor(), иначе 0.95 (95%)
## отображался бы как "94%" из-за погрешности float.
func _volume_percent_text(value: float) -> String:
	return "%d%%" % round(value * 100)


func _on_volume_changed(value: float) -> void:
	ProfileManager.set_volume(value)
	_volume_value_label.text = _volume_percent_text(value)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
