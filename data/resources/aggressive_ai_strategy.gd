class_name AggressiveAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Атакующая стратегия ИИ.


func _score_known_effect(
	effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData
) -> float:
	var type := effect.type
	var value := effect.value
	var priority: float = 0.0

	if type == EffectType.Type.DAMAGE or type == EffectType.Type.DIRECT_DAMAGE:
		priority += value * max(2.5, 200.0 / max(1.0, player_enemy.tower_hp))

	if type == EffectType.Type.BUILD_WALL:
		priority += value * 0.5 * (1.0 - (player_actor.wall_hp / 100.0))

	if type in EffectType.MOD_TYPES:
		priority += value * 0.5

	if type == EffectType.Type.REDUCE_WALL:
		priority += value * 1.5

	if type == EffectType.Type.STEAL_RESOURCE or type == EffectType.Type.DRAIN_RESOURCE:
		priority += value * 1.5

	if type == EffectType.Type.GAIN_RESOURCE or type == EffectType.Type.DRAW_CARD:
		priority += value * 1.0

	if type == EffectType.Type.CONDITIONAL:
		var branch: EffectData = resolve_conditional_branch(effect, player_actor, player_enemy)
		if branch:
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
