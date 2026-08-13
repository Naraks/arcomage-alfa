extends Node
## Правила матча, ходы, карты и условия победы.

enum State { START_MATCH, PLAYER_TURN, PROCESS_CARD, AI_TURN, CHECK_WIN, END_MATCH }

const WIN_TOWER_HEIGHT = 55
const WIN_RESOURCE_AMOUNT = 300

const DEFAULT_AI_STRATEGY_PATH := "res://data/resources/default_ai_strategy.gd"

const DefaultAIStrategyScript = preload("res://data/resources/default_ai_strategy.gd")
const AggressiveAIStrategyScript = preload("res://data/resources/aggressive_ai_strategy.gd")
const BuilderAIStrategyScript = preload("res://data/resources/builder_ai_strategy.gd")
const EconomistAIStrategyScript = preload("res://data/resources/economist_ai_strategy.gd")

const REGULAR_STRATEGY_SCRIPTS: Array = [
	DefaultAIStrategyScript,
	AggressiveAIStrategyScript,
	BuilderAIStrategyScript,
	EconomistAIStrategyScript
]

const STARTER_DECK_CARD_PATHS := [
	"res://data/cards/wall_card.tres",
	"res://data/cards/knight_card.tres",
	"res://data/cards/brick_1.tres",
	"res://data/cards/brick_9.tres",
	"res://data/cards/brick_3.tres",
	"res://data/cards/gem_1.tres",
	"res://data/cards/gem_2.tres",
	"res://data/cards/gem_3.tres",
	"res://data/cards/beast_1.tres",
	"res://data/cards/beast_2.tres",
	"res://data/cards/beast_3.tres",
]

const STARTING_RUN_GOLD := 20

const ALL_CARD_PATHS := [
	"res://data/cards/wall_card.tres",
	"res://data/cards/knight_card.tres",
	"res://data/cards/brick_1.tres",
	"res://data/cards/brick_3.tres",
	"res://data/cards/brick_4.tres",
	"res://data/cards/brick_5.tres",
	"res://data/cards/brick_6.tres",
	"res://data/cards/brick_7.tres",
	"res://data/cards/brick_8.tres",
	"res://data/cards/brick_9.tres",
	"res://data/cards/brick_10.tres",
	"res://data/cards/brick_13.tres",
	"res://data/cards/brick_14.tres",
	"res://data/cards/brick_15.tres",
	"res://data/cards/brick_16.tres",
	"res://data/cards/brick_17.tres",
	"res://data/cards/brick_18.tres",
	"res://data/cards/brick_19.tres",
	"res://data/cards/brick_20.tres",
	"res://data/cards/brick_21.tres",
	"res://data/cards/brick_22.tres",
	"res://data/cards/brick_23.tres",
	"res://data/cards/brick_24.tres",
	"res://data/cards/gem_1.tres",
	"res://data/cards/gem_2.tres",
	"res://data/cards/gem_3.tres",
	"res://data/cards/gem_4.tres",
	"res://data/cards/gem_5.tres",
	"res://data/cards/gem_6.tres",
	"res://data/cards/gem_7.tres",
	"res://data/cards/gem_8.tres",
	"res://data/cards/gem_9.tres",
	"res://data/cards/gem_10.tres",
	"res://data/cards/gem_11.tres",
	"res://data/cards/gem_12.tres",
	"res://data/cards/gem_13.tres",
	"res://data/cards/gem_14.tres",
	"res://data/cards/gem_15.tres",
	"res://data/cards/gem_16.tres",
	"res://data/cards/gem_17.tres",
	"res://data/cards/gem_18.tres",
	"res://data/cards/gem_19.tres",
	"res://data/cards/gem_20.tres",
	"res://data/cards/gem_21.tres",
	"res://data/cards/gem_22.tres",
	"res://data/cards/gem_23.tres",
	"res://data/cards/beast_1.tres",
	"res://data/cards/beast_2.tres",
	"res://data/cards/beast_3.tres",
	"res://data/cards/beast_5.tres",
	"res://data/cards/beast_6.tres",
	"res://data/cards/beast_7.tres",
	"res://data/cards/beast_8.tres",
	"res://data/cards/beast_9.tres",
	"res://data/cards/beast_10.tres",
	"res://data/cards/beast_11.tres",
	"res://data/cards/beast_12.tres",
	"res://data/cards/beast_13.tres",
	"res://data/cards/beast_14.tres",
	"res://data/cards/beast_15.tres",
	"res://data/cards/beast_16.tres",
	"res://data/cards/beast_17.tres",
	"res://data/cards/beast_18.tres",
	"res://data/cards/beast_19.tres",
	"res://data/cards/beast_20.tres",
	"res://data/cards/beast_21.tres",
	"res://data/cards/beast_22.tres",
	"res://data/cards/beast_23.tres",
]

var current_state: State = State.START_MATCH
var player_data: PlayerData
var enemy_data: PlayerData
var last_actor: PlayerData
var auto_execute_ai_turn: bool = true

var last_win_reason: String = ""
var last_win_resource: String = ""

var player_hand: Array[CardData] = []
var enemy_hand: Array[CardData] = []
var deck: Array[CardData] = []
var enemy_deck: Array[CardData] = []


func pick_random_regular_ai_strategy() -> Resource:
	return REGULAR_STRATEGY_SCRIPTS[randi() % REGULAR_STRATEGY_SCRIPTS.size()].new()


func setup_match(
	p_player: PlayerData,
	p_enemy: PlayerData,
	p_run_deck: Array[CardData] = [],
	p_apply_player_progression: bool = true,
	p_starting_side: int = 0,
	p_auto_execute_ai_turn: bool = true
) -> void:
	player_data = p_player
	enemy_data = p_enemy
	auto_execute_ai_turn = p_auto_execute_ai_turn

	player_hand = []
	enemy_hand = []

	if not enemy_data.ai_strategy:
		enemy_data.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()

	var profile_manager = get_node_or_null("/root/ProfileManager")
	if profile_manager and p_apply_player_progression:
		player_data.tower_hp += profile_manager.get_upgrade_bonus("tower")
		player_data.wall_hp += profile_manager.get_upgrade_bonus("wall")
		player_data.quarry += profile_manager.get_upgrade_bonus("quarry")
		player_data.magic += profile_manager.get_upgrade_bonus("magic")
		player_data.dungeon += profile_manager.get_upgrade_bonus("dungeon")
		player_data.max_hand_size += profile_manager.get_upgrade_bonus("hand_size")
		print("[DEBUG] Meta-progression bonuses applied")

	if p_apply_player_progression:
		player_data.tower_hp += MatchSettings.run_tower_bonus
		player_data.quarry += MatchSettings.run_quarry_bonus
		player_data.magic += MatchSettings.run_magic_bonus
		player_data.dungeon += MatchSettings.run_dungeon_bonus

	if p_apply_player_progression:
		player_data.active_artifacts = MatchSettings.run_artifacts.duplicate()
	else:
		player_data.active_artifacts.clear()

	if not p_run_deck.is_empty():
		deck = p_run_deck.duplicate()
		deck.shuffle()
		enemy_deck = _build_generic_card_pool()
	else:
		deck = _build_full_card_pool()
		enemy_deck = _build_full_card_pool()

	for i in range(5):
		draw_card(player_data)
		draw_card(enemy_data)

	current_state = State.START_MATCH
	GameEvents.match_started.emit(player_data, enemy_data)
	start_turn(player_data if p_starting_side == 0 else enemy_data)


func _initialize_test_deck() -> void:
	deck = _build_generic_card_pool()
	print("[DEBUG] Deck initialized with ", deck.size(), " cards")


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


static func _build_full_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path in ALL_CARD_PATHS:
		var card = load(path)
		if card:
			pool.append(card)
		else:
			print("[ERROR] Failed to load card: ", path)

	pool.shuffle()
	return pool


static func build_starting_run_deck() -> Array[CardData]:
	return _build_generic_card_pool()


static func build_shop_offer(card_count: int) -> Array[CardData]:
	var paths := ALL_CARD_PATHS.duplicate()
	paths.shuffle()

	var offer: Array[CardData] = []
	for path in paths:
		if offer.size() >= card_count:
			break
		var card = load(path)
		if not card:
			print("[ERROR] Failed to load card: ", path)
			continue
		if not ProfileManager.is_card_unlocked(card):
			continue
		offer.append(card)
	return offer


func draw_card(player: PlayerData) -> void:
	var hand = player_hand if player == player_data else enemy_hand

	if hand.size() >= player.max_hand_size:
		return

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
	draw_card(player)

	player.bricks += player.quarry
	player.gems += player.magic
	player.beasts += player.dungeon

	GameEvents.resource_changed.emit(player, "all", 0)
	GameEvents.turn_started.emit(player)

	if player == player_data:
		current_state = State.PLAYER_TURN
	else:
		current_state = State.AI_TURN
		if auto_execute_ai_turn:
			execute_ai_turn()


func execute_ai_turn() -> void:
	await _create_ai_turn_timer().timeout
	_resolve_ai_turn(enemy_data)


func _create_ai_turn_timer(delay_seconds: float = 1.0) -> SceneTreeTimer:
	# process_always=false сохраняет оставшееся время при паузе вкладки.
	return get_tree().create_timer(delay_seconds, false)


func _resolve_ai_turn(actor: PlayerData) -> void:
	var opponent = enemy_data if actor == player_data else player_data
	var hand = player_hand if actor == player_data else enemy_hand

	if not actor.ai_strategy:
		print("[ERROR] AI Strategy not set! Falling back to default_ai_strategy.gd")
		actor.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()

	var best_card = actor.ai_strategy.get_best_card(hand, actor, opponent)

	if best_card:
		print("AI plays: ", best_card.card_name)
		var index = hand.find(best_card)
		play_card_by_index(index, actor)
	elif not hand.is_empty():
		var index = randi() % hand.size()
		var card_to_discard = hand[index]
		print("AI discards: ", card_to_discard.card_name)
		discard_card_by_index(index, actor)
	else:
		print("[DEBUG] AI has no cards to discard, passing turn")
		if not check_win():
			end_turn(actor)


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

	if not can_afford(card, actor):
		print("Not enough resources!")
		return

	current_state = State.PROCESS_CARD

	var skip_payment: bool = ArtifactManager.should_skip_payment(actor)

	if not skip_payment:
		match card.type:
			CardData.ResourceType.BRICKS:
				actor.bricks -= card.cost
			CardData.ResourceType.GEMS:
				actor.gems -= card.cost
			CardData.ResourceType.BEASTS:
				actor.beasts -= card.cost

	hand.remove_at(index)

	GameEvents.card_played.emit(card, actor)
	last_actor = actor

	apply_card_effects(card, actor)

	if not check_win():
		end_turn(actor)


func discard_card_by_index(index: int, actor: PlayerData) -> void:
	if current_state != State.PLAYER_TURN and current_state != State.AI_TURN:
		return

	if current_state == State.PLAYER_TURN and actor != player_data:
		return
	if current_state == State.AI_TURN and actor != enemy_data:
		return

	var hand = player_hand if actor == player_data else enemy_hand
	if index < 0 or index >= hand.size():
		return

	hand.remove_at(index)

	if not check_win():
		end_turn(actor)


func can_afford(card: CardData, actor: PlayerData) -> bool:
	return EffectUtils.can_afford(card, actor)


func apply_card_effects(card: CardData, actor: PlayerData) -> void:
	var enemy = enemy_data if actor == player_data else player_data

	for effect in card.effects:
		_apply_effect(effect, actor, enemy)

	GameEvents.resource_changed.emit(actor, "all", 0)
	GameEvents.resource_changed.emit(enemy, "all", 0)


func _apply_effect(effect: EffectData, actor: PlayerData, enemy: PlayerData) -> void:
	var type := effect.type
	var value := effect.value

	var target_player = resolve_target(actor, enemy, effect.target)

	match type:
		"damage":
			apply_damage(value, target_player, false, actor)
		"direct_damage":
			apply_damage(value, target_player, true, actor)
		"build_wall":
			target_player.wall_hp += value
			GameEvents.value_built.emit(target_player, value, "wall")
		"build_tower":
			target_player.tower_hp += value
			GameEvents.value_built.emit(target_player, value, "tower")
		"mod_quarry":
			target_player.quarry = max(0, target_player.quarry + value)
		"mod_magic":
			target_player.magic = max(0, target_player.magic + value)
		"mod_dungeon":
			target_player.dungeon = max(0, target_player.dungeon + value)
		"draw_card":
			for i in range(value):
				draw_card(target_player)
		"steal_resource":
			_apply_steal_resource(effect, target_player, actor)
		"conditional":
			var branch: EffectData = EffectUtils.resolve_conditional_branch(effect, actor, enemy)
			if branch:
				_apply_effect(branch, actor, enemy)
		"gain_resource":
			_modify_resource(target_player, effect.resource, value)
		"drain_resource":
			var drain_amount: int = min(value, _get_resource(target_player, effect.resource))
			if drain_amount > 0:
				_modify_resource(target_player, effect.resource, -drain_amount)
		"reduce_wall":
			target_player.wall_hp = max(0, target_player.wall_hp - value)
		_:
			push_warning("MatchManager: неизвестный тип эффекта карты '%s'" % type)


func _apply_steal_resource(
	effect: EffectData, from_player: PlayerData, to_player: PlayerData
) -> void:
	var resource_name: String = effect.resource
	if resource_name == "random":
		resource_name = EffectUtils.RESOURCE_NAMES[randi() % EffectUtils.RESOURCE_NAMES.size()]
	var amount: int = min(effect.value, _get_resource(from_player, resource_name))
	if amount <= 0:
		return
	_modify_resource(from_player, resource_name, -amount)
	_modify_resource(to_player, resource_name, amount)


func _get_resource(player: PlayerData, resource_name: String) -> int:
	return EffectUtils.get_resource(player, resource_name)


func _modify_resource(player: PlayerData, resource_name: String, delta: int) -> void:
	EffectUtils.modify_resource(player, resource_name, delta)


func _get_field(player: PlayerData, field_name: String):
	return EffectUtils.get_field(player, field_name)


func _evaluate_condition(value, op: String, threshold) -> bool:
	return EffectUtils.evaluate_condition(value, op, threshold)


func resolve_target(actor: PlayerData, enemy: PlayerData, target_str: String) -> PlayerData:
	return EffectUtils.resolve_target(actor, enemy, target_str)


func apply_damage(
	amount: int, target: PlayerData, ignore_wall: bool, source: PlayerData = null
) -> void:
	if ignore_wall:
		target.tower_hp -= amount
	else:
		var overflow = amount - target.wall_hp
		target.wall_hp = max(0, target.wall_hp - amount)
		if overflow > 0:
			target.tower_hp -= overflow

	var hit_wall = not ignore_wall
	GameEvents.damage_applied.emit(target, amount, hit_wall, source)


func check_win() -> bool:
	current_state = State.CHECK_WIN
	var winner = null
	var reason := ""
	var win_resource := ""

	if enemy_data.tower_hp <= 0:
		winner = player_data
		reason = "tower_destroyed"
	elif player_data.tower_hp <= 0:
		winner = enemy_data
		reason = "tower_destroyed"
	elif player_data.tower_hp >= WIN_TOWER_HEIGHT:
		winner = player_data
		reason = "tower_height"
	elif enemy_data.tower_hp >= WIN_TOWER_HEIGHT:
		winner = enemy_data
		reason = "tower_height"
	elif player_data.bricks >= WIN_RESOURCE_AMOUNT:
		winner = player_data
		reason = "resource"
		win_resource = "bricks"
	elif player_data.gems >= WIN_RESOURCE_AMOUNT:
		winner = player_data
		reason = "resource"
		win_resource = "gems"
	elif player_data.beasts >= WIN_RESOURCE_AMOUNT:
		winner = player_data
		reason = "resource"
		win_resource = "beasts"
	elif enemy_data.bricks >= WIN_RESOURCE_AMOUNT:
		winner = enemy_data
		reason = "resource"
		win_resource = "bricks"
	elif enemy_data.gems >= WIN_RESOURCE_AMOUNT:
		winner = enemy_data
		reason = "resource"
		win_resource = "gems"
	elif enemy_data.beasts >= WIN_RESOURCE_AMOUNT:
		winner = enemy_data
		reason = "resource"
		win_resource = "beasts"

	if winner:
		current_state = State.END_MATCH
		last_win_reason = reason
		last_win_resource = win_resource
		GameEvents.match_ended.emit(winner)
		return true

	return false


func end_turn(actor: PlayerData) -> void:
	var next_player = enemy_data if actor == player_data else player_data
	start_turn(next_player)
