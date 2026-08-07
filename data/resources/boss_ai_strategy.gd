class_name BossAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Гибридная стратегия босса.

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
