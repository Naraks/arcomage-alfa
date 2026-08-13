class_name EffectUtils
extends RefCounted
## Общая логика разбора эффектов карт/артефактов и условий ИИ.

const RESOURCE_NAMES := ["bricks", "gems", "beasts"]


static func can_afford(card: CardData, actor: PlayerData) -> bool:
	match card.type:
		CardData.ResourceType.BRICKS:
			return actor.bricks >= card.cost
		CardData.ResourceType.GEMS:
			return actor.gems >= card.cost
		CardData.ResourceType.BEASTS:
			return actor.beasts >= card.cost
	return false


static func get_resource(player: PlayerData, resource_name: String) -> int:
	match resource_name:
		"bricks":
			return player.bricks
		"gems":
			return player.gems
		"beasts":
			return player.beasts
	return 0


static func modify_resource(player: PlayerData, resource_name: String, delta: int) -> void:
	match resource_name:
		"bricks":
			player.bricks += delta
		"gems":
			player.gems += delta
		"beasts":
			player.beasts += delta
		_:
			push_warning("EffectUtils.modify_resource: неизвестный ресурс '%s'" % resource_name)


static func resolve_target(actor: PlayerData, enemy: PlayerData, target_str: String) -> PlayerData:
	if target_str.begins_with("self"):
		return actor
	return enemy


static func get_field(player: PlayerData, field_name: String):
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


static func evaluate_condition(value, op: String, threshold) -> bool:
	match op:
		"<":
			return value < threshold
		"<=":
			return value <= threshold
		">":
			return value > threshold
		">=":
			return value >= threshold
		"==":
			return value == threshold
		"!=":
			return value != threshold
		_:
			push_warning("EffectUtils.evaluate_condition: неизвестный оператор '%s'" % op)
			return false


static func resolve_conditional_branch(
	effect: Dictionary, actor: PlayerData, enemy: PlayerData
) -> Dictionary:
	var condition_target := resolve_target(actor, enemy, effect.get("target", "self"))
	var field_value = get_field(condition_target, effect.get("field", ""))
	var op: String = effect.get("op", "<")
	var threshold = effect.get("threshold", 0)
	var branch_key: String = "then" if evaluate_condition(field_value, op, threshold) else "else"
	return effect.get(branch_key, {})
