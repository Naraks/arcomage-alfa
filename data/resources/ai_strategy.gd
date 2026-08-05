class_name AIStrategy
extends Resource


# Базовый класс для всех стратегий ИИ
func get_best_card(_hand: Array[CardData], _actor: Resource, _enemy: Resource) -> CardData:
	return null


func can_afford(card: CardData, actor: Resource) -> bool:
	match card.type:
		CardData.ResourceType.BRICKS:
			return actor.bricks >= card.cost
		CardData.ResourceType.GEMS:
			return actor.gems >= card.cost
		CardData.ResourceType.BEASTS:
			return actor.beasts >= card.cost
	return false


## ARC-093: зеркалит core/match_manager.gd::resolve_target() — стратегии сами
## резолвят target у вложенных then/else-эффектов "conditional", не обращаясь
## к MatchManager (Resource не должен знать про autoload-синглтон боя).
func resolve_target(actor: Resource, enemy: Resource, target_str: String) -> Resource:
	if target_str.begins_with("self"):
		return actor
	return enemy


## ARC-093: зеркалит core/match_manager.gd::_get_field().
func _get_field(player: Resource, field_name: String):
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


## ARC-093: зеркалит core/match_manager.gd::_evaluate_condition().
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


## ARC-093: по образцу core/match_manager.gd::_apply_conditional() — определяет,
## какая ветка ("then"/"else") реально сработает у эффекта "conditional" при
## текущем actor/enemy, чтобы стратегия могла рекурсивно оценить её приоритет
## вместо того, чтобы считать сам "conditional" непрозрачным нулём.
func resolve_conditional_branch(effect: Dictionary, actor: Resource, enemy: Resource) -> Dictionary:
	var condition_target: Resource = resolve_target(actor, enemy, effect.get("target", "self"))
	var field_value = _get_field(condition_target, effect.get("field", ""))
	var op: String = effect.get("op", "<")
	var threshold = effect.get("threshold", 0)
	var branch_key: String = "then" if _evaluate_condition(field_value, op, threshold) else "else"
	return effect.get(branch_key, {})
