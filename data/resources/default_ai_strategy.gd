class_name DefaultAIStrategy
extends "res://data/resources/ai_strategy.gd"
## Сбалансированная стратегия ИИ.


func _score_effect(effect: Dictionary, player_actor: PlayerData, player_enemy: PlayerData) -> float:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)
	var priority: float = 0.0

	if type == "damage":
		var wall_multiplier = 1.0 - (player_enemy.wall_hp / 50.0)
		priority += value * max(0.5, wall_multiplier) * (100.0 / max(1.0, player_enemy.tower_hp))

	if type == "direct_damage":
		priority += value * (100.0 / max(1.0, player_enemy.tower_hp)) * 1.5

	if type == "build_wall":
		priority += value * (1.0 - (player_actor.wall_hp / 50.0))

	if type == "build_tower":
		priority += value * (0.5 + (player_actor.tower_hp / 100.0))

	if "mod_" in type:
		priority += value * 10.0

	if type == "reduce_wall":
		priority += value * 1.0

	if type == "gain_resource":
		priority += value * 3.0

	if type == "steal_resource":
		priority += value * 4.0

	if type == "drain_resource":
		priority += value * 2.5

	if type == "draw_card":
		priority += value * 3.0

	if type == "conditional":
		var branch: Dictionary = resolve_conditional_branch(effect, player_actor, player_enemy)
		if not branch.is_empty():
			priority += _score_effect(branch, player_actor, player_enemy)

	return priority
