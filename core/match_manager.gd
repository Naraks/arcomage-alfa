extends Node

## MatchManager: Основной контроллер матча Arcomage

enum State { START_MATCH, PLAYER_TURN, PROCESS_CARD, AI_TURN, CHECK_WIN, END_MATCH }

const WIN_TOWER_HEIGHT = 100
const WIN_RESOURCE_AMOUNT = 300

## ARC-084 (gdlint class-definitions-order): все const этого файла собраны в
## одном месте, в начале, а не разбросаны между функциями — раньше
## STARTER_DECK_CARD_PATHS/STARTING_RUN_GOLD/ALL_CARD_PATHS/RESOURCE_NAMES
## были определены значительно ниже, вперемешку с методами (сохранены на
## месте использования доккомментарии — сами константы просто переехали).

const DEFAULT_AI_STRATEGY_PATH := "res://data/resources/default_ai_strategy.gd"

## ARC-085: вынесено сюда из ui/map/world_map_screen.gd, чтобы Быстрый бой
## (ui/main_menu.gd::_on_battle_pressed()) тоже мог давать случайный обычный
## архетип, а не только обычный бой на карте мира — вместо дублирования
## одного и того же списка/рандомайзера в двух экранах. world_map_screen.gd
## по-прежнему держит свой ELITE_STRATEGY_SCRIPTS локально — он не переиспользуется
## больше нигде.
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

## Базовый пул карт — единственное место, где перечислены пути .tres. Общий
## источник для тестовой колоды игрока, колоды ИИ и стартовой колоды забега
## (см. _build_generic_card_pool ниже).
const STARTER_DECK_CARD_PATHS := [
	"res://data/cards/wall_card.tres",
	"res://data/cards/knight_card.tres",
	"res://data/cards/brick_1.tres",
	# ARC-084: brick_2.tres ("Стена 1", стена+2) убран из игры целиком —
	# точный дубликат-хуже wall_card.tres ("Стена", стена+3) на том же cost=1,
	# см. docs/balance_proposal_arc084.md §1. Заменён на brick_9.tres ("Бур"),
	# чтобы Кирпичи не остались единственным типом с 2 стартовыми картами
	# вместо 3 (у Гемов/Зверей — по 3, см. gem_1..3/beast_1..3 ниже).
	"res://data/cards/brick_9.tres",
	"res://data/cards/brick_3.tres",
	"res://data/cards/gem_1.tres",
	"res://data/cards/gem_2.tres",
	"res://data/cards/gem_3.tres",
	"res://data/cards/beast_1.tres",
	"res://data/cards/beast_2.tres",
	"res://data/cards/beast_3.tres",
]

## ARC-012: стартовое золото забега — заглушка, пока в игре нет реальных
## источников золота (ARC-013/014/015).
const STARTING_RUN_GOLD := 20

## ARC-012: все карты игры — источник предложений магазина (в отличие от
## урезанного STARTER_DECK_CARD_PATHS выше), включая RARE (пул общий по
## редкости, фильтрация по редкости — не здесь). ARC-020 добавил сюда 32
## новые карты (включая 12 RARE) и отметил как отложенную проблему: RARE не
## должны попадать в магазин/награду обычного боя (design doc §5.3). ARC-038
## её закрыл — build_shop_offer() ниже и ui/reward/reward_screen.gd
## (_unlocked_paths()) фильтруют RARE-карты через
## ProfileManager.is_card_unlocked(), так что в этом массиве по-прежнему
## перечислены ВСЕ карты (это по-прежнему полный пул), но заблокированные
## RARE отсеиваются на этапе построения предложения, а не здесь.
##
## ARC-084 (docs/balance_proposal_arc084.md): brick_2/brick_11/brick_12/beast_4
## убраны насовсем — точные дубликаты/доминируемые варианты уже существующих
## карт (не про слабость, это уже правил ARC-023). brick_23/brick_24/gem_22/
## gem_23/beast_22/beast_23 — новые карты верхнего края (cost 6/8/9),
## закрывающие пробелы кривой impact/cost из docs/balance_audit_arc084.md.
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

## ARC-021 (используется в _apply_steal_resource ниже): список типов ресурса
## для "любой" (resource == "random", карта "Кража времени").
const RESOURCE_NAMES := ["bricks", "gems", "beasts"]

var current_state: State = State.START_MATCH
var player_data: PlayerData
var enemy_data: PlayerData
var last_actor: PlayerData

## ARC-084 (профилирование симулятора, tools/battle_simulator.gd): тип
## последней победы — "tower_height" (своя башня достигла WIN_TOWER_HEIGHT),
## "tower_destroyed" (башня врага упала до 0) или "resource" (свой ресурс
## достиг WIN_RESOURCE_AMOUNT). last_win_resource заполняется только для
## "resource" ("bricks"/"gems"/"beasts") — иначе пустая строка. Оба поля
## выставляются в check_win() непосредственно перед match_ended, не
## сбрасываются автоматически между матчами (следующий check_win()
## перезапишет их заново, как и winner).
var last_win_reason: String = ""
var last_win_resource: String = ""

var player_hand: Array[CardData] = []
var enemy_hand: Array[CardData] = []
## Колода игрока — стартовая из run_deck (ARC-016) в реальном забеге, либо
## тестовый пул (см. STARTER_DECK_CARD_PATHS) вне забега.
var deck: Array[CardData] = []
## ARC-016: у ИИ своя, независимая от run_deck игрока колода — раньше обе
## стороны делили один общий пул ("для простоты прототипа"), из-за чего ИИ
## мог тянуть и разыгрывать уникальные наградные карты игрока.
var enemy_deck: Array[CardData] = []


## ARC-085: вынесено сюда из ui/map/world_map_screen.gd, чтобы Быстрый бой
## (ui/main_menu.gd::_on_battle_pressed()) тоже мог давать случайный обычный
## архетип, а не только обычный бой на карте мира — вместо дублирования
## одного и того же рандомайзера в двух экранах.
func pick_random_regular_ai_strategy() -> Resource:
	return REGULAR_STRATEGY_SCRIPTS[randi() % REGULAR_STRATEGY_SCRIPTS.size()].new()


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
		enemy_data.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()

	# Бонусы мета-прогрессии, если ProfileManager доступен (ARC-001).
	# ARC-037: раньше здесь было два хардкодных плоских бонуса
	# (player_stats.tower_hp_bonus/resource_gain_bonus, всегда включены) —
	# теперь все шесть читаются из настоящего каталога прокачки
	# (ProfileManager.UPGRADE_CATALOG), покупаются за Славу в MetaShopScreen,
	# по умолчанию 0 (см. комментарий в profile_manager.gd).
	var profile_manager = get_node_or_null("/root/ProfileManager")
	if profile_manager:
		player_data.tower_hp += profile_manager.get_upgrade_bonus("tower")
		player_data.wall_hp += profile_manager.get_upgrade_bonus("wall")
		player_data.quarry += profile_manager.get_upgrade_bonus("quarry")
		player_data.magic += profile_manager.get_upgrade_bonus("magic")
		player_data.dungeon += profile_manager.get_upgrade_bonus("dungeon")
		player_data.max_hand_size += profile_manager.get_upgrade_bonus("hand_size")
		print("[DEBUG] Meta-progression bonuses applied")

	# ARC-013: постоянные усиления забега с узлов «Отдых» — тем же механизмом,
	# что и бонусы ProfileManager чуть выше.
	player_data.tower_hp += MatchSettings.run_tower_bonus
	player_data.quarry += MatchSettings.run_quarry_bonus
	player_data.magic += MatchSettings.run_magic_bonus
	player_data.dungeon += MatchSettings.run_dungeon_bonus

	# ARC-015: артефакты забега (награда за бой) — копия, не сама run_artifacts,
	# по аналогии с run_deck ниже.
	player_data.active_artifacts = MatchSettings.run_artifacts.duplicate()

	# ARC-016: в match_manager.deck кладём ШУФЛ-КОПИЮ run_deck, а не саму
	# run_deck — карты, разыгранные/сброшенные за бой, не должны пропадать из
	# забега навсегда (discard/reshuffle внутри одного боя — вне рамок этого
	# тикета).
	if not p_run_deck.is_empty():
		deck = p_run_deck.duplicate()
		deck.shuffle()
		# У ИИ нет run_deck (это коллекция ИГРОКА) — свой независимый пул на
		# каждый бой, из общего тестового набора карт.
		enemy_deck = _build_generic_card_pool()
	else:
		# ARC-095: тестовый бой без забега («Битва» в главном меню) — раньше
		# и игрок, и ИИ получали урезанный STARTER_DECK_CARD_PATHS (11 карт),
		# дополненный случайными повторами до 20 (_build_generic_card_pool,
		# см. _initialize_test_deck). Теперь оба берут полный пул всех
		# уникальных карт игры (ALL_CARD_PATHS) без паддинга повторами —
		# тестовый бой должен давать возможность увидеть в деле любую карту,
		# не только стартовый набор. Реального забега (p_run_deck непустой)
		# это не касается — там уже и так настоящая растущая колода игрока.
		deck = _build_full_card_pool()
		enemy_deck = _build_full_card_pool()

	for i in range(5):
		draw_card(player_data)
		draw_card(enemy_data)

	current_state = State.START_MATCH
	GameEvents.match_started.emit(player_data, enemy_data)
	start_turn(player_data)


## ARC-095: используется теперь только аварийным доливом в _draw_from_deck()
## (колода игрока опустела посреди боя, реальный забег или нет) — при старте
## тестового боя без забега setup_match() с этого тикета берёт
## _build_full_card_pool(), не этот генерик-пул.
func _initialize_test_deck() -> void:
	deck = _build_generic_card_pool()
	print("[DEBUG] Deck initialized with ", deck.size(), " cards")


## Перемешанный пул из STARTER_DECK_CARD_PATHS, дополненный случайными
## повторами до 20 карт. static — не трогает состояние матча, поэтому его
## также использует build_starting_run_deck() (стартовая колода игрока).
## Источники: аварийный долив опустевшей колоды игрока (_draw_from_deck),
## колода ИИ в реальном забеге (setup_match, у ИИ нет своей "коллекции", как
## run_deck у игрока) и стартовая колода забега (build_starting_run_deck).
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


## ARC-095: полный пул уникальных карт игры (ALL_CARD_PATHS, без паддинга
## повторами — 68 карт уже с запасом покрывают любой разумный размер колоды)
## — только для тестового боя из главного меню («Битва», p_run_deck пуст).
## Настоящий забег (world_map BATTLE/ELITE_BATTLE/BOSS) не использует эту
## функцию вовсе — там и так настоящая растущая колода игрока (p_run_deck),
## а колода ИИ там всё ещё берётся из _build_generic_card_pool().
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


## card_count РАЗНЫХ карт (без повторов) из ALL_CARD_PATHS — предложение
## магазина на визит. Если card_count больше размера пула (после фильтра
## ARC-038 ниже), возвращает весь доступный пул.
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
		# ARC-038: RARE-карты не должны попадать в магазин, пока не куплены за
		# Славу (design doc §5.3) — раньше пул был общим для всех редкостей
		# (см. комментарий у ALL_CARD_PATHS), это и есть та отложенная правка.
		if not ProfileManager.is_card_unlocked(card):
			continue
		offer.append(card)
	return offer


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
	_resolve_ai_turn(enemy_data)


## ARC-054: чистая логика "сходить за actor'а его ai_strategy" без await/
## задержки — вынесена из execute_ai_turn(), чтобы её мог напрямую вызывать
## tools/battle_simulator.gd (сотни автобоёв без искусственной секундной паузы,
## которая нужна только реальному battle_screen.gd для комфорта игрока-человека).
## Обобщена на любого actor (не только enemy_data) — симулятору ИИ-против-ИИ
## нужно так же прогонять ход и за player_data, если ему тоже назначена
## ai_strategy (в обычном UI-бою за player_data всегда ходит человек, эта
## ветка там не используется).
func _resolve_ai_turn(actor: PlayerData) -> void:
	var opponent = enemy_data if actor == player_data else player_data
	var hand = player_hand if actor == player_data else enemy_hand

	# Та же подстраховка, что раньше была только для enemy_data в execute_ai_turn():
	# отсутствие стратегии не должно вешать ход навсегда.
	if not actor.ai_strategy:
		print("[ERROR] AI Strategy not set! Falling back to default_ai_strategy.gd")
		actor.ai_strategy = load(DEFAULT_AI_STRATEGY_PATH).new()

	var best_card = actor.ai_strategy.get_best_card(hand, actor, opponent)

	if best_card:
		print("AI plays: ", best_card.card_name)
		var index = hand.find(best_card)
		play_card_by_index(index, actor)
	elif not hand.is_empty():
		# Если нечего играть, сбрасываем случайную карту (Arcomage rules)
		var index = randi() % hand.size()
		var card_to_discard = hand[index]
		print("AI discards: ", card_to_discard.card_name)
		discard_card_by_index(index, actor)
	else:
		# Рука пуста (крайний случай) — всё равно возвращаем ход, а не подвешиваем матч.
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

	# Проверка стоимости
	if not can_afford(card, actor):
		print("Not enough resources!")
		return

	current_state = State.PROCESS_CARD

	# ARC-035: pre-play хук ДО списания стоимости — "Счастливая Монета" (10%
	# не потратить ресурсы за карту) физически не может сработать ПОСЛЕ
	# списания, как остальные триггеры артефактов (card_played и т.п. в
	# ArtifactManager._check_artifacts() срабатывают уже после розыгрыша).
	# can_afford() выше уже проверил, что actor МОГ БЫ заплатить — сам факт
	# пропуска оплаты не должен разрешать то, что иначе было бы недоступно.
	var skip_payment: bool = ArtifactManager.should_skip_payment(actor)

	# Трата ресурсов
	if not skip_payment:
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
		_apply_effect(effect, actor, enemy)

	GameEvents.resource_changed.emit(actor, "all", 0)
	GameEvents.resource_changed.emit(enemy, "all", 0)


## ARC-021: применение одного эффекта из словаря. Вынесено из apply_card_effects()
## в отдельную функцию, чтобы "conditional" мог рекурсивно применить вложенный
## под-эффект (ветка "then"/"else") тем же кодом, без дублирования match'а.
func _apply_effect(effect: Dictionary, actor: PlayerData, enemy: PlayerData) -> void:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)
	var target_str = effect.get("target", "enemy")

	var target_player = resolve_target(actor, enemy, target_str)

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
			# ARC-020: генератор не может уйти в минус (cards_list.md, "Заметка по
			# реализации" — карты «порчи генераторов» вроде Порчи Карьера/
			# Разрушения Основ используют отрицательный value поверх этого же типа).
			target_player.quarry = max(0, target_player.quarry + value)
		"mod_magic":
			target_player.magic = max(0, target_player.magic + value)
		"mod_dungeon":
			target_player.dungeon = max(0, target_player.dungeon + value)
		"draw_card":
			# value — сколько карт тянет target_player (обычно "self").
			for i in range(value):
				draw_card(target_player)
		"steal_resource":
			# target_str резолвит, у КОГО крадём (обычно "enemy") — получает
			# всегда actor, симметрично "украсть N Х у врага".
			_apply_steal_resource(effect, target_player, actor)
		"conditional":
			_apply_conditional(effect, target_player, actor, enemy)
		"gain_resource":
			# ARC-020: {"type": "gain_resource", "target": "self", "resource": "bricks",
			# "value": N} — мгновенное +N ресурса target_player'у, без второй стороны
			# (в отличие от steal_resource). Нужен для Rare-карт вида "Генератор X +5,
			# сразу +5 X" (Гномья шахта/Архимаг/Логово альфы) — сам генератор растится
			# отдельным mod_quarry/magic/dungeon эффектом в той же карте.
			_modify_resource(target_player, effect.get("resource", ""), value)
		"drain_resource":
			# ARC-020: {"type": "drain_resource", "target": "enemy", "resource": "bricks",
			# "value": N} — забирает min(N, доступно) ресурса у target_player, но, в
			# отличие от steal_resource, никому не отдаёт (чистое "проклятие", не кража).
			var drain_amount: int = min(
				value, _get_resource(target_player, effect.get("resource", ""))
			)
			if drain_amount > 0:
				_modify_resource(target_player, effect.get("resource", ""), -drain_amount)
		"reduce_wall":
			# ARC-020: {"type": "reduce_wall", "target": "enemy", "value": N} — плоское
			# -N к wall_hp, без перелива в tower_hp (в отличие от "damage"). Нужен для
			# карт вида "Стена врага −N" как вторичный эффект (Гидра, Дракон).
			target_player.wall_hp = max(0, target_player.wall_hp - value)


## ARC-021: {"type": "steal_resource", "target": "enemy", "resource": "gems", "value": N}
## Крадёт min(N, доступно у from) ресурса resource у from, отдаёт ровно столько же to —
## нельзя увести ресурс в минус и нельзя украсть больше, чем реально есть.
## ARC-020: resource == "random" — тип ресурса выбирается случайно в момент розыгрыша
## (нужно карте "Кража времени": "украсть 5 любого ресурса врага, тот же ресурс приходит вам" —
## "любой" в данных не фиксируется заранее, а бросается при применении эффекта).
func _apply_steal_resource(
	effect: Dictionary, from_player: PlayerData, to_player: PlayerData
) -> void:
	var resource_name: String = effect.get("resource", "")
	if resource_name == "random":
		resource_name = RESOURCE_NAMES[randi() % RESOURCE_NAMES.size()]
	var value: int = effect.get("value", 0)
	var amount: int = min(value, _get_resource(from_player, resource_name))
	if amount <= 0:
		return
	_modify_resource(from_player, resource_name, -amount)
	_modify_resource(to_player, resource_name, amount)


func _get_resource(player: PlayerData, resource_name: String) -> int:
	match resource_name:
		"bricks":
			return player.bricks
		"gems":
			return player.gems
		"beasts":
			return player.beasts
	return 0


func _modify_resource(player: PlayerData, resource_name: String, delta: int) -> void:
	match resource_name:
		"bricks":
			player.bricks += delta
		"gems":
			player.gems += delta
		"beasts":
			player.beasts += delta


## ARC-021: {"type": "conditional", "target": "self", "field": "wall_hp", "op": "<",
## "threshold": 3, "then": {...эффект...}, "else": {...эффект...}}. target/field
## резолвятся к тому же target_player, что и остальные эффекты (см. _apply_effect) —
## условие всегда проверяется на нём, а не отдельно на actor/enemy. Вложенные
## "then"/"else" — обычные словари эффекта со своим собственным target (может
## отличаться от условия, например «если твоя Стена < 3 — урони Стену врага»).
func _apply_conditional(
	effect: Dictionary, condition_target: PlayerData, actor: PlayerData, enemy: PlayerData
) -> void:
	var field: String = effect.get("field", "")
	var op: String = effect.get("op", "<")
	var threshold = effect.get("threshold", 0)

	var field_value = _get_field(condition_target, field)
	var branch_key: String = "then" if _evaluate_condition(field_value, op, threshold) else "else"
	var branch: Dictionary = effect.get(branch_key, {})
	if not branch.is_empty():
		_apply_effect(branch, actor, enemy)


## ARC-084 (gdlint max-returns): один return вместо восьми — значение
## собирается словарём-таблицей и отдаётся один раз, логика не изменилась.
func _get_field(player: PlayerData, field_name: String):
	var fields := {
		"wall_hp": player.wall_hp,
		"tower_hp": player.tower_hp,
		"bricks": player.bricks,
		"gems": player.gems,
		"beasts": player.beasts,
		"quarry": player.quarry,
		"magic": player.magic,
		"dungeon": player.dungeon,
	}
	return fields.get(field_name, 0)


## ARC-084 (gdlint max-returns): один return вместо семи — результат копится в
## переменную внутри match, отдаётся один раз в конце, логика не изменилась.
func _evaluate_condition(value, op: String, threshold) -> bool:
	var result := false
	match op:
		"<":
			result = value < threshold
		"<=":
			result = value <= threshold
		">":
			result = value > threshold
		">=":
			result = value >= threshold
		"==":
			result = value == threshold
		"!=":
			result = value != threshold
	return result


## ARC-005: единая точка резолва `target` из словаря эффекта карты/артефакта в
## конкретного PlayerData. Учитывается только префикс "self"/"enemy" — суффикс
## `_wall`/`_tower` (например, "enemy_wall") ни на что здесь не влияет и для
## большинства типов эффекта чисто описательный, см. docs/effects_reference.md.
func resolve_target(actor: PlayerData, enemy: PlayerData, target_str: String) -> PlayerData:
	if target_str.begins_with("self"):
		return actor
	return enemy


## ARC-030: source (необязательный, по умолчанию null) — кто нанёс урон,
## пробрасывается в GameEvents.damage_applied для ArtifactManager (триггер
## "on_damage_taken", нужен Шипастой Стене — ARC-031, знать, кому отвечать).
## Оба реальных вызова из _apply_effect() передают actor; вызовы без source
## (тесты, потенциальный будущий "урон от ловушки/эффекта без владельца")
## просто не дадут сработать эффектам с типом "reflect_damage".
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

	# ARC-004: damage_applied несёт положительный amount — знак больше не нужен,
	# т.к. само имя сигнала уже говорит "это урон".
	var hit_wall = not ignore_wall
	GameEvents.damage_applied.emit(target, amount, hit_wall, source)


## ARC-084: помимо winner, теперь определяет и записывает в last_win_reason/
## last_win_resource ЗА СЧЁТ ЧЕГО именно произошла победа — нужно
## tools/battle_simulator.gd для профилирования (были запросы: "по ресурсам
## (по какому ресурсу), по высоте башни, по уничтожению башни противника").
## Приоритет проверки при теоретическом одновременном срабатывании нескольких
## условий за один вызов (на практике почти невозможно — один apply_card_
## effects() обычно двигает только одну ось): сначала уничтожение башни
## врага, затем собственная высота башни, затем ресурсы — уничтожение
## приоритетнее как более "прямое" и мгновенное завершение партии.
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
