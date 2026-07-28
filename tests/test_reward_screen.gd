extends GutTest
## Юнит-тесты RewardScreen (ARC-015): состав слотов по типу узла, доступность
## артефактов, применение выбранного слота. Экземпляр создаётся через
## load().new() без добавления в дерево сцены, как в tests/test_shop_screen.gd
## — _return_to_map() (трогает get_tree()) здесь не тестируется.

const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")


func before_each() -> void:
	MatchSettings.run_deck = []
	MatchSettings.run_artifacts = []


# --- обычный бой ---


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


# --- элитный бой ---


func test_build_elite_slots_always_guarantees_high_rarity_card() -> void:
	var screen = RewardScreenScript.new()
	var high_rarity_cards := [
		load(RewardScreenScript.HIGH_RARITY_CARD_PATHS[0]), load(RewardScreenScript.HIGH_RARITY_CARD_PATHS[1])
	]

	for i in range(20):
		var slots := screen._build_elite_slots()
		assert_eq(slots.size(), 3)
		assert_eq(slots[2].get("kind"), "card", "Слот редкой карты не должен пропадать даже при шансе артефакта")
		assert_true(high_rarity_cards.has(slots[2]["card"]))

	screen.free()


# --- босс ---


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
	MatchSettings.run_artifacts = [load(RewardScreenScript.ALL_ARTIFACT_PATHS[0])]

	var slots := screen._build_boss_slots()

	assert_eq(slots.size(), 3, "Слотов должно остаться 3, даже когда все артефакты уже собраны")
	assert_eq(slots[2].get("kind"), "card")

	screen.free()


# --- доступность артефактов ---


func test_available_artifacts_excludes_owned() -> void:
	var screen = RewardScreenScript.new()

	assert_eq(screen._available_artifacts().size(), RewardScreenScript.ALL_ARTIFACT_PATHS.size())

	MatchSettings.run_artifacts = [load(RewardScreenScript.ALL_ARTIFACT_PATHS[0])]

	assert_true(screen._available_artifacts().is_empty())

	screen.free()


# --- применение выбранного слота ---


func test_apply_slot_card_appends_to_run_deck() -> void:
	var screen = RewardScreenScript.new()
	var card := load("res://data/cards/meteor.tres")

	screen._apply_slot({"kind": "card", "card": card})

	assert_eq(MatchSettings.run_deck, [card])

	screen.free()


func test_apply_slot_artifact_appends_to_run_artifacts() -> void:
	var screen = RewardScreenScript.new()
	var artifact := load(RewardScreenScript.ALL_ARTIFACT_PATHS[0])

	screen._apply_slot({"kind": "artifact", "artifact": artifact})

	assert_eq(MatchSettings.run_artifacts, [artifact])

	screen.free()
