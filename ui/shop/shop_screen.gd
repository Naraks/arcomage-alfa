extends Control
## ARC-012: узел «Магазин» — docs/game_design_doc.md 7.1/10.5. Один экран, два
## раздела на нём (без вкладок, как в мокапе docs/ui_wireframes.html#shop-screen):
## "Купить карты" (3-5 предложений за визит) и "Удалить карту из колоды" (вся
## текущая MatchSettings.run_deck, клик = плата за удаление).
##
## Вся разметка строится кодом в _ready(), как и в world_map_screen.gd (узлы
## карты) и battle_screen.gd (попапы) — так в этом проекте уже принято для
## экранов, где UI проще держать в скрипте, чем вручную собирать в .tscn.

## Цена покупки = cost карты * множитель. У CardData пока нет системы
## редкости (docs/game_design_doc.md 5.3 описывает её, но поле в ресурсе не
## заведено) — это самое простое правило, которое даёт разброс цен, близкий к
## примерам из мокапа (4-9 золота за карту).
const CARD_PRICE_MULTIPLIER := 2

## Фиксированная плата за удаление карты из колоды — конкретное число нигде,
## кроме мокапа, не задано ("−5💰 за карту"), взято оттуда.
const REMOVE_CARD_PRICE := 5

const SHOP_OFFER_MIN := 3
const SHOP_OFFER_MAX := 5

var _shop_offer: Array[CardData] = []
var _gold_label: Label
var _buy_list: VBoxContainer
var _remove_list: VBoxContainer


func _ready() -> void:
	var offer_size := randi_range(SHOP_OFFER_MIN, SHOP_OFFER_MAX)
	_shop_offer = MatchManager.build_shop_offer(offer_size)
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

	# Шапка: "МАГАЗИН" + золото (design doc 10.5: "Золото всегда видно в шапке").
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "МАГАЗИН"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_gold_label)
	_update_gold_label()

	# Два раздела рядом: купить / удалить.
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	var buy_col := VBoxContainer.new()
	buy_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(buy_col)

	var buy_title := Label.new()
	buy_title.text = "КУПИТЬ КАРТЫ"
	buy_col.add_child(buy_title)

	var buy_scroll := ScrollContainer.new()
	buy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buy_col.add_child(buy_scroll)

	_buy_list = VBoxContainer.new()
	_buy_list.add_theme_constant_override("separation", 8)
	_buy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_scroll.add_child(_buy_list)

	var remove_col := VBoxContainer.new()
	remove_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(remove_col)

	var remove_title := Label.new()
	remove_title.text = "УДАЛИТЬ КАРТУ ИЗ КОЛОДЫ (−%d💰 за карту)" % REMOVE_CARD_PRICE
	remove_col.add_child(remove_title)

	var remove_scroll := ScrollContainer.new()
	remove_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	remove_col.add_child(remove_scroll)

	_remove_list = VBoxContainer.new()
	_remove_list.add_theme_constant_override("separation", 8)
	_remove_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_scroll.add_child(_remove_list)

	# Футер: возврат на карту (design doc 10.5: "Уйти на карту").
	var back_button := Button.new()
	back_button.text = "Уйти на карту →"
	back_button.pressed.connect(_on_back_pressed)
	root_vbox.add_child(back_button)

	_refresh_buy_list()
	_refresh_remove_list()


func _update_gold_label() -> void:
	_gold_label.text = "Золото: %d" % MatchSettings.run_gold


func _card_price(card: CardData) -> int:
	return max(1, card.cost * CARD_PRICE_MULTIPLIER)


func _refresh_buy_list() -> void:
	for child in _buy_list.get_children():
		child.queue_free()

	for card in _shop_offer:
		var price := _card_price(card)
		var row := _make_card_row(card, price, "Купить")
		var buy_button: Button = row.get_node("ActionButton")
		buy_button.disabled = MatchSettings.run_gold < price
		buy_button.pressed.connect(_on_buy_pressed.bind(card))
		_buy_list.add_child(row)

	if _shop_offer.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Больше нечего предложить"
		_buy_list.add_child(empty_label)


func _refresh_remove_list() -> void:
	for child in _remove_list.get_children():
		child.queue_free()

	# ARC-012: сортируем только ОТОБРАЖЕНИЕ (через пары card/index), а кнопку
	# привязываем к исходному индексу в MatchSettings.run_deck, а не к самой
	# карте — run_deck может содержать несколько ссылок на один и тот же
	# ресурс CardData (MatchManager._build_generic_card_pool добивает колоду
	# случайными повторами уже загруженных инстансов), и remove_at(index)
	# однозначен, а erase(card) по значению удалил бы не ту карту, что нажал
	# игрок.
	var indexed: Array = []
	for i in range(MatchSettings.run_deck.size()):
		indexed.append({"card": MatchSettings.run_deck[i], "index": i})
	indexed.sort_custom(func(a, b): return _compare_cards(a["card"], b["card"]))

	for entry in indexed:
		var card: CardData = entry["card"]
		var row := _make_card_row(card, REMOVE_CARD_PRICE, "Удалить")
		var remove_button: Button = row.get_node("ActionButton")
		remove_button.disabled = MatchSettings.run_gold < REMOVE_CARD_PRICE
		remove_button.pressed.connect(_on_remove_pressed.bind(entry["index"]))
		_remove_list.add_child(row)

	if MatchSettings.run_deck.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Колода пуста"
		_remove_list.add_child(empty_label)


## Тот же порядок сортировки, что и в battle_screen._compare_cards_for_view
## (ARC-016): по типу ресурса, затем по стоимости, затем по имени — здесь
## отдельная копия, а не переиспользование чужого метода, чтобы shop_screen не
## зависел от battle_screen.
func _compare_cards(a: CardData, b: CardData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.card_name < b.card_name


func _make_card_row(card: CardData, price: int, action_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = "%s (cost %d)" % [card.card_name, card.cost]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "%d💰" % price
	row.add_child(price_label)

	var action_button := Button.new()
	action_button.name = "ActionButton"
	action_button.text = action_text
	row.add_child(action_button)

	return row


func _on_buy_pressed(card: CardData) -> void:
	var price := _card_price(card)
	if MatchSettings.run_gold < price:
		return
	MatchSettings.run_gold -= price
	MatchSettings.run_deck.append(card)
	_shop_offer.erase(card)
	_update_gold_label()
	_refresh_buy_list()
	_refresh_remove_list()


func _on_remove_pressed(deck_index: int) -> void:
	if MatchSettings.run_gold < REMOVE_CARD_PRICE:
		return
	if deck_index < 0 or deck_index >= MatchSettings.run_deck.size():
		return
	MatchSettings.run_gold -= REMOVE_CARD_PRICE
	MatchSettings.run_deck.remove_at(deck_index)
	_update_gold_label()
	_refresh_remove_list()
	_refresh_buy_list()


func _on_back_pressed() -> void:
	# ARC-012: как и battle_screen._on_match_ended() при победе с карты —
	# помечаем узел пройденным и обновляем current_node_index, иначе
	# world_map_screen._compute_available_nodes() не откроет соседние узлы.
	# У магазина нет "поражения" — любой выход считается завершением узла.
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
