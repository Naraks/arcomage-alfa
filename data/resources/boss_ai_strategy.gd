class_name BossAIStrategy
extends "res://data/resources/ai_strategy.gd"
## ARC-027: "отдельная скриптованная гибридная стратегия" для босса — в
## отличие от Default/Aggressive/Builder/Economist (ARC-005/025/026), это не
## свой набор весов в calculate_card_priority(), а явное (скриптованное)
## переключение между уже существующими AggressiveAIStrategy и
## BuilderAIStrategy по порогам угрозы поражения/окна для добивания. Решение
## пересчитывается заново на каждый вызов (stateless) от актуального
## tower_hp actor/enemy — никакого отдельного состояния "текущий режим" не
## хранится между ходами.
##
## Правила переключения:
## - Если tower_hp врага (enemy) уже заметно ниже стартовых значений
##   (LETHAL_ENEMY_TOWER_HP) — режим AggressiveAIStrategy: добивать, пока есть
##   окно, а не откладывать урон на потом ради экономики, которая не успеет
##   окупиться до конца боя.
## - Иначе если сам босс (actor) под угрозой поражения (DANGER_OWN_TOWER_HP) —
##   тоже AggressiveAIStrategy: логика "бей в ответ, пока не поздно" вместо
##   пассивной постройки экономики.
## - Иначе (ни угрозы, ни лёгкой добычи) — BuilderAIStrategy: играть в долгую,
##   наращивать Башню/генераторы — босс должен ощущаться так, будто он
##   перерастает игрока по ходу боя, а не просто спамит урон с первого хода.
##
## Пороги — стартовая, не откалиброванная симулятором величина (как и бонусы
## ARC-017): PlayerData.tower_hp по умолчанию = 20 (см. tests/fixtures.gd),
## поэтому LETHAL_ENEMY_TOWER_HP заметно ниже — иначе режим "добивать" включался
## бы с первого хода, ещё до того, как игрок вообще потерял Башню. Босс
## получает BOSS_TOWER_BONUS = 20 (world_map_screen.gd) поверх базовых 20, т.е.
## типичный старт ~40 — DANGER_OWN_TOWER_HP заметно ниже половины этого запаса.

const LETHAL_ENEMY_TOWER_HP := 8
const DANGER_OWN_TOWER_HP := 15

var _aggressive := AggressiveAIStrategy.new()
var _builder := BuilderAIStrategy.new()


func _pick_delegate(actor: PlayerData, enemy: PlayerData) -> AIStrategy:
	if enemy.tower_hp <= LETHAL_ENEMY_TOWER_HP:
		return _aggressive
	if actor.tower_hp <= DANGER_OWN_TOWER_HP:
		return _aggressive
	return _builder


func get_best_card(hand: Array[CardData], actor: Resource, enemy: Resource) -> CardData:
	var player_actor: PlayerData = actor as PlayerData
	var player_enemy: PlayerData = enemy as PlayerData
	return _pick_delegate(player_actor, player_enemy).get_best_card(hand, actor, enemy)


func calculate_card_priority(card: CardData, actor: Resource, enemy: Resource) -> float:
	var player_actor: PlayerData = actor as PlayerData
	var player_enemy: PlayerData = enemy as PlayerData
	return _pick_delegate(player_actor, player_enemy).calculate_card_priority(card, actor, enemy)
