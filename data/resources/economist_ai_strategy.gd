class_name EconomistAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Экономическая стратегия ИИ.


func _score_effect(effect: Dictionary, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)
	var priority = 0.0

	if type == "mod_magic":
		priority += value * 8.0

	elif type == "steal_resource" or type == "drain_resource":
		priority += value * 6.0

	elif type == "gain_resource":
		priority += value * 5.0

	elif type == "draw_card":
		priority += value * 4.0

	elif type == "mod_quarry" or type == "mod_dungeon":
		priority += value * 1.0

	elif type == "build_wall":
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	elif type == "damage" or type == "direct_damage":
		priority += value * 0.3 * (100.0 / max(1.0, player_enemy.tower_hp))
	elif type == "build_tower":
		priority += value * 0.5

	elif type == "reduce_wall":
		priority += value * 0.3

	elif type == "conditional":
		var branch: Dictionary = resolve_conditional_branch(effect, player_actor, player_enemy)
		if not branch.is_empty():
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
