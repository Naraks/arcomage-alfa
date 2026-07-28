extends Control

const WorldMapData = preload("res://data/resources/world_map_data.gd")
const MapNodeData = preload("res://data/resources/map_node_data.gd")

@export var map_data: Resource

@onready var _map_content: Control = $ScrollContainer/MapContent


func _ready() -> void:
	print("WorldMapScreen _ready")
	if not map_data:
		map_data = MatchSettings.world_map_data

	if map_data:
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
			line.points = [node.position + Vector2(25, 25), connected.position + Vector2(25, 25)]
			line.width = 2
			line.default_color = Color.WHITE
			_map_content.add_child(line)

	# ARC-011: кликабельны только узлы, соединённые с current_node_index и ещё
	# не пройденные — остальные задизейблены и визуально приглушены.
	var available_nodes: Array = _compute_available_nodes()

	# Отрисовка узлов
	for node in map_data.map_nodes:
		var button = Button.new()
		button.text = MapNodeData.NodeType.keys()[node.node_type]
		button.position = node.position
		button.custom_minimum_size = Vector2(50, 50)

		var is_available: bool = available_nodes.has(node)
		button.disabled = not is_available
		_style_node_button(button, node, is_available)

		button.pressed.connect(_on_node_pressed.bind(node))
		_map_content.add_child(button)
		print("Added button at: ", node.position)


## Узлы позиционируются абсолютно (node.position, см. world_map_generator.gd),
## поэтому ScrollContainer должен знать реальный размер контента заранее —
## иначе он не покажет скроллбар и обрежет карту по размеру экрана.
func _fit_map_content_size() -> void:
	var max_x := 0.0
	var max_y := 0.0
	for node in map_data.map_nodes:
		max_x = max(max_x, node.position.x)
		max_y = max(max_y, node.position.y)
	_map_content.custom_minimum_size = Vector2(max_x + 150, max_y + 150)


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


## Доступные узлы — обычный вид. Пройденные — приглушённо-зелёные (для
## наглядности маршрута за спиной). Всё остальное недоступное — тусклое,
## с иконкой замка перед названием типа узла.
func _style_node_button(button: Button, node: Resource, is_available: bool) -> void:
	if is_available:
		button.modulate = Color.WHITE
	elif node.is_completed:
		button.modulate = Color(0.5, 0.8, 0.5, 1.0)
	else:
		button.modulate = Color(0.45, 0.45, 0.45, 1.0)
		button.text = "🔒 " + button.text


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
const DefaultAIStrategyScript = preload("res://data/resources/default_ai_strategy.gd")
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")
const BuilderAIStrategyScript = preload("res://data/resources/builder_ai_strategy.gd")
const EconomistAIStrategyScript = preload("res://data/resources/economist_ai_strategy.gd")
const BossAIStrategyScript = preload("res://data/resources/boss_ai_strategy.gd")

const REGULAR_STRATEGY_SCRIPTS: Array = [
	DefaultAIStrategyScript, AggressiveAIStrategyScript, BuilderAIStrategyScript, EconomistAIStrategyScript
]
const ELITE_STRATEGY_SCRIPTS: Array = [AggressiveAIStrategyScript, BuilderAIStrategyScript]


func _pick_random_strategy(scripts: Array) -> AIStrategy:
	return scripts[randi() % scripts.size()].new()


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
			enemy.ai_strategy = _pick_random_strategy(REGULAR_STRATEGY_SCRIPTS)
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
