extends Node
## Применение эффектов артефактов по игровым событиям.

const RESOURCE_NAMES := ["bricks", "gems", "beasts"]

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
			if effect.get("trigger") == trigger_type:
				apply_artifact_effect(artifact, effect, player, context)


func apply_artifact_effect(
	artifact: ArtifactData, effect: Dictionary, player: PlayerData, context: Dictionary = {}
) -> void:
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
		"gain_resource":
			if effect.has("requires_card_type"):
				var played_card = context.get("card")
				if not played_card or played_card.type != effect["requires_card_type"]:
					return
			_modify_resource(player, effect.get("resource", ""), value)
		"set_generator_level":
			player.quarry = max(player.quarry, value)
			player.magic = max(player.magic, value)
			player.dungeon = max(player.dungeon, value)
		"set_max_hand_size":
			player.max_hand_size = max(player.max_hand_size, value)
		"reflect_damage":
			if not context.get("hit_wall", false):
				return
			var attacker := context.get("attacker") as PlayerData
			if attacker:
				_reflecting = true
				MatchManager.apply_damage(value, attacker, true)
				_reflecting = false

	GameEvents.resource_changed.emit(player, "all", 0)

	GameEvents.artifact_triggered.emit(artifact, player)
	print("[DEBUG] Artifact triggered: ", artifact.artifact_name, " effect: ", type)


func _modify_resource(player: PlayerData, resource_name: String, delta: int) -> void:
	match resource_name:
		"bricks":
			player.bricks += delta
		"gems":
			player.gems += delta
		"beasts":
			player.beasts += delta


func should_skip_payment(player: PlayerData) -> bool:
	for artifact in player.active_artifacts:
		for effect in artifact.effects:
			if effect.get("trigger") == "pre_play" and effect.get("type") == "skip_payment_chance":
				var chance: float = effect.get("value", 0.0)
				if randf() < chance:
					GameEvents.artifact_triggered.emit(artifact, player)
					return true
	return false
