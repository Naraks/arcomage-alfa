class_name BuilderAIStrategy
extends "res://data/resources/ai_strategy.gd"
## ARC-025: профиль ИИ «Строитель» — приоритизирует рост собственной Башни и
## добычу Кирпичей над атакой. Тот же каркас get_best_card()/
## calculate_card_priority(), что и в default_ai_strategy.gd/
## aggressive_ai_strategy.gd (ARC-005/ARC-025-026), различаются только веса
## внутри calculate_card_priority().


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

		# Рост своей Башни — главный приоритет Строителя.
		if type == "build_tower":
			priority += value * 5.0

		# Добыча Кирпичей — приоритет ещё выше build_tower: "рост через
		# кирпичи" буквально из описания тикета, а не экономика вообще
		# (mod_magic/mod_dungeon ниже, см. блок "прочая экономика").
		elif type == "mod_quarry":
			priority += value * 8.0

		# Стену всё равно строит — иначе Башню снесут раньше, чем она
		# успеет вырасти — но не в приоритете над build_tower/mod_quarry.
		elif type == "build_wall":
			priority += value * (1.0 - (player_actor.wall_hp / 50.0))

		# Атака — не его игра: Строитель разыгрывает урон только если больше
		# нечего делать (низкий, но не нулевой вес — карту в руке всё равно
		# лучше сыграть, чем придержать просто так).
		elif type == "damage" or type == "direct_damage":
			priority += value * 0.3 * (100.0 / max(1.0, player_enemy.tower_hp))

		# Прочая экономика (Гемы/Звери) — не его специализация, но не ноль.
		elif type == "mod_magic" or type == "mod_dungeon":
			priority += value * 1.0

	return priority
