extends Control

## UI 02/13 (#97): состояние узла — отдельная семантика, а не оттенок.
## Browser fix: пиктограммы узлов — PNG-текстуры, а не Unicode-глифы,
## наличие которых зависит от системных шрифтов браузера.
## Текущий узел остаётся последним посещённым; доступными являются его выходы.
enum NodeState { CURRENT, AVAILABLE, COMPLETED, LOCKED }

const WorldMapData = preload("res://data/resources/world_map_data.gd")
const MapNodeData = preload("res://data/resources/map_node_data.gd")

const NODE_PRESENTATION := {
	MapNodeData.NodeType.BATTLE:
	{
		"icon": preload("res://art/map/nodes/battle.png"),
		"title": "Бой",
		"preview": "Обычный бой. Награда — после победы."
	},
	MapNodeData.NodeType.ELITE_BATTLE:
	{
		"icon": preload("res://art/map/nodes/elite.png"),
		"title": "Элита",
		"preview": "Опасный усиленный противник и ценная награда."
	},
	MapNodeData.NodeType.SHOP:
	{
		"icon": preload("res://art/map/nodes/shop.png"),
		"title": "Магазин",
		"preview": "Покупка и удаление карт за золото."
	},
	MapNodeData.NodeType.REST:
	{
		"icon": preload("res://art/map/nodes/rest.png"),
		"title": "Отдых",
		"preview": "Безопасная остановка и постоянное усиление забега."
	},
	MapNodeData.NodeType.EVENT:
	{
		"icon": preload("res://art/map/nodes/event.png"),
		"title": "Событие",
		"preview": "Неизвестная встреча. Результат скрыт до входа."
	},
	MapNodeData.NodeType.BOSS:
	{
		"icon": preload("res://art/map/nodes/boss.png"),
		"title": "Босс",
		"preview": "Финальное испытание этого маршрута."
	},
}
const NODE_SIZE := Vector2(132, 62)
const MAP_SIDE_PADDING := 32.0

## ARC-017: "выше стартовые HP/генераторы, чуть агрессивнее" (design doc,
## раздел 6) для элиты/босса — конкретные числа нигде не заданы, взяты как
## разумная прогрессия (босс вдвое злее элиты).
const ELITE_TOWER_BONUS := 10
const ELITE_WALL_BONUS := 5
const ELITE_GENERATOR_BONUS := 1
const BOSS_TOWER_BONUS := 20
const BOSS_WALL_BONUS := 10
const BOSS_GENERATOR_BONUS := 2

## ARC-027: тип узла определяет не только бонусы к статам (ARC-017), но и то,
## какой ai_strategy достаётся противнику.
## - BATTLE: без бонусов к статам, случайный профиль из всех четырёх — обычный
##   бой не должен ощущаться усиленным, но должен давать разнообразие
##   ("случайный/сбалансированный профиль" из описания тикета). До этого
##   тикета BATTLE вообще не выставлял ai_strategy — MatchManager._resolve_ai_turn
##   молча подставлял DefaultAIStrategy с [ERROR]-принтом в консоль на каждый
##   ход ИИ; теперь это явное и разнообразное назначение, принт больше не
##   появляется.
## - ELITE_BATTLE: бонусы к статам как раньше, но профиль теперь случайно
##   Aggressive ИЛИ Builder — буквально "усиленная версия (Aggressive/Builder)"
##   из описания тикета, а не всегда фиксированный Aggressive, как было
##   временным приближением в ARC-017.
## - BOSS: свои (более высокие) бонусы, всегда BossAIStrategy — "отдельная
##   скриптованная гибридная стратегия" (data/resources/boss_ai_strategy.gd:
##   переключается между Aggressive/Builder по угрозе поражения/окну для
##   добивания — именно то, что в ARC-017 было отложено как "отдельная, более
##   крупная задача про ИИ").
##
## Массивы держат сами GDScript-объекты через preload() (гарантированно
## константное выражение), а не bare class_name-идентификаторы вроде
## DefaultAIStrategy — компилятор не считает их константным выражением внутри
## const-массива (`Assigned value for constant "..." isn't a constant
## expression`), несмотря на то, что вне const-контекста (`enemy.ai_strategy =
## AggressiveAIStrategy.new()`, как было до ARC-027) обращение к ним работает
## нормально.
## ARC-085: REGULAR_STRATEGY_SCRIPTS переехал в MatchManager.REGULAR_STRATEGY_SCRIPTS —
## переиспользуется ещё и в main_menu.gd (Быстрый бой). ELITE_STRATEGY_SCRIPTS
## остаётся здесь — используется только этим экраном.
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")
const BuilderAIStrategyScript = preload("res://data/resources/builder_ai_strategy.gd")
const BossAIStrategyScript = preload("res://data/resources/boss_ai_strategy.gd")

const ELITE_STRATEGY_SCRIPTS: Array = [AggressiveAIStrategyScript, BuilderAIStrategyScript]

## ARC-029: рост сложности от глубины карты (MapNodeData.floor_index,
## 0-based) — НЕЗАВИСИМО от типа узла, поверх бонусов ELITE/BOSS (ARC-017):
## дальний обычный BATTLE должен быть ощутимо опаснее самого первого, а не
## только элита/босс, у которых до этого тикета сложность вообще не зависела
## от того, на каком этаже они встретились. floor_index=0 (первый этаж, а
## также любой узел, созданный не через генератор — тестовые/отладочные)
## даёт нулевой бонус — старое поведение ELITE/BOSS-тестов не меняется.
##
## tower_hp/wall_hp растут линейно на каждый этаж; генераторы — раз в
## FLOOR_GENERATOR_INTERVAL этажей, а не на каждый: базовый генератор = 1,
## линейный рост на каждый из 12-15 этажей карты (WorldMapGenerator) был бы
## взрывным (генератор x12+ к последнему этажу).
const FLOOR_TOWER_HP_PER_FLOOR := 2
const FLOOR_WALL_HP_PER_FLOOR := 1
const FLOOR_GENERATOR_INTERVAL := 3

@export var map_data: Resource

var _map_offset_x := 0.0

@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _map_content: Control = $ScrollContainer/MapContent
@onready var _hud_label: Label = $Header/Hud
@onready var _preview_label: Label = $Preview


func _ready() -> void:
	print("WorldMapScreen _ready")
	if not map_data:
		map_data = MatchSettings.world_map_data

	if map_data:
		_update_hud()
		_generate_map_ui()
		# ARC-018: единая точка автосохранения — сюда возвращаются после любого
		# узла (shop/rest/event/reward уже успели проставить is_completed/
		# current_node_index до перехода), и сюда же попадают сразу после
		# генерации нового забега.
		RunSaveManager.save_run()

	if OS.is_debug_build():
		_generate_debug_node_bar()


## Карта может быть выше/шире экрана (12-15 этажей) — раньше узлы и
## линии добавлялись прямо в корневой Control без прокрутки, из-за чего нижние
## этажи были не видны и недоступны для клика. Теперь всё содержимое карты
## живёт в $ScrollContainer/MapContent, а не в самом экране.
func _generate_map_ui() -> void:
	print("Generating map UI, nodes count: ", map_data.map_nodes.size())
	_fit_map_content_size()

	# Отрисовка путей
	for node in map_data.map_nodes:
		for connected in node.connected_nodes:
			var line = Line2D.new()
			line.points = [
				_map_position(node) + NODE_SIZE / 2.0,
				_map_position(connected) + NODE_SIZE / 2.0,
			]
			line.width = 4
			line.default_color = Color(0.55, 0.45, 0.28, 0.8)
			_map_content.add_child(line)

	# ARC-011: кликабельны только узлы, соединённые с current_node_index и ещё
	# не пройденные — остальные задизейблены и визуально приглушены.
	var available_nodes: Array = _compute_available_nodes()

	# Отрисовка узлов
	for node in map_data.map_nodes:
		var button = Button.new()
		var state := _node_state(node, available_nodes)
		button.text = _node_label(node, state)
		button.tooltip_text = _node_preview(node, state)
		button.position = _map_position(node)
		button.custom_minimum_size = NODE_SIZE
		_add_node_icon(button, node, state)

		# LOCKED остаётся кликабельным только для понятной обратной связи;
		# _can_enter_node — единый guard, поэтому переход невозможен.
		button.disabled = state == NodeState.COMPLETED or state == NodeState.CURRENT
		_style_node_button(button, state)

		button.pressed.connect(_on_node_pressed.bind(node))
		button.mouse_entered.connect(_show_node_preview.bind(node, state))
		button.focus_entered.connect(_show_node_preview.bind(node, state))
		_map_content.add_child(button)
		print("Added button at: ", node.position)


## Узлы позиционируются абсолютно (node.position, см. world_map_generator.gd),
## поэтому ScrollContainer должен знать реальный размер контента заранее —
## иначе он не покажет скроллбар и обрежет карту по размеру экрана.
func _fit_map_content_size() -> void:
	var max_y := 0.0
	for node in map_data.map_nodes:
		max_y = max(max_y, node.position.y)
	var horizontal_layout := _calculate_horizontal_layout(_scroll_container.size.x)
	_map_offset_x = horizontal_layout.x
	_map_content.custom_minimum_size = Vector2(horizontal_layout.y, max_y + 170)


## Генератор хранит координаты в своей фиксированной сетке. На широком
## экране эта сетка раньше оставалась у левого края ScrollContainer. Здесь
## вычисляется единый сдвиг для всех узлов и линий: маршрут центрируется,
## если помещается, либо получает безопасные поля и горизонтальный скролл.
## Vector2.x = offset, Vector2.y = итоговая ширина MapContent.
func _calculate_horizontal_layout(viewport_width: float) -> Vector2:
	if map_data == null or map_data.map_nodes.is_empty():
		return Vector2(MAP_SIDE_PADDING, maxf(viewport_width, NODE_SIZE.x + MAP_SIDE_PADDING * 2.0))
	var min_x := INF
	var max_x := -INF
	for node in map_data.map_nodes:
		min_x = minf(min_x, node.position.x)
		max_x = maxf(max_x, node.position.x)
	var route_width := max_x - min_x + NODE_SIZE.x
	var content_width := maxf(viewport_width, route_width + MAP_SIDE_PADDING * 2.0)
	var offset := (content_width - route_width) / 2.0 - min_x
	return Vector2(offset, content_width)


func _map_position(node: Resource) -> Vector2:
	return node.position + Vector2(_map_offset_x, 0)


func _update_hud() -> void:
	var floor_number := 1
	if map_data.current_node_index >= 0 and map_data.current_node_index < map_data.map_nodes.size():
		floor_number = map_data.map_nodes[map_data.current_node_index].floor_index + 1
	_hud_label.text = (
		"Этаж %d/%d  •  Золото %d\nБашня +%d  •  Колода %d  •  Артефакты %d"
		% [
			floor_number,
			maxi(1, map_data.floor_count),
			MatchSettings.run_gold,
			MatchSettings.run_tower_bonus,
			MatchSettings.run_deck.size(),
			MatchSettings.run_artifacts.size(),
		]
	)


func _node_state(node: Resource, available_nodes: Array = []) -> int:
	var index: int = map_data.map_nodes.find(node)
	if index == map_data.current_node_index and index >= 0:
		return NodeState.CURRENT
	if available_nodes.has(node):
		return NodeState.AVAILABLE
	if node.is_completed:
		return NodeState.COMPLETED
	return NodeState.LOCKED


func _node_label(node: Resource, state: int) -> String:
	var presentation: Dictionary = NODE_PRESENTATION.get(node.node_type, {"title": "Узел"})
	var state_label: String = {
		NodeState.CURRENT: "ВЫ ЗДЕСЬ",
		NodeState.AVAILABLE: "ДОСТУПНО",
		NodeState.COMPLETED: "ПРОЙДЕНО",
		NodeState.LOCKED: "ЗАКРЫТО"
	}[state]
	return "%s\n%s" % [presentation.title, state_label]


func _node_icon(node: Resource) -> Texture2D:
	var presentation: Dictionary = NODE_PRESENTATION.get(node.node_type, {})
	return presentation.get("icon")


func _add_node_icon(button: Button, node: Resource, state: int) -> void:
	var icon := TextureRect.new()
	icon.name = "NodeIcon"
	icon.texture = _node_icon(node)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if state == NodeState.LOCKED:
		icon.modulate = Color(0.55, 0.53, 0.5)
	button.add_child(icon)
	# TextureRect пересчитывает minimum size при входе в дерево; поэтому
	# фиксируем прямоугольник после add_child, иначе 128px-исходник перекрывает подпись.
	icon.position = Vector2(8, 17)
	icon.size = Vector2(28, 28)


func _node_preview(node: Resource, state: int) -> String:
	if state == NodeState.LOCKED:
		return "Путь закрыт: сначала завершите связанный доступный узел."
	var presentation: Dictionary = NODE_PRESENTATION.get(
		node.node_type, {"preview": "Неизвестный узел."}
	)
	return "Этаж %d. %s" % [node.floor_index + 1, presentation.preview]


func _show_node_preview(node: Resource, state: int) -> void:
	_preview_label.text = _node_preview(node, state)


func _can_enter_node(node: Resource) -> bool:
	return _compute_available_nodes().has(node)


## Доступные для клика узлы — соединённые с текущей позицией на карте
## (map_data.current_node_index) и ещё не пройденные. current_node_index == -1
## — сентинел WorldMapGenerator "забег только начался": тогда доступны узлы
## первого этажа, у которых нет ни одной входящей связи ни от одного узла карты.
func _compute_available_nodes() -> Array:
	if map_data.current_node_index == -1:
		var roots: Array = []
		for node in map_data.map_nodes:
			if not _has_incoming_edge(node):
				roots.append(node)
		return roots

	var index: int = map_data.current_node_index
	if index < 0 or index >= map_data.map_nodes.size():
		return []

	var current_node = map_data.map_nodes[index]
	var reachable: Array = []
	for node in current_node.connected_nodes:
		if not node.is_completed:
			reachable.append(node)
	return reachable


func _has_incoming_edge(target_node: Resource) -> bool:
	for node in map_data.map_nodes:
		if node.connected_nodes.has(target_node):
			return true
	return false


## Состояния различаются одновременно подписью, формой и контрастом рамки:
## круглее всего текущий узел, доступный выделен толстой рамкой, пройденный
## почти прямоугольный, заблокированный — прямоугольный и приглушённый.
func _style_node_button(button: Button, state: int) -> void:
	var palette: Array = {
		NodeState.CURRENT: [Color("5b3c20"), Color("f6d58a"), 18],
		NodeState.AVAILABLE: [Color("2f5b45"), Color("d8f4db"), 12],
		NodeState.COMPLETED: [Color("273d32"), Color("9eb9a3"), 4],
		NodeState.LOCKED: [Color("292724"), Color("77716a"), 0],
	}[state]
	var box := StyleBoxFlat.new()
	box.bg_color = palette[0]
	box.border_color = palette[1]
	box.set_border_width_all(2 if state != NodeState.AVAILABLE else 3)
	box.set_corner_radius_all(palette[2])
	box.content_margin_left = 10
	box.content_margin_right = 10
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("disabled", box)
	button.add_theme_color_override("font_color", palette[1])
	button.add_theme_color_override("font_disabled_color", palette[1])
	button.add_theme_font_size_override("font_size", 14)


## Панель отладки: по одной всегда доступной кнопке на каждый NodeType, не
## привязанной к основному пути (узлы синтетические, не входят в
## map_data.map_nodes — клик по ним не может испортить прохождение забега,
## см. guard'ы на .find() в battle_screen/shop_screen/rest_screen). Только в
## debug-сборках — не попадёт в релизный экспорт для Яндекс Игр.
func _generate_debug_node_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -44
	row.offset_bottom = 0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	layer.add_child(row)

	var type_names: Array = MapNodeData.NodeType.keys()
	for node_type in range(type_names.size()):
		var debug_node := MapNodeData.new()
		debug_node.node_type = node_type

		var button := Button.new()
		button.text = "DBG: %s" % type_names[node_type]
		button.modulate = Color(1.0, 0.85, 0.3)
		button.pressed.connect(_on_node_pressed.bind(debug_node))
		row.add_child(button)


func _pick_random_strategy(scripts: Array) -> AIStrategy:
	return scripts[randi() % scripts.size()].new()


func _apply_floor_difficulty(enemy: PlayerData, floor_index: int) -> void:
	enemy.tower_hp += floor_index * FLOOR_TOWER_HP_PER_FLOOR
	enemy.wall_hp += floor_index * FLOOR_WALL_HP_PER_FLOOR
	var generator_bonus: int = floor_index / FLOOR_GENERATOR_INTERVAL
	enemy.quarry += generator_bonus
	enemy.magic += generator_bonus
	enemy.dungeon += generator_bonus


func _apply_node_difficulty(enemy: PlayerData, node_type: int, floor_index: int = 0) -> void:
	_apply_floor_difficulty(enemy, floor_index)

	match node_type:
		MapNodeData.NodeType.BATTLE:
			enemy.ai_strategy = _pick_random_strategy(MatchManager.REGULAR_STRATEGY_SCRIPTS)
		MapNodeData.NodeType.ELITE_BATTLE:
			enemy.tower_hp += ELITE_TOWER_BONUS
			enemy.wall_hp += ELITE_WALL_BONUS
			enemy.quarry += ELITE_GENERATOR_BONUS
			enemy.magic += ELITE_GENERATOR_BONUS
			enemy.dungeon += ELITE_GENERATOR_BONUS
			enemy.ai_strategy = _pick_random_strategy(ELITE_STRATEGY_SCRIPTS)
		MapNodeData.NodeType.BOSS:
			enemy.tower_hp += BOSS_TOWER_BONUS
			enemy.wall_hp += BOSS_WALL_BONUS
			enemy.quarry += BOSS_GENERATOR_BONUS
			enemy.magic += BOSS_GENERATOR_BONUS
			enemy.dungeon += BOSS_GENERATOR_BONUS
			enemy.ai_strategy = BossAIStrategyScript.new()


func _on_node_pressed(node: Resource) -> void:
	print("Node pressed: ", node.node_type)
	if map_data.map_nodes.has(node) and not _can_enter_node(node):
		_preview_label.text = "Этот путь пока закрыт. Выберите узел с пометкой «ДОСТУПНО»."
		return

	# ARC-015: ELITE_BATTLE/BOSS запускают тот же battle_screen, что и обычный
	# BATTLE — отличается пул наград после победы (reward_screen.gd читает
	# node_type из current_map_node) и, с ARC-017, характеристики противника
	# (_apply_node_difficulty).
	if (
		node.node_type == MapNodeData.NodeType.BATTLE
		or node.node_type == MapNodeData.NodeType.ELITE_BATTLE
		or node.node_type == MapNodeData.NodeType.BOSS
	):
		# Заглушка для PlayerData
		var p_data = PlayerData.new()
		var e_data = PlayerData.new()
		_apply_node_difficulty(e_data, node.node_type, node.floor_index)
		MatchSettings.player_data = p_data
		MatchSettings.enemy_data = e_data

		# ARC-002: помечаем, что бой начат с карты — battle_screen прочитает это
		# в _on_match_ended(), чтобы при победе увести на экран награды (ARC-015),
		# а при поражении вернуть сюда без отметки узла пройденным.
		MatchSettings.came_from_map = true
		MatchSettings.current_map_node = node

		get_tree().change_scene_to_file("res://ui/battle/battle_screen.tscn")
	elif node.node_type == MapNodeData.NodeType.SHOP:
		# ARC-012: небоевой узел — завершение (is_completed) делает сам
		# shop_screen.gd по кнопке "Уйти на карту".
		MatchSettings.current_map_node = node
		get_tree().change_scene_to_file("res://ui/shop/shop_screen.tscn")
	elif node.node_type == MapNodeData.NodeType.REST:
		# ARC-013: тот же переход, что и у Магазина.
		MatchSettings.current_map_node = node
		get_tree().change_scene_to_file("res://ui/rest/rest_screen.tscn")
	elif node.node_type == MapNodeData.NodeType.EVENT:
		# ARC-014: тот же переход, что и у Магазина/Отдыха.
		MatchSettings.current_map_node = node
		get_tree().change_scene_to_file("res://ui/event/event_screen.tscn")
	else:
		print("Other node types not yet implemented: ", node.node_type)
