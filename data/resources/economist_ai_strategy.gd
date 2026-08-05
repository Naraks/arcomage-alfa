class_name EconomistAIStrategy
extends "res://data/resources/ai_strategy.gd"
## ARC-026: профиль ИИ «Маг/Экономист» — приоритизирует манипуляции
## ресурсами (свой рост, кража/порча ресурсов врага, добор карт) над прямой
## атакой или защитой. Тот же каркас get_best_card()/calculate_card_priority(),
## что и в default_ai_strategy.gd/aggressive_ai_strategy.gd/
## builder_ai_strategy.gd — различаются только веса.


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


## ARC-093: вынесено из calculate_card_priority(), чтобы "conditional" мог
## рекурсивно оценить вложенный then/else-эффект той же весовой таблицей.
func _score_effect(effect: Dictionary, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)
	var priority = 0.0

	# Добыча Гемов — главная специализация (описание тикета: "карты гемов").
	if type == "mod_magic":
		priority += value * 8.0

	# Кража/порча ресурсов врага (ARC-020/021) — прямое попадание в
	# описание тикета: "включая будущие эффекты кражи ресурсов".
	elif type == "steal_resource" or type == "drain_resource":
		priority += value * 6.0

	# Мгновенный прирост ресурса (ARC-020) — тоже "манипуляция ресурсами".
	elif type == "gain_resource":
		priority += value * 5.0

	# Добор карт — тоже экономика (карта в руке = будущая опция).
	elif type == "draw_card":
		priority += value * 4.0

	# Прочие генераторы — не специализация, но не ноль.
	elif type == "mod_quarry" or type == "mod_dungeon":
		priority += value * 1.0

	# Оборона — как у остальных стратегий, не в приоритете, но нужна.
	elif type == "build_wall":
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	# Атака и рост Башни — не его игра, низкий вес (то же соотношение,
	# что у Строителя для "не своей" механики).
	elif type == "damage" or type == "direct_damage":
		priority += value * 0.3 * (100.0 / max(1.0, player_enemy.tower_hp))
	elif type == "build_tower":
		priority += value * 0.5

	# ARC-093: не его специализация, но снятие Стены врага всё же облегчает
	# урон — тот же низкий вес, что у остальной "не своей" механики.
	elif type == "reduce_wall":
		priority += value * 0.3

	# ARC-093: выбираем реально применимую ветку по текущему состоянию и
	# считаем её приоритет рекурсивно — "conditional" сам по себе не эффект.
	elif type == "conditional":
		var branch: Dictionary = resolve_conditional_branch(effect, player_actor, player_enemy)
		if not branch.is_empty():
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
