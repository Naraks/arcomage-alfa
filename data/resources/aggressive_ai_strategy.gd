class_name AggressiveAIStrategy
extends "res://data/resources/ai_strategy.gd"


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
		var type = effect.get("type", "")
		var value = effect.get("value", 0)

		# Агрессивный ИИ: Урон намного важнее
		if type == "damage" or type == "direct_damage":
			priority += value * (200.0 / max(1.0, player_enemy.tower_hp))

		# Защита менее важна (ARC-005: generic-тип "build" убран, остался только build_wall)
		if type == "build_wall":
			priority += value * 0.5 * (1.0 - (player_actor.wall_hp / 100.0))

		# Экономика менее важна
		if "add_" in type or "mod_" in type:
			priority += value * 2.0

	return priority
