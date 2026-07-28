extends Control
## ARC-037: экран мета-магазина — тратит постоянную Славу (ProfileManager.
## profile.fame) на уровни из ProfileManager.UPGRADE_CATALOG. Открывается из
## главного меню (ui/main_menu.gd/.tscn), не из забега — прокачка не
## привязана к конкретной кампании. Разметка строится кодом в _ready(), как
## и в ui/shop/shop_screen.gd (тот же паттерн этого проекта для экранов без
## сложной вёрстки).

## Порядок отображения строк — фиксированный, не порядок ключей в
## ProfileManager.UPGRADE_CATALOG (Dictionary в GDScript не гарантирует
## порядок вставки при итерации так же надёжно, как явный список; плюс так
## проще сознательно сгруппировать "Основание" (tower/wall) перед
## "Мастерство ресурсов" (quarry/magic/dungeon) и утилити (hand_size) —
## та же группировка, что в game_design_doc.md §9.2).
const UPGRADE_ORDER := ["tower", "wall", "quarry", "magic", "dungeon", "hand_size"]

var _fame_label: Label
var _upgrade_list: VBoxContainer


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

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "ПРОКАЧКА"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_fame_label = Label.new()
	_fame_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_fame_label)
	_update_fame_label()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_upgrade_list = VBoxContainer.new()
	_upgrade_list.add_theme_constant_override("separation", 8)
	_upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_upgrade_list)

	var back_button := Button.new()
	back_button.text = "Назад в меню"
	back_button.pressed.connect(_on_back_pressed)
	root_vbox.add_child(back_button)

	_refresh_upgrade_list()


func _update_fame_label() -> void:
	_fame_label.text = "Слава: %d" % ProfileManager.profile.get("fame", 0)


## ARC-037: строка с названием улучшения, текущим уровнем/максимумом и
## описанием эффекта на СЛЕДУЮЩИЙ уровень (не на текущий — игрок покупает то,
## что получит, а не то, что уже есть). При max_level показывает текущий
## суммарный эффект вместо "следующего", т.к. следующего не будет.
func _row_label_text(key: String) -> String:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG.get(key, {})
	if def.is_empty():
		return ""
	var level := ProfileManager.get_upgrade_level(key)
	var max_level: int = def["max_level"]
	var per_level: int = def["per_level"]
	var shown_value: int = per_level if level < max_level else per_level * level
	return "%s — %s (ур. %d/%d)" % [def["name"], def["desc"] % shown_value, level, max_level]


## Текст кнопки покупки: цена следующего уровня или "МАКС." на пределе.
func _buy_button_text(key: String) -> String:
	var cost := ProfileManager.get_upgrade_next_cost(key)
	if cost < 0:
		return "МАКС."
	return "Купить за %d" % cost


func _refresh_upgrade_list() -> void:
	for child in _upgrade_list.get_children():
		child.queue_free()

	for key in UPGRADE_ORDER:
		_upgrade_list.add_child(_make_upgrade_row(key))


func _make_upgrade_row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = _row_label_text(key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = _buy_button_text(key)
	var next_cost := ProfileManager.get_upgrade_next_cost(key)
	buy_button.disabled = next_cost < 0 or not ProfileManager.can_afford_upgrade(key)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	row.add_child(buy_button)

	return row


func _on_buy_pressed(key: String) -> void:
	if not ProfileManager.purchase_upgrade(key):
		return
	_update_fame_label()
	_refresh_upgrade_list()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
