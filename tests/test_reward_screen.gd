extends GutTest
## Тесты наград за бой.

const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")

var _saved_unlocked_cards: Array
var _saved_unlocked_artifacts: Array


func before_each() -> void:
	MatchSettings.run_deck = []
	MatchSettings.run_artifacts = []
	_saved_unlocked_cards = ProfileManager.profile.get("unlocked_cards", []).duplicate()
	ProfileManager.profile["unlocked_cards"] = []
	_saved_unlocked_artifacts = ProfileManager.profile.get("unlocked_artifacts", []).duplicate()
	ProfileManager.profile["unlocked_artifacts"] = []


func after_each() -> void:
	ProfileManager.profile["unlocked_cards"] = _saved_unlocked_cards
	ProfileManager.profile["unlocked_artifacts"] = _saved_unlocked_artifacts


func test_build_battle_slots_returns_three_distinct_cards() -> void:
	var screen = RewardScreenScript.new()

	var slots := screen._build_battle_slots()

	assert_eq(slots.size(), 3)
	var seen := {}
	for slot in slots:
		assert_eq(slot.get("kind"), "card")
		var card = slot["card"]
		assert_false(seen.has(card), "Слоты обычного боя не должны повторять одну карту")
		seen[card] = true

	screen.free()


func test_build_elite_slots_always_guarantees_high_rarity_card() -> void:
	var screen = RewardScreenScript.new()
	var high_rarity_cards := [
		load(RewardScreenScript.HIGH_RARITY_CARD_PATHS[0]),
		load(RewardScreenScript.HIGH_RARITY_CARD_PATHS[1])
	]

	for i in range(20):
		var slots := screen._build_elite_slots()
		assert_eq(slots.size(), 3)
		assert_eq(
			slots[2].get("kind"),
			"card",
			"Слот редкой карты не должен пропадать даже при шансе артефакта"
		)
		assert_true(high_rarity_cards.has(slots[2]["card"]))

	screen.free()


func test_build_boss_slots_always_includes_both_high_rarity_cards() -> void:
	var screen = RewardScreenScript.new()

	var slots := screen._build_boss_slots()

	assert_eq(slots.size(), 3)
	assert_eq(slots[0]["card"], load(RewardScreenScript.HIGH_RARITY_CARD_PATHS[0]))
	assert_eq(slots[1]["card"], load(RewardScreenScript.HIGH_RARITY_CARD_PATHS[1]))

	screen.free()


func test_build_boss_slots_offers_artifact_when_available() -> void:
	var screen = RewardScreenScript.new()

	var slots := screen._build_boss_slots()

	assert_eq(slots[2].get("kind"), "artifact")

	screen.free()


func test_build_boss_slots_falls_back_to_card_when_no_artifacts_left() -> void:
	var screen = RewardScreenScript.new()
	MatchSettings.run_artifacts = Array(
		RewardScreenScript.ALL_ARTIFACT_PATHS.map(func(p): return load(p)),
		TYPE_OBJECT,
		"Resource",
		ArtifactData
	)

	var slots := screen._build_boss_slots()

	assert_eq(slots.size(), 3, "Слотов должно остаться 3, даже когда все артефакты уже собраны")
	assert_eq(slots[2].get("kind"), "card")

	screen.free()


func test_available_artifacts_excludes_owned() -> void:
	var screen = RewardScreenScript.new()

	assert_eq(screen._available_artifacts().size(), RewardScreenScript.ALL_ARTIFACT_PATHS.size())

	MatchSettings.run_artifacts = Array(
		RewardScreenScript.ALL_ARTIFACT_PATHS.map(func(p): return load(p)),
		TYPE_OBJECT,
		"Resource",
		ArtifactData
	)

	assert_true(screen._available_artifacts().is_empty())

	screen.free()


func test_apply_slot_card_appends_to_run_deck() -> void:
	var screen = RewardScreenScript.new()
	var card := load("res://data/cards/bricks_medium_wall.tres")

	screen._apply_slot({"kind": "card", "card": card})

	assert_eq(MatchSettings.run_deck, [card])

	screen.free()


func test_apply_slot_artifact_appends_to_run_artifacts() -> void:
	var screen = RewardScreenScript.new()
	var artifact := load(RewardScreenScript.ALL_ARTIFACT_PATHS[0])

	screen._apply_slot({"kind": "artifact", "artifact": artifact})

	assert_eq(MatchSettings.run_artifacts, [artifact])

	screen.free()


func test_apply_slot_artifact_records_it_as_collected_in_profile() -> void:
	var screen = RewardScreenScript.new()
	var artifact := load(RewardScreenScript.ALL_ARTIFACT_PATHS[0])

	screen._apply_slot({"kind": "artifact", "artifact": artifact})

	assert_eq(ProfileManager.profile["unlocked_artifacts"], [artifact.resource_path])

	screen.free()


func test_unlocked_paths_excludes_locked_rare_cards() -> void:
	var screen = RewardScreenScript.new()

	var filtered := screen._unlocked_paths(
		["res://data/cards/gems_armageddon.tres", "res://data/cards/bricks_quarry.tres"]
	)

	assert_eq(filtered, ["res://data/cards/bricks_quarry.tres"])

	screen.free()


func test_unlocked_paths_includes_rare_card_once_unlocked() -> void:
	var screen = RewardScreenScript.new()
	ProfileManager.profile["unlocked_cards"] = ["res://data/cards/gems_armageddon.tres"]

	var filtered := screen._unlocked_paths(
		["res://data/cards/gems_armageddon.tres", "res://data/cards/bricks_quarry.tres"]
	)

	assert_eq(filtered.size(), 2)
	assert_true(filtered.has("res://data/cards/gems_armageddon.tres"))

	screen.free()


func test_build_battle_slots_never_offers_locked_rare_card() -> void:
	var screen = RewardScreenScript.new()

	for i in range(20):
		var slots := screen._build_battle_slots()
		for slot in slots:
			var card: CardData = slot["card"]
			assert_true(
				ProfileManager.is_card_unlocked(card),
				(
					"Награда обычного боя не должна предлагать заблокированную RARE-карту: %s"
					% card.card_name
				)
			)

	screen.free()
