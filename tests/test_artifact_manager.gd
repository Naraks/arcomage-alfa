extends GutTest
## Юнит-тесты ArtifactManager (ARC-073). ArtifactManager не autoload — каждый
## тест создаёт свой экземпляр через autofree(), не добавляя его в дерево
## сцены (это не нужно для прямых вызовов apply_artifact_effect/_check_artifacts).

var manager: ArtifactManager
var player: PlayerData


func before_each() -> void:
	manager = autofree(ArtifactManager.new())
	player = PlayerData.new()
	player.quarry = 1
	player.magic = 1
	player.dungeon = 1
	player.wall_hp = 5
	player.tower_hp = 20


func _make_artifact(effects: Array[Dictionary]) -> ArtifactData:
	var artifact := ArtifactData.new()
	artifact.effects = effects
	return artifact


# --- apply_artifact_effect ---


func test_apply_artifact_effect_mod_quarry() -> void:
	manager.apply_artifact_effect(_make_artifact([]), {"type": "mod_quarry", "value": 2}, player)
	assert_eq(player.quarry, 3, "mod_quarry должен увеличить прирост кирпичей")


func test_apply_artifact_effect_mod_magic() -> void:
	manager.apply_artifact_effect(_make_artifact([]), {"type": "mod_magic", "value": 2}, player)
	assert_eq(player.magic, 3, "mod_magic должен увеличить прирост самоцветов")


func test_apply_artifact_effect_build_wall() -> void:
	manager.apply_artifact_effect(_make_artifact([]), {"type": "build_wall", "value": 4}, player)
	assert_eq(player.wall_hp, 9, "build_wall должен увеличить HP стены")


func test_apply_artifact_effect_build_tower() -> void:
	manager.apply_artifact_effect(_make_artifact([]), {"type": "build_tower", "value": 4}, player)
	assert_eq(player.tower_hp, 24, "build_tower должен увеличить HP башни")


# --- _check_artifacts (триггеры) ---


func test_check_artifacts_triggers_matching_trigger_type() -> void:
	var artifact := _make_artifact([{"trigger": "card_played", "type": "mod_quarry", "value": 5}])
	player.active_artifacts = [artifact]
	manager._check_artifacts(player, "card_played")
	assert_eq(player.quarry, 6, "Эффект с совпадающим триггером должен сработать")


func test_check_artifacts_ignores_non_matching_trigger_type() -> void:
	var artifact := _make_artifact([{"trigger": "turn_started", "type": "mod_quarry", "value": 5}])
	player.active_artifacts = [artifact]
	manager._check_artifacts(player, "card_played")
	assert_eq(player.quarry, 1, "Эффект с другим типом триггера срабатывать не должен")


func test_check_artifacts_handles_multiple_artifacts() -> void:
	var a1 := _make_artifact([{"trigger": "turn_started", "type": "mod_quarry", "value": 1}])
	var a2 := _make_artifact([{"trigger": "turn_started", "type": "mod_magic", "value": 2}])
	player.active_artifacts = [a1, a2]
	manager._check_artifacts(player, "turn_started")
	assert_eq(player.quarry, 2, "Первый артефакт должен сработать")
	assert_eq(player.magic, 3, "Второй артефакт должен сработать независимо от первого")
