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
var deck: Array[CardData] = []  # Общая колода для простоты прототипа
var artifact_manager: Node


func _ready() -> void:
	# Инициализация менеджера артефактов
	artifact_manager = load("res://core/artifact_manager.gd").new()
	add_child(artifact_manager)


func setup_match(p_player: PlayerData, p_enemy: PlayerData) -> void:
	player_data = p_player
	enemy_data = p_enemy

	# Баг: экраны, создающие enemy_data "на лету" (world_map_screen.gd, main_menu.gd),
	# не назначают ai_strategy. Без неё execute_ai_turn() печатал ошибку и выходил,
	# ни разу не вызвав end_turn() — матч навсегда зависал в AI_TURN. Подстраховываемся
	# здесь, в единой точке входа для всех боевых сценариев.
	if not enemy_data.ai_strategy:
		enemy_data.ai_strategy = load("res://data/resources/default_ai_strategy.gd").new()

	# Применение бонусов мета-прогрессии, если ProfileManager доступен (ARC-001).
	# Раньше: ProfileManager не был зарегистрирован в [autoload], поэтому
	# get_node_or_null() всегда возвращал null и весь блок молча не выполнялся —
	# бонусы никогда не применялись, без единой ошибки в логе. Заодно был второй,
	# скрытый этим багом баг: profile_manager.has("profile") — has() не метод
	# базового Object/Node (это не Dictionary/Array), такой вызов упал бы с
	# "Nonexistent function 'has'", если бы когда-либо реально выполнился. profile —
	# обычное поле скрипта с дефолтным значением, всегда существует, когда узел
	# существует, поэтому отдельная проверка не нужна вовсе.
	var profile_manager = get_node_or_null("/root/ProfileManager")
	if profile_manager:
		player_data.tower_hp += profile_manager.profile.player_stats.tower_hp_bonus
		player_data.quarry += profile_manager.profile.player_stats.resource_gain_bonus
		print("[DEBUG] Meta-progression bonuses applied")

	# Инициализация колоды и рук (заглушка)
	_initialize_test_deck()
	for i in range(5):
		draw_card(player_data)
		draw_card(enemy_data)

	current_state = State.START_MATCH
	GameEvents.match_started.emit(player_data, enemy_data)
	start_turn(player_data)


func _initialize_test_deck() -> void:
	var card_paths = [
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
		"res://data/cards/beast_3.tres"
	]

	deck = []
	for path in card_paths:
		var card = load(path)
		if card:
			deck.append(card)
		else:
			print("[ERROR] Failed to load card: ", path)

	# Заполняем колоду до нужного количества, если нужно
	while deck.size() < 20:
		deck.append(deck.pick_random())

	deck.shuffle()
	print("[DEBUG] Deck initialized with ", deck.size(), " cards")


func draw_card(player: PlayerData) -> void:
	if deck.is_empty():
		_initialize_test_deck()

	var card = deck.pop_back()
	if card == null:
		print("[ERROR] Drew a null card!")
		return

	if player == player_data:
		player_hand.append(card)
	else:
		enemy_hand.append(card)


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

		var target_player = enemy
		if target_str.begins_with("self"):
			target_player = actor

		match type:
			"damage":
				apply_damage(value, target_player, false)
			"direct_damage":
				apply_damage(value, target_player, true)
			"build_wall":
				target_player.wall_hp += value
				GameEvents.health_changed.emit(target_player, value)
			"build_tower":
				target_player.tower_hp += value
				GameEvents.health_changed.emit(target_player, value)
			"mod_quarry":
				target_player.quarry += value
			"mod_magic":
				target_player.magic += value
			"mod_dungeon":
				target_player.dungeon += value
			"build":  # Универсальный эффект из примера в CardData
				if target_str == "self_wall":
					target_player.wall_hp += value
				elif target_str == "self_tower":
					target_player.tower_hp += value
				GameEvents.health_changed.emit(target_player, value)

	GameEvents.resource_changed.emit(actor, "all", 0)
	GameEvents.resource_changed.emit(enemy, "all", 0)


func apply_damage(amount: int, target: PlayerData, ignore_wall: bool) -> void:
	if ignore_wall:
		target.tower_hp -= amount
	else:
		var overflow = amount - target.wall_hp
		target.wall_hp = max(0, target.wall_hp - amount)
		if overflow > 0:
			target.tower_hp -= overflow

	GameEvents.health_changed.emit(target, -amount)


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
