class_name BuilderAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Строительная стратегия ИИ.


func _score_effect(effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type := effect.type
	var value := effect.value
	var priority: float = 0.0

	if type == EffectType.BUILD_TOWER:
		priority += value * 5.0

	elif type == EffectType.MOD_QUARRY:
		priority += value * 8.0

	elif type == EffectType.BUILD_WALL:
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	elif type == EffectType.DAMAGE or type == EffectType.DIRECT_DAMAGE:
		priority += value * 0.3 * (100.0 / max(1.0, player_enemy.tower_hp))

	elif type == EffectType.MOD_MAGIC or type == EffectType.MOD_DUNGEON:
		priority += value * 1.0

	elif type == EffectType.REDUCE_WALL:
		priority += value * 0.5

	elif (
		type == EffectType.GAIN_RESOURCE
		or type == EffectType.STEAL_RESOURCE
		or type == EffectType.DRAIN_RESOURCE
		or type == EffectType.DRAW_CARD
	):
		priority += value * 1.0

	elif type == EffectType.CONDITIONAL:
		var branch: EffectData = resolve_conditional_branch(effect, player_actor, player_enemy)
		if branch:
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
