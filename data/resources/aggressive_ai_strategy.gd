class_name AggressiveAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Атакующая стратегия ИИ.


func _score_effect(effect: EffectData, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type := effect.type
	var value := effect.value
	var priority: float = 0.0

	if type == "damage" or type == "direct_damage":
		priority += value * max(2.5, 200.0 / max(1.0, player_enemy.tower_hp))

	if type == "build_wall":
		priority += value * 0.5 * (1.0 - (player_actor.wall_hp / 100.0))

	if "add_" in type or "mod_" in type:
		priority += value * 0.5

	if type == "reduce_wall":
		priority += value * 1.5

	if type == "steal_resource" or type == "drain_resource":
		priority += value * 1.5

	if type == "gain_resource" or type == "draw_card":
		priority += value * 1.0

	if type == "conditional":
		var branch: EffectData = resolve_conditional_branch(effect, player_actor, player_enemy)
		if branch:
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
