extends GutTest
## Тесты эффектов артефактов.

const FOUNDERS_BLESSING_PATH := "res://data/artifacts/founders_blessing.tres"
const PREDATOR_FANG_PATH := "res://data/artifacts/predator_fang.tres"

var player: PlayerData
var enemy: PlayerData


func before_each() -> void:
	player = TestFixtures.make_player()
	enemy = TestFixtures.make_player()
	MatchManager.player_data = player
	MatchManager.enemy_data = enemy


func test_apply_artifact_effect_mod_quarry() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(), EffectData.from_dict({"type": "mod_quarry", "value": 2}), player
	)
	assert_eq(player.quarry, 3, "mod_quarry должен увеличить прирост кирпичей")


func test_apply_artifact_effect_mod_magic() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(), EffectData.from_dict({"type": "mod_magic", "value": 2}), player
	)
	assert_eq(player.magic, 3, "mod_magic должен увеличить прирост самоцветов")


func test_apply_artifact_effect_mod_dungeon() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(), EffectData.from_dict({"type": "mod_dungeon", "value": 2}), player
	)
	assert_eq(player.dungeon, 3, "mod_dungeon должен увеличить прирост зверей")


func test_apply_artifact_effect_build_wall() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(), EffectData.from_dict({"type": "build_wall", "value": 4}), player
	)
	assert_eq(player.wall_hp, 9, "build_wall должен увеличить HP стены")


func test_apply_artifact_effect_build_tower() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(), EffectData.from_dict({"type": "build_tower", "value": 4}), player
	)
	assert_eq(player.tower_hp, 24, "build_tower должен увеличить HP башни")


func test_check_artifacts_triggers_matching_trigger_type() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "card_played", "type": "mod_quarry", "value": 5}]
	)
	player.active_artifacts = [artifact]
	ArtifactManager._check_artifacts(player, "card_played")
	assert_eq(player.quarry, 6, "Эффект с совпадающим триггером должен сработать")


func test_check_artifacts_ignores_non_matching_trigger_type() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "turn_started", "type": "mod_quarry", "value": 5}]
	)
	player.active_artifacts = [artifact]
	ArtifactManager._check_artifacts(player, "card_played")
	assert_eq(player.quarry, 1, "Эффект с другим типом триггера срабатывать не должен")


func test_check_artifacts_handles_multiple_artifacts() -> void:
	var a1 := TestFixtures.make_artifact(
		[{"trigger": "turn_started", "type": "mod_quarry", "value": 1}]
	)
	var a2 := TestFixtures.make_artifact(
		[{"trigger": "turn_started", "type": "mod_magic", "value": 2}]
	)
	player.active_artifacts = [a1, a2]
	ArtifactManager._check_artifacts(player, "turn_started")
	assert_eq(player.quarry, 2, "Первый артефакт должен сработать")
	assert_eq(player.magic, 3, "Второй артефакт должен сработать независимо от первого")


func test_gain_resource_without_card_type_filter_always_fires() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(),
		EffectData.from_dict({"type": "gain_resource", "resource": "gems", "value": 1}),
		player
	)
	assert_eq(player.gems, 6, "Без requires_card_type эффект должен срабатывать безусловно")


func test_gain_resource_requires_card_type_fires_on_matching_card() -> void:
	var gem_card := TestFixtures.make_card(1, CardData.ResourceType.GEMS)
	(
		ArtifactManager
		. apply_artifact_effect(
			TestFixtures.make_artifact(),
			EffectData.from_dict(
				{
					"type": "gain_resource",
					"resource": "gems",
					"value": 1,
					"requires_card_type": CardData.ResourceType.GEMS,
				}
			),
			player,
			{"card": gem_card}
		)
	)
	assert_eq(player.gems, 6, "Карта-гем должна проходить фильтр requires_card_type=GEMS")


func test_gain_resource_requires_card_type_ignores_non_matching_card() -> void:
	var brick_card := TestFixtures.make_card(1, CardData.ResourceType.BRICKS)
	(
		ArtifactManager
		. apply_artifact_effect(
			TestFixtures.make_artifact(),
			EffectData.from_dict(
				{
					"type": "gain_resource",
					"resource": "gems",
					"value": 1,
					"requires_card_type": CardData.ResourceType.GEMS,
				}
			),
			player,
			{"card": brick_card}
		)
	)
	assert_eq(player.gems, 5, "Карта-кирпич не должна проходить фильтр requires_card_type=GEMS")


func test_on_card_played_passes_card_into_context_for_gain_resource_filter() -> void:
	var artifact := (
		TestFixtures
		. make_artifact(
			[
				{
					"trigger": "card_played",
					"type": "gain_resource",
					"resource": "gems",
					"value": 1,
					"requires_card_type": CardData.ResourceType.GEMS,
				}
			]
		)
	)
	player.active_artifacts = [artifact]
	var gem_card := TestFixtures.make_card(1, CardData.ResourceType.GEMS)

	ArtifactManager._on_card_played(gem_card, player)

	assert_eq(player.gems, 6, "card_played должен пробросить сыгранную карту в context для фильтра")


func test_set_generator_level_raises_low_generators_to_value() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(),
		EffectData.from_dict({"type": "set_generator_level", "value": 2}),
		player
	)
	assert_eq(player.quarry, 2)
	assert_eq(player.magic, 2)
	assert_eq(player.dungeon, 2)


func test_set_generator_level_does_not_lower_already_higher_generator() -> void:
	player.quarry = 5
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(),
		EffectData.from_dict({"type": "set_generator_level", "value": 2}),
		player
	)
	assert_eq(
		player.quarry,
		5,
		"Уже больший генератор не должен откатываться вниз (см. комментарий в коде)"
	)


func test_on_match_started_applies_to_both_sides() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "match_started", "type": "set_generator_level", "value": 3}]
	)
	player.active_artifacts = [artifact]
	enemy.active_artifacts = [artifact]

	ArtifactManager._on_match_started(player, enemy)

	assert_eq(player.quarry, 3)
	assert_eq(enemy.quarry, 3)


func test_set_max_hand_size_raises_limit() -> void:
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(),
		EffectData.from_dict({"type": "set_max_hand_size", "value": 6}),
		player
	)
	assert_eq(player.max_hand_size, 6)


func test_set_max_hand_size_does_not_lower_already_higher_limit() -> void:
	player.max_hand_size = 8
	ArtifactManager.apply_artifact_effect(
		TestFixtures.make_artifact(),
		EffectData.from_dict({"type": "set_max_hand_size", "value": 6}),
		player
	)
	assert_eq(player.max_hand_size, 8)


func test_reflect_damage_hits_attacker_on_wall_hit() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}]
	)
	player.active_artifacts = [artifact]
	var attacker_tower_before := enemy.tower_hp

	ArtifactManager._on_damage_taken(player, 3, true, enemy)

	assert_eq(
		enemy.tower_hp,
		attacker_tower_before - 2,
		"Атакующий должен получить 2 урона в ответ на удар по стене"
	)


func test_reflect_damage_does_not_fire_on_direct_damage_bypassing_wall() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}]
	)
	player.active_artifacts = [artifact]
	var attacker_tower_before := enemy.tower_hp

	ArtifactManager._on_damage_taken(player, 3, false, enemy)

	assert_eq(
		enemy.tower_hp,
		attacker_tower_before,
		"reflect_damage — только при ударе по стене (hit_wall)"
	)


func test_reflect_damage_no_op_without_known_attacker() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}]
	)
	player.active_artifacts = [artifact]
	var enemy_tower_before := enemy.tower_hp

	ArtifactManager._on_damage_taken(player, 3, true, null)

	assert_eq(enemy.tower_hp, enemy_tower_before)


func test_reflect_damage_does_not_infinite_loop_when_both_sides_have_the_artifact() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}]
	)
	player.active_artifacts = [artifact]
	enemy.active_artifacts = [artifact]
	var enemy_tower_before := enemy.tower_hp

	ArtifactManager._on_damage_taken(player, 3, true, enemy)

	assert_eq(enemy.tower_hp, enemy_tower_before - 2)


func test_should_skip_payment_false_without_artifact() -> void:
	assert_false(ArtifactManager.should_skip_payment(player))


func test_should_skip_payment_true_when_chance_is_certain() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "pre_play", "type": "skip_payment_chance", "value": 1.0}]
	)
	player.active_artifacts = [artifact]

	assert_true(ArtifactManager.should_skip_payment(player), "value=1.0 должно срабатывать всегда")


func test_should_skip_payment_false_when_chance_is_impossible() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "pre_play", "type": "skip_payment_chance", "value": 0.0}]
	)
	player.active_artifacts = [artifact]

	assert_false(
		ArtifactManager.should_skip_payment(player), "value=0.0 не должно срабатывать никогда"
	)


func test_should_skip_payment_is_deterministic_with_fixed_seed() -> void:
	var artifact := TestFixtures.make_artifact(
		[{"trigger": "pre_play", "type": "skip_payment_chance", "value": 0.1}]
	)
	player.active_artifacts = [artifact]

	seed(12345)
	var results: Array[bool] = []
	for i in range(20):
		results.append(ArtifactManager.should_skip_payment(player))

	seed(12345)
	var results_repeat: Array[bool] = []
	for i in range(20):
		results_repeat.append(ArtifactManager.should_skip_payment(player))

	assert_eq(
		results,
		results_repeat,
		"Одинаковый seed должен давать одинаковую последовательность срабатываний"
	)


func test_founders_blessing_applies_wall_and_tower_bonus_on_match_started() -> void:
	var artifact: ArtifactData = load(FOUNDERS_BLESSING_PATH)
	player.active_artifacts = [artifact]
	var wall_before := player.wall_hp
	var tower_before := player.tower_hp

	ArtifactManager._on_match_started(player, enemy)

	assert_eq(
		player.wall_hp, wall_before + 5, "Благословение Основателя должно дать Стене +5 HP"
	)
	assert_eq(
		player.tower_hp, tower_before + 3, "Благословение Основателя должно дать Башне +3 HP"
	)


func test_founders_blessing_does_not_affect_side_without_the_artifact() -> void:
	var artifact: ArtifactData = load(FOUNDERS_BLESSING_PATH)
	player.active_artifacts = [artifact]
	var enemy_wall_before := enemy.wall_hp
	var enemy_tower_before := enemy.tower_hp

	ArtifactManager._on_match_started(player, enemy)

	assert_eq(enemy.wall_hp, enemy_wall_before, "Эффект не должен затрагивать противника")
	assert_eq(enemy.tower_hp, enemy_tower_before, "Эффект не должен затрагивать противника")


func test_predator_fang_increases_beast_generator_on_turn_started() -> void:
	var artifact: ArtifactData = load(PREDATOR_FANG_PATH)
	player.active_artifacts = [artifact]
	var dungeon_before := player.dungeon

	ArtifactManager._on_turn_started(player)

	assert_eq(
		player.dungeon, dungeon_before + 1, "Клык Хищника должен дать +1 к приросту зверей"
	)


func test_predator_fang_does_not_fire_on_other_triggers() -> void:
	var artifact: ArtifactData = load(PREDATOR_FANG_PATH)
	player.active_artifacts = [artifact]
	var dungeon_before := player.dungeon

	ArtifactManager._check_artifacts(player, "card_played")

	assert_eq(
		player.dungeon, dungeon_before, "Клык Хищника триггерится только на начало хода"
	)
