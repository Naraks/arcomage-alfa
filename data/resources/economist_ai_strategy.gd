class_name EconomistAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Экономическая стратегия ИИ.


func _score_known_effect(
	effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData
) -> float:
	var type := effect.type
	var value := effect.value
	var priority: float = 0.0

	if type == EffectType.Type.MOD_MAGIC:
		priority += value * 8.0

	elif type == EffectType.Type.STEAL_RESOURCE or type == EffectType.Type.DRAIN_RESOURCE:
		priority += value * 6.0

	elif type == EffectType.Type.GAIN_RESOURCE:
		priority += value * 5.0

	elif type == EffectType.Type.DRAW_CARD:
		priority += value * 4.0

	elif type == EffectType.Type.MOD_QUARRY or type == EffectType.Type.MOD_DUNGEON:
		priority += value * 1.0

	elif type == EffectType.Type.BUILD_WALL:
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	elif type == EffectType.Type.DAMAGE or type == EffectType.Type.DIRECT_DAMAGE:
		priority += value * 0.3 * (100.0 / max(1.0, player_enemy.tower_hp))
	elif type == EffectType.Type.BUILD_TOWER:
		priority += value * 0.5

	elif type == EffectType.Type.REDUCE_WALL:
		priority += value * 0.3

	elif type == EffectType.Type.CONDITIONAL:
		var branch: EffectData = resolve_conditional_branch(effect, player_actor, player_enemy)
		if branch:
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
