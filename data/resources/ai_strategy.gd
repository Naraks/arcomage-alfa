class_name AIStrategy
extends Resource
## Базовый интерфейс и общие оценки стратегий ИИ.


func get_best_card(hand: Array[CardData], actor: Resource, enemy: Resource) -> CardData:
	var player_actor: PlayerData = actor as PlayerData
	var player_enemy: PlayerData = enemy as PlayerData
	var affordable_cards: Array = hand.filter(func(c): return can_afford(c, player_actor))

	if affordable_cards.is_empty():
		return null

	var best_card: CardData = null
	var highest_weight := -9999.0

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


func _score_effect(effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	if not effect.type in EffectType.CARD_TYPES:
		push_warning(
			"AIStrategy: неизвестный тип эффекта карты '%s' в _score_effect" % effect.type
		)
	return _score_known_effect(effect, player_actor, player_enemy)


func _score_known_effect(
	_effect: EffectData, _player_actor: PlayerData, _player_enemy: PlayerData
) -> float:
	return 0.0


func can_afford(card: CardData, actor: Resource) -> bool:
	return EffectUtils.can_afford(card, actor as PlayerData)


func resolve_target(actor: Resource, enemy: Resource, target_str: String) -> Resource:
	return EffectUtils.resolve_target(actor as PlayerData, enemy as PlayerData, target_str)


func _get_field(player: Resource, field_name: String):
	return EffectUtils.get_field(player as PlayerData, field_name)


func _evaluate_condition(value, op: String, threshold) -> bool:
	return EffectUtils.evaluate_condition(value, op, threshold)


func resolve_conditional_branch(effect: EffectData, actor: Resource, enemy: Resource) -> EffectData:
	return EffectUtils.resolve_conditional_branch(effect, actor as PlayerData, enemy as PlayerData)
