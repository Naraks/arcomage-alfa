class_name BuilderAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Строительная стратегия ИИ.


func _score_effect(effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type := effect.type
	var value := effect.value
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
		var branch: EffectData = resolve_conditional_branch(effect, player_actor, player_enemy)
		if branch:
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
