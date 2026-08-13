class_name TestFixtures
extends RefCounted
## Общие тестовые фикстуры.


static func make_player(overrides: Dictionary = {}) -> PlayerData:
	var player := PlayerData.new()
	player.tower_hp = 20
	player.wall_hp = 5
	player.bricks = 5
	player.gems = 5
	player.beasts = 5
	player.quarry = 1
	player.magic = 1
	player.dungeon = 1
	player.max_hand_size = 5
	for key in overrides:
		player.set(key, overrides[key])
	return player


static func make_card(
	cost: int, type: CardData.ResourceType, effects: Array[Dictionary] = []
) -> CardData:
	var card := CardData.new()
	card.cost = cost
	card.type = type
	card.effects = _to_effect_data(effects)
	return card


static func make_artifact(effects: Array[Dictionary] = []) -> ArtifactData:
	var artifact := ArtifactData.new()
	artifact.effects = _to_effect_data(effects)
	return artifact


static func _to_effect_data(dict_effects: Array[Dictionary]) -> Array[EffectData]:
	var result: Array[EffectData] = []
	for d in dict_effects:
		result.append(EffectData.from_dict(d))
	return result
