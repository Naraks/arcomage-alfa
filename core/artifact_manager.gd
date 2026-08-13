extends Node
## Применение эффектов артефактов по игровым событиям.

var _reflecting := false


func _ready() -> void:
	GameEvents.card_played.connect(_on_card_played)
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.match_started.connect(_on_match_started)
	GameEvents.damage_applied.connect(_on_damage_taken)


func _on_card_played(card: CardData, player: PlayerData) -> void:
	_check_artifacts(player, "card_played", {"card": card})


func _on_turn_started(player: PlayerData) -> void:
	_check_artifacts(player, "turn_started")


func _on_match_started(player: PlayerData, enemy: PlayerData) -> void:
	_check_artifacts(player, "match_started")
	_check_artifacts(enemy, "match_started")


func _on_damage_taken(target: Resource, amount: int, hit_wall: bool, source: Resource) -> void:
	if _reflecting:
		return
	var player_target := target as PlayerData
	if not player_target:
		return
	_check_artifacts(
		player_target,
		"on_damage_taken",
		{"amount": amount, "hit_wall": hit_wall, "attacker": source}
	)


func _check_artifacts(player: PlayerData, trigger_type: String, context: Dictionary = {}) -> void:
	for artifact in player.active_artifacts:
		for effect in artifact.effects:
			if effect.trigger == trigger_type:
				apply_artifact_effect(artifact, effect, player, context)


func apply_artifact_effect(
	artifact: ArtifactData, effect: EffectData, player: PlayerData, context: Dictionary = {}
) -> void:
	var type := effect.type
	var value := effect.value

	match type:
		EffectType.Type.MOD_QUARRY:
			player.quarry += value
		EffectType.Type.MOD_MAGIC:
			player.magic += value
		EffectType.Type.MOD_DUNGEON:
			player.dungeon += value
		EffectType.Type.BUILD_WALL:
			player.wall_hp += value
			GameEvents.value_built.emit(player, value, "wall")
		EffectType.Type.BUILD_TOWER:
			player.tower_hp += value
			GameEvents.value_built.emit(player, value, "tower")
		EffectType.Type.GAIN_RESOURCE:
			if effect.requires_card_type != -1:
				var played_card = context.get("card")
				if not played_card or played_card.type != effect.requires_card_type:
					return
			_modify_resource(player, effect.resource, value)
		EffectType.Type.SET_GENERATOR_LEVEL:
			player.quarry = max(player.quarry, value)
			player.magic = max(player.magic, value)
			player.dungeon = max(player.dungeon, value)
		EffectType.Type.SET_MAX_HAND_SIZE:
			player.max_hand_size = max(player.max_hand_size, value)
		EffectType.Type.REFLECT_DAMAGE:
			if not context.get("hit_wall", false):
				return
			var attacker := context.get("attacker") as PlayerData
			if attacker:
				_reflecting = true
				MatchManager.apply_damage(value, attacker, true)
				_reflecting = false
		_:
			push_warning("ArtifactManager: неизвестный тип эффекта артефакта '%s'" % type)

	GameEvents.resource_changed.emit(player, "all", 0)

	GameEvents.artifact_triggered.emit(artifact, player)


func _modify_resource(player: PlayerData, resource_name: String, delta: int) -> void:
	EffectUtils.modify_resource(player, resource_name, delta)


func should_skip_payment(player: PlayerData) -> bool:
	for artifact in player.active_artifacts:
		for effect in artifact.effects:
			if effect.trigger == "pre_play" and effect.type == EffectType.Type.SKIP_PAYMENT_CHANCE:
				if randf() < effect.chance:
					GameEvents.artifact_triggered.emit(artifact, player)
					return true
	return false
