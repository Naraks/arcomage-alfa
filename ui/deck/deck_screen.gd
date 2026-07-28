extends Control
## ARC-041: экран «Колода» — просмотр (не редактирование, MVP) состава
## колоды. Открывается из главного меню (ui/main_menu.gd, кнопка «Колода» —
## раньше заглушка с print()). Разметка строится кодом в _ready(), тот же
## паттерн, что в ui/shop/shop_screen.gd.
##
## Сознательно НЕ полный «Единый экран профиля/колоды» из ARC-046 (вкладки
## Прокачка/Статистика/Коллекция, см. docs/ui_wireframes.html#profile-screen) —
## ARC-046 зависит от ARC-038 (система разблокировки карт), которой ещё нет:
## показывать вкладку «Коллекция» нечем содержательно наполнить без понятия
## "карта разблокирована". Этот экран закрывает буквальный акцептанс-критерий
## именно ARC-041 ("«Колода» открывает реальный экран") самостоятельно, не
## дожидаясь ARC-038/046 — см. блокквот ARC-041 в dev_plan_tickets.md.
##
## Что показывает: колоду ТЕКУЩЕГО забега, если есть сохранённый
## (RunSaveManager.has_saved_run()) — то же самое, что игрок увидит, нажав
## «Продолжить»; иначе — превью стартовой колоды новой кампании
## (MatchManager.build_starting_run_deck()). Это превью НЕ детерминировано
## (build_starting_run_deck() каждый раз мешает случайные повторы — см. её
## комментарий) — тот же список карт, что реально получит игрок при старте
## кампании, просто не побайтово тот же порядок/дубликаты.

var _deck_list: VBoxContainer
var _source_label: Label


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
	title.text = "КОЛОДА"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_source_label = Label.new()
	header.add_child(_source_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_deck_list = VBoxContainer.new()
	_deck_list.add_theme_constant_override("separation", 6)
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_deck_list)

	var back_button := Button.new()
	back_button.text = "Назад в меню"
	back_button.pressed.connect(_on_back_pressed)
	root_vbox.add_child(back_button)

	_refresh(_load_deck_to_show())


## Решает, чью колоду показывать, и подписывает _source_label. Отдельно от
## _refresh() — какая колода показывается, не то же самое, что как она
## отрисовывается (группировка/сортировка тестируется без реального сейва).
func _load_deck_to_show() -> Array[CardData]:
	if RunSaveManager.has_saved_run():
		RunSaveManager.load_run()
		_source_label.text = "Колода текущего забега"
		return MatchSettings.run_deck
	_source_label.text = "Нет активного забега — превью стартовой колоды новой кампании"
	return MatchManager.build_starting_run_deck()


func _refresh(cards: Array[CardData]) -> void:
	for child in _deck_list.get_children():
		child.queue_free()

	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Колода пуста"
		_deck_list.add_child(empty_label)
		return

	for entry in _group_cards(cards):
		var card: CardData = entry["card"]
		var count: int = entry["count"]
		var row := Label.new()
		row.text = "%s ×%d (cost %d)" % [card.card_name, count, card.cost]
		_deck_list.add_child(row)


## Группирует одинаковые CardData по identity (колода часто содержит
## несколько ссылок на один и тот же ресурс .tres — та же ситуация, что
## shop_screen._refresh_remove_list() решает по индексу, но там нужен именно
## индекс для точечного удаления; здесь нужен только счётчик, поэтому проще
## через Dictionary с CardData-ключом) и сортирует: тип ресурса → cost → имя.
func _group_cards(cards: Array[CardData]) -> Array:
	var counts: Dictionary = {}
	var order: Array[CardData] = []
	for card in cards:
		if not counts.has(card):
			counts[card] = 0
			order.append(card)
		counts[card] += 1

	order.sort_custom(_compare_cards)

	var result: Array = []
	for card in order:
		result.append({"card": card, "count": counts[card]})
	return result


## Та же сортировка (тип → cost → имя), что в ui/shop/shop_screen.gd —
## независимая копия, не общая функция: тот же паттерн уже используют
## shop_screen.gd и battle_screen.gd (обе хранят свою копию _compare_cards),
## не общий модуль.
func _compare_cards(a: CardData, b: CardData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.card_name < b.card_name


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
