extends Node

## MatchManager: Основной контроллер матча Arcomage

enum State { START_MATCH, PLAYER_TURN, PROCESS_CARD, AI_TURN, CHECK_WIN, END_MATCH }

const WIN_TOWER_HEIGHT = 100
const WIN_RESOURCE_AMOUNT = 300

var current_state: State = State.START_MATCH
var player_data: PlayerData
var enemy_data: PlayerData
var last_actor: PlayerData

var player_hand: Array[CardData] = []
var enemy_hand: Array[CardData] = []
## Колода игрока — стартовая из run_deck (ARC-016) в реальном забеге, либо
## тестовый пул (см. STARTER_DECK_CARD_PATHS) вне забега.
var deck: Array[CardData] = []
## ARC-016: у ИИ своя, независимая от run_deck игрока колода — раньше обе
## стороны делили один общий пул ("для простоты прототипа"), из-за чего ИИ
## мог тянуть и разыгрывать уникальные наградные карты игрока.
var enemy_deck: Array[CardData] = []
var artifact_manager: Node


func _ready() -> void:
	# Инициализация менеджера артефактов
	artifact_manager = load("res://core/artifact_manager.gd").new()
	add_child(artifact_manager)


## ARC-016: p_run_deck — колода забега (MatchSettings.run_deck), собственность
## игрока на весь роглик-забег, растёт от наград/магазина (ARC-015/012).
## Пустой массив (дефолт) — тестовый бой из главного меню, без забега: тогда
## используется старый _initialize_test_deck() как и раньше.
func setup_match(
	p_player: PlayerData, p_enemy: PlayerData, p_run_deck: Array[CardData] = []
) -> void:
	player_data = p_player
	enemy_data = p_enemy

	# ARC-002: setup_match() теперь может вызываться повторно за сессию (карта
	# мира -> бой -> карта -> следующий бой) — без сброса сюда бы утекали карты
	# из руки предыдущего матча.
	player_hand = []
	enemy_hand = []

	# enemy_data может прийти без ai_strategy (world_map_screen.gd, main_menu.gd) —
	# подстраховываемся здесь, в единой точке входа для всех боевых сценариев (ARC-078).
	if not enemy_data.ai_strategy:
		enemy_data.ai_strategy = load("res://data/resources/default_ai_strategy.gd").new()

	# Бонусы мета-прогрессии, если ProfileManager доступен (ARC-001).
	var profile_manager = get_node_or_null("/root/ProfileManager")
	if profile_manager:
		player_data.tower_hp += profile_manager.profile.player_stats.tower_hp_bonus
		player_data.quarry += profile_manager.profile.player_stats.resource_gain_bonus
		print("[DEBUG] Meta-progression bonuses applied")

	# ARC-016: в match_manager.deck кладём ШУФЛ-КОПИЮ run_deck, а не саму
	# run_deck — карты, разыгранные/сброшенные за бой, не должны пропадать из
	# забега навсегда (discard/reshuffle внутри одного боя — вне рамок этого
	# тикета).
	if not p_run_deck.is_empty():
		deck = p_run_deck.duplicate()
		deck.shuffle()
	else:
		_initialize_test_deck()

	# У ИИ нет run_deck (это коллекция ИГРОКА) — свой независимый пул на
	# каждый бой, из общего тестового набора карт.
	enemy_deck = _build_generic_card_pool()

	for i in range(5):
		draw_card(player_data)
		draw_card(enemy_data)

	current_state = State.START_MATCH
	GameEvents.match_started.emit(player_data, enemy_data)
	start_turn(player_data)


## Базовый пул карт — единственное место, где перечислены пути .tres. Общий
## источник для тестовой колоды игрока, колоды ИИ и стартовой колоды забега
## (см. _build_generic_card_pool ниже).
const STARTER_DECK_CARD_PATHS := [
	"res://data/cards/wall_card.tres",
	"res://data/cards/knight_card.tres",
	"res://data/cards/brick_1.tres",
	"res://data/cards/brick_2.tres",
	"res://data/cards/brick_3.tres",
	"res://data/cards/gem_1.tres",
	"res://data/cards/gem_2.tres",
	"res://data/cards/gem_3.tres",
	"res://data/cards/beast_1.tres",
	"res://data/cards/beast_2.tres",
	"res://data/cards/beast_3.tres",
]


func _initialize_test_deck() -> void:
	deck = _build_generic_card_pool()
	print("[DEBUG] Deck initialized with ", deck.size(), " cards")


## Перемешанный пул из STARTER_DECK_CARD_PATHS, дополненный случайными
## повторами до 20 карт. static — не трогает состояние матча, поэтому его
## также использует build_starting_run_deck() (стартовая колода игрока).
## Источники: тестовая колода игрока (_initialize_test_deck), колода ИИ
## (setup_match — у ИИ нет своей "коллекции", как run_deck у игрока, поэтому
## он всегда берёт отсюда) и стартовая колода забега (build_starting_run_deck).
static func _build_generic_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path in STARTER_DECK_CARD_PATHS:
		var card = load(path)
		if card:
			pool.append(card)
		else:
			print("[ERROR] Failed to load card: ", path)

	while pool.size() < 20:
		pool.append(pool.pick_random())

	pool.shuffle()
	return pool


## ARC-016: стартовая колода нового забега (main_menu.gd._on_campaign_pressed()).
## Сейчас буквально тот же пул, что и генерик-колода ИИ/теста
## (_build_generic_card_pool) — паддинг до 20 карт нужен потому, что
## setup_match() тянет 10 карт сразу при старте боя (5 игроку + 5 ИИ), и
## непаддинговая колода в 11 карт после этого почти опустошалась (баг, найденный
## при ручной проверке). Пока нет реальных наград/магазина (ARC-015/012),
## которые растили бы колоду органически, это самый простой рабочий вариант —
## когда они появятся, стоит пересмотреть (возможно, свой, отдельный от
## теста/ИИ стартовый набор без паддинга случайными повторами).
static func build_starting_run_deck() -> Array[CardData]:
	return _build_generic_card_pool()


func draw_card(player: PlayerData) -> void:
	var hand = player_hand if player == player_data else enemy_hand

	# ARC-003: рука ограничена max_hand_size — карта остаётся в колоде, а не
	# тянется "про запас" (ближе к оригинальным правилам Arcomage, чем
	# автосброс лишней карты).
	if hand.size() >= player.max_hand_size:
		return

	# ARC-016: у игрока и ИИ раздельные колоды (см. deck/enemy_deck выше).
	var is_player: bool = player == player_data
	var card: CardData = _draw_from_deck(is_player)
	if card == null:
		print("[ERROR] Drew a null card!")
		return

	hand.append(card)


func _draw_from_deck(is_player: bool) -> CardData:
	if is_player:
		if deck.is_empty():
			_initialize_test_deck()
		return deck.pop_back()

	if enemy_deck.is_empty():
		enemy_deck = _build_generic_card_pool()
	return enemy_deck.pop_back()


func start_turn(player: PlayerData) -> void:
	# Добераем карту в начале хода
	draw_card(player)

	# Прирост ресурсов
	player.bricks += player.quarry
	player.gems += player.magic
	player.beasts += player.dungeon

	GameEvents.resource_changed.emit(player, "all", 0)  # Сигнал для обновления UI
	GameEvents.turn_started.emit(player)

	if player == player_data:
		current_state = State.PLAYER_TURN
	else:
		current_state = State.AI_TURN
		execute_ai_turn()


func execute_ai_turn() -> void:
	# Небольшая задержка для визуального комфорта
	await get_tree().create_timer(1.0).timeout

	# Подстраховка: setup_match() всегда назначает стратегию по умолчанию, но если этот
	# метод вызвали в обход неё, отсутствие стратегии не должно вешать ход навсегда.
	if not enemy_data.ai_strategy:
		print("[ERROR] AI Strategy not set! Falling back to default_ai_strategy.gd")
		enemy_data.ai_strategy = load("res://data/resources/default_ai_strategy.gd").new()

	var best_card = enemy_data.ai_strategy.get_best_card(enemy_hand, enemy_data, player_data)

	if best_card:
		print("AI plays: ", best_card.card_name)
		var index = enemy_hand.find(best_card)
		play_card_by_index(index, enemy_data)
	elif not enemy_hand.is_empty():
		# Если нечего играть, сбрасываем случайную карту (Arcomage rules)
		var index = randi() % enemy_hand.size()
		var card_to_discard = enemy_hand[index]
		print("AI discards: ", card_to_discard.card_name)
		discard_card_by_index(index, enemy_data)
	else:
		# Рука пуста (крайний случай) — всё равно возвращаем ход игроку, а не подвешиваем матч.
		print("[DEBUG] AI has no cards to discard, passing turn")
		if not check_win():
			end_turn(enemy_data)


func play_card(card: CardData, actor: PlayerData) -> void:
	var hand = player_hand if actor == player_data else enemy_hand
	var index = hand.find(card)
	if index != -1:
		play_card_by_index(index, actor)


func play_card_by_index(index: int, actor: PlayerData) -> void:
	if current_state != State.PLAYER_TURN and current_state != State.AI_TURN:
		return

	var hand = player_hand if actor == player_data else enemy_hand
	if index < 0 or index >= hand.size():
		return

	var card = hand[index]

	# Проверка стоимости
	if not can_afford(card, actor):
		print("Not enough resources!")
		return

	current_state = State.PROCESS_CARD

	# Трата ресурсов
	match card.type:
		CardData.ResourceType.BRICKS:
			actor.bricks -= card.cost
		CardData.ResourceType.GEMS:
			actor.gems -= card.cost
		CardData.ResourceType.BEASTS:
			actor.beasts -= card.cost

	# Удаление из руки
	hand.remove_at(index)

	GameEvents.card_played.emit(card, actor)
	last_actor = actor

	# Применение эффектов (будет расширено в Шаге 5)
	apply_card_effects(card, actor)

	if not check_win():
		end_turn(actor)


func discard_card_by_index(index: int, actor: PlayerData) -> void:
	# Разрешаем сброс только если сейчас ход игрока или ИИ
	if current_state != State.PLAYER_TURN and current_state != State.AI_TURN:
		return

	# Проверка, чей сейчас ход
	if current_state == State.PLAYER_TURN and actor != player_data:
		return
	if current_state == State.AI_TURN and actor != enemy_data:
		return

	var hand = player_hand if actor == player_data else enemy_hand
	if index < 0 or index >= hand.size():
		return

	# Удаление из руки
	hand.remove_at(index)

	# Конец хода
	if not check_win():
		end_turn(actor)


func can_afford(card: CardData, actor: PlayerData) -> bool:
	match card.type:
		CardData.ResourceType.BRICKS:
			return actor.bricks >= card.cost
		CardData.ResourceType.GEMS:
			return actor.gems >= card.cost
		CardData.ResourceType.BEASTS:
			return actor.beasts >= card.cost
	return false


func apply_card_effects(card: CardData, actor: PlayerData) -> void:
	var enemy = enemy_data if actor == player_data else player_data

	for effect in card.effects:
		var type = effect.get("type", "")
		var value = effect.get("value", 0)
		var target_str = effect.get("target", "enemy")

		var target_player = resolve_target(actor, enemy, target_str)

		match type:
			"damage":
				apply_damage(value, target_player, false)
			"direct_damage":
				apply_damage(value, target_player, true)
			"build_wall":
				target_player.wall_hp += value
				GameEvents.value_built.emit(target_player, value, "wall")
			"build_tower":
				target_player.tower_hp += value
				GameEvents.value_built.emit(target_player, value, "tower")
			"mod_quarry":
				target_player.quarry += value
			"mod_magic":
				target_player.magic += value
			"mod_dungeon":
				target_player.dungeon += value

	GameEvents.resource_changed.emit(actor, "all", 0)
	GameEvents.resource_changed.emit(enemy, "all", 0)


## ARC-005: единая точка резолва `target` из словаря эффекта карты/артефакта в
## конкретного PlayerData. Учитывается только префикс "self"/"enemy" — суффикс
## `_wall`/`_tower` (например, "enemy_wall") ни на что здесь не влияет и для
## большинства типов эффекта чисто описательный, см. docs/effects_reference.md.
func resolve_target(actor: PlayerData, enemy: PlayerData, target_str: String) -> PlayerData:
	if target_str.begins_with("self"):
		return actor
	return enemy


func apply_damage(amount: int, target: PlayerData, ignore_wall: bool) -> void:
	if ignore_wall:
		target.tower_hp -= amount
	else:
		var overflow = amount - target.wall_hp
		target.wall_hp = max(0, target.wall_hp - amount)
		if overflow > 0:
			target.tower_hp -= overflow

	# ARC-004: damage_applied несёт положительный amount — знак больше не нужен,
	# т.к. само имя сигнала уже говорит "это урон".
	var hit_wall = not ignore_wall
	GameEvents.damage_applied.emit(target, amount, hit_wall)


func check_win() -> bool:
	current_state = State.CHECK_WIN
	var winner = null

	if player_data.tower_hp >= WIN_TOWER_HEIGHT or enemy_data.tower_hp <= 0:
		winner = player_data
	elif enemy_data.tower_hp >= WIN_TOWER_HEIGHT or player_data.tower_hp <= 0:
		winner = enemy_data
	elif (
		player_data.bricks >= WIN_RESOURCE_AMOUNT
		or player_data.gems >= WIN_RESOURCE_AMOUNT
		or player_data.beasts >= WIN_RESOURCE_AMOUNT
	):
		winner = player_data
	elif (
		enemy_data.bricks >= WIN_RESOURCE_AMOUNT
		or enemy_data.gems >= WIN_RESOURCE_AMOUNT
		or enemy_data.beasts >= WIN_RESOURCE_AMOUNT
	):
		winner = enemy_data

	if winner:
		current_state = State.END_MATCH
		GameEvents.match_ended.emit(winner)
		return true

	return false


func end_turn(actor: PlayerData) -> void:
	var next_player = enemy_data if actor == player_data else player_data
	start_turn(next_player)
