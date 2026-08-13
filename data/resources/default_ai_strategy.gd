class_name DefaultAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Сбалансированная стратегия ИИ.


func _score_effect(effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type := effect.type
	var value := effect.value
	var priority: float = 0.0

	if type == EffectType.Type.DAMAGE:
		var wall_multiplier = 1.0 - (player_enemy.wall_hp / 50.0)
		priority += value * max(0.5, wall_multiplier) * (100.0 / max(1.0, player_enemy.tower_hp))

	if type == EffectType.Type.DIRECT_DAMAGE:
		priority += value * (100.0 / max(1.0, player_enemy.tower_hp)) * 1.5

	if type == EffectType.Type.BUILD_WALL:
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	if type == EffectType.Type.BUILD_TOWER:
		priority += value * (0.5 + (player_actor.tower_hp / 100.0))

	if type in EffectType.MOD_TYPES:
		priority += value * 10.0

	if type == EffectType.Type.REDUCE_WALL:
		priority += value * 1.0

	if type == EffectType.Type.GAIN_RESOURCE:
		priority += value * 3.0

	if type == EffectType.Type.STEAL_RESOURCE:
		priority += value * 4.0

	if type == EffectType.Type.DRAIN_RESOURCE:
		priority += value * 2.5

	if type == EffectType.Type.DRAW_CARD:
		priority += value * 3.0

	if type == EffectType.Type.CONDITIONAL:
		var branch: EffectData = resolve_conditional_branch(effect, player_actor, player_enemy)
		if branch:
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
