class_name ArtifactManager
extends Node


func _ready() -> void:
	GameEvents.card_played.connect(_on_card_played)
	GameEvents.turn_started.connect(_on_turn_started)


func _on_card_played(_card: CardData, player: PlayerData) -> void:
	_check_artifacts(player, "card_played")


func _on_turn_started(player: PlayerData) -> void:
	_check_artifacts(player, "turn_started")


func _check_artifacts(player: PlayerData, trigger_type: String) -> void:
	for artifact in player.active_artifacts:
		for effect in artifact.effects:
			if effect.get("trigger") == trigger_type:
				apply_artifact_effect(artifact, effect, player)


func apply_artifact_effect(artifact: ArtifactData, effect: Dictionary, player: PlayerData) -> void:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)

	match type:
		"mod_quarry":
			player.quarry += value
		"mod_magic":
			player.magic += value
		"mod_dungeon":
			player.dungeon += value
		"build_wall":
			player.wall_hp += value
			GameEvents.value_built.emit(player, value, "wall")
		"build_tower":
			player.tower_hp += value
			GameEvents.value_built.emit(player, value, "tower")

	# Обновляем UI, если нужно
	GameEvents.resource_changed.emit(player, "all", 0)

	GameEvents.artifact_triggered.emit(artifact, player)
	print("[DEBUG] Artifact triggered: ", artifact.artifact_name, " effect: ", type)
