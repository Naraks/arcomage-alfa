class_name BuilderAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Строительная стратегия ИИ.


func get_best_card(hand: Array[CardData], actor: Resource, enemy: Resource) -> CardData:
	var player_actor = actor as PlayerData
	var player_enemy = enemy as PlayerData
	var affordable_cards = hand.filter(func(c): return can_afford(c, player_actor))

	if affordable_cards.is_empty():
		return null

	var best_card = null
	var highest_weight = -9999

	for card in affordable_cards:
		var weight = calculate_card_priority(card, player_actor, player_enemy)
		if weight > highest_weight:
			highest_weight = weight
			best_card = card

	return best_card


func calculate_card_priority(card: CardData, actor: Resource, enemy: Resource) -> float:
	var player_actor = actor as PlayerData
	var player_enemy = enemy as PlayerData
	var priority = 0.0

	for effect in card.effects:
		priority += _score_effect(effect, player_actor, player_enemy)

	return priority


func _score_effect(effect: Dictionary, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)
	var priority = 0.0

	if type == "build_tower":
		priority += value * 5.0

	elif type == "mod_quarry":
		priority += value * 8.0

	elif type == "build_wall":
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	elif type == "damage" or type == "direct_damage":
		priority += value * 0.3 * (100.0 / max(1.0, player_enemy.tower_hp))

	elif type == "mod_magic" or type == "mod_dungeon":
		priority += value * 1.0

	elif type == "reduce_wall":
		priority += value * 0.5

	elif (
		type == "gain_resource"
		or type == "steal_resource"
		or type == "drain_resource"
		or type == "draw_card"
	):
		priority += value * 1.0

	elif type == "conditional":
		var branch: Dictionary = resolve_conditional_branch(effect, player_actor, player_enemy)
		if not branch.is_empty():
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
