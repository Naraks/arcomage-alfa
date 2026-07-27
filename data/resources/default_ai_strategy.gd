extends "res://data/resources/ai_strategy.gd"
class_name DefaultAIStrategy

func get_best_card(hand: Array[CardData], actor: Resource, enemy: Resource) -> CardData:
	var player_actor: PlayerData = actor as PlayerData
	var player_enemy: PlayerData = enemy as PlayerData
	var affordable_cards: Array = hand.filter(func(c): return can_afford(c, player_actor))
	
	if affordable_cards.is_empty():
		return null
		
	var best_card = null
	var highest_weight = -9999
	
	for card in affordable_cards:
		var weight: float = calculate_card_priority(card, player_actor, player_enemy)
		if weight > highest_weight:
			highest_weight = weight
			best_card = card
			
	return best_card

func calculate_card_priority(card: CardData, actor: Resource, enemy: Resource) -> float:
	var player_actor: PlayerData = actor as PlayerData
	var player_enemy: PlayerData = enemy as PlayerData
	var priority: float = 0.0
	
	for effect in card.effects:
		var type = effect.get("type", "")
		var value = effect.get("value", 0)
		
		# Приоритет урона
		if type == "damage":
			# Если стена врага высока, урон менее эффективен
			var wall_multiplier = 1.0 - (player_enemy.wall_hp / 50.0)
			priority += value * max(0.5, wall_multiplier) * (100.0 / max(1.0, player_enemy.tower_hp))
		
		if type == "direct_damage":
			priority += value * (100.0 / max(1.0, player_enemy.tower_hp)) * 1.5
		
		# Приоритет защиты
		if type == "build_wall" or (type == "build" and effect.get("target") == "self_wall"):
			priority += value * (1.0 - (player_actor.wall_hp / 50.0))
		
		if type == "build_tower" or (type == "build" and effect.get("target") == "self_tower"):
			priority += value * (0.5 + (player_actor.tower_hp / 100.0))

		# Приоритет экономики
		if "mod_" in type:
			priority += value * 10.0
			
	return priority
