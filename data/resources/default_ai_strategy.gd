class_name DefaultAIStrategy
extends "res://data/resources/ai_strategy.gd"


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
		priority += _score_effect(effect, player_actor, player_enemy)

	return priority


## ARC-093: вынесено из calculate_card_priority(), чтобы "conditional" мог
## рекурсивно оценить вложенный then/else-эффект той же весовой таблицей.
func _score_effect(effect: Dictionary, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)
	var priority: float = 0.0

	# Приоритет урона
	if type == "damage":
		# Если стена врага высока, урон менее эффективен
		var wall_multiplier = 1.0 - (player_enemy.wall_hp / 50.0)
		priority += value * max(0.5, wall_multiplier) * (100.0 / max(1.0, player_enemy.tower_hp))

	if type == "direct_damage":
		priority += value * (100.0 / max(1.0, player_enemy.tower_hp)) * 1.5

	# Приоритет защиты (ARC-005: generic-тип "build" убран, остались только build_wall/build_tower)
	if type == "build_wall":
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	if type == "build_tower":
		priority += value * (0.5 + (player_actor.tower_hp / 100.0))

	# Приоритет экономики
	if "mod_" in type:
		priority += value * 10.0

	# ARC-093: снятие Стены врага облегчает будущий урон — не игнорировать.
	if type == "reduce_wall":
		priority += value * 1.0

	# ARC-093: раньше эти четыре типа не оценивались вовсе (вес 0) — ИИ
	# физически не мог предпочесть эти карты ничему. Кража весит больше
	# чистого приобретения (вредит и врагу), drain — чуть меньше steal
	# (никому не отдаёт, чистый минус без выгоды себе).
	if type == "gain_resource":
		priority += value * 3.0

	if type == "steal_resource":
		priority += value * 4.0

	if type == "drain_resource":
		priority += value * 2.5

	if type == "draw_card":
		priority += value * 3.0

	# ARC-093: выбираем реально применимую ветку по текущему состоянию и
	# считаем её приоритет рекурсивно — "conditional" сам по себе не эффект.
	if type == "conditional":
		var branch: Dictionary = resolve_conditional_branch(effect, player_actor, player_enemy)
		if not branch.is_empty():
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
