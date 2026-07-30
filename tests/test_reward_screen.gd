extends GutTest
## Юнит-тесты RewardScreen (ARC-015): состав слотов по типу узла, доступность
## артефактов, применение выбранного слота. Экземпляр создаётся через
## load().new() без добавления в дерево сцены, как в tests/test_shop_screen.gd
## — _return_to_map() (трогает get_tree()) здесь не тестируется.

const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")

var _saved_unlocked_cards: Array
var _saved_unlocked_artifacts: Array


func before_each() -> void:
	MatchSettings.run_deck = []
	MatchSettings.run_artifacts = []
	# ARC-038/039: ProfileManager — общий синглтон с другими тестовыми файлами;
	# фиксируем известное состояние (ничего не разблокировано/собрано) и
	# восстанавливаем после, как test_profile_manager.gd делает для всего profile.
	_saved_unlocked_cards = ProfileManager.profile.get("unlocked_cards", []).duplicate()
	ProfileManager.profile["unlocked_cards"] = []
	_saved_unlocked_artifacts = ProfileManager.profile.get("unlocked_artifacts", []).duplicate()
	ProfileManager.profile["unlocked_artifacts"] = []


func after_each() -> void:
	ProfileManager.profile["unlocked_cards"] = _saved_unlocked_cards
	ProfileManager.profile["unlocked_artifacts"] = _saved_unlocked_artifacts


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
	# Владеем ВСЕМИ артефактами (не только первым) — иначе тест ломается при
	# добавлении новых в ALL_ARTIFACT_PATHS (см. ARC-030..035): "артефактов не
	# осталось" означает буквально ни одного доступного, не "меньше на один".
	# Array(..., TYPE_OBJECT, "Resource", ArtifactData) — не просто .map(), тот
	# возвращает нетипизированный Array; присвоить его типизированному полю
	# MatchSettings.run_artifacts (Array[ArtifactData]) движок отказывается
	# ("Invalid assignment ... value of type 'Array'") — нужен явно типизированный
	# массив через 4-аргументный конструктор Array().
	MatchSettings.run_artifacts = Array(
		RewardScreenScript.ALL_ARTIFACT_PATHS.map(func(p): return load(p)), TYPE_OBJECT, "Resource", ArtifactData
	)

	var slots := screen._build_boss_slots()

	assert_eq(slots.size(), 3, "Слотов должно остаться 3, даже когда все артефакты уже собраны")
	assert_eq(slots[2].get("kind"), "card")

	screen.free()


# --- доступность артефактов ---


func test_available_artifacts_excludes_owned() -> void:
	var screen = RewardScreenScript.new()

	assert_eq(screen._available_artifacts().size(), RewardScreenScript.ALL_ARTIFACT_PATHS.size())

	# Владеем ВСЕМИ артефактами — см. комментарий в test_build_boss_slots_falls_back_to_card_when_no_artifacts_left
	# (тот же типизированный Array() нужен по той же причине).
	MatchSettings.run_artifacts = Array(
		RewardScreenScript.ALL_ARTIFACT_PATHS.map(func(p): return load(p)), TYPE_OBJECT, "Resource", ArtifactData
	)

	assert_true(screen._available_artifacts().is_empty())

	screen.free()


# --- применение выбранного слота ---


func test_apply_slot_card_appends_to_run_deck() -> void:
	var screen = RewardScreenScript.new()
	var card := load("res://data/cards/brick_4.tres")

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
	# ARC-039: лифетайм-коллекция для экрана статистики, отдельно от
	# run_artifacts (тот обнуляется каждый новый забег, см. тест выше).
	var screen = RewardScreenScript.new()
	var artifact := load(RewardScreenScript.ALL_ARTIFACT_PATHS[0])

	screen._apply_slot({"kind": "artifact", "artifact": artifact})

	assert_eq(ProfileManager.profile["unlocked_artifacts"], [artifact.resource_path])

	screen.free()


# --- ARC-038: _unlocked_paths() / фильтрация RARE-карт по разблокировке ---


func test_unlocked_paths_excludes_locked_rare_cards() -> void:
	var screen = RewardScreenScript.new()

	# gem_10.tres = "Армагеддон", rarity RARE (см. data/cards/gem_10.tres) —
	# по умолчанию (before_each сбрасывает unlocked_cards в []) заблокирована.
	var filtered := screen._unlocked_paths(["res://data/cards/gem_10.tres", "res://data/cards/brick_1.tres"])

	assert_eq(filtered, ["res://data/cards/brick_1.tres"])

	screen.free()


func test_unlocked_paths_includes_rare_card_once_unlocked() -> void:
	var screen = RewardScreenScript.new()
	ProfileManager.profile["unlocked_cards"] = ["res://data/cards/gem_10.tres"]

	var filtered := screen._unlocked_paths(["res://data/cards/gem_10.tres", "res://data/cards/brick_1.tres"])

	assert_eq(filtered.size(), 2)
	assert_true(filtered.has("res://data/cards/gem_10.tres"))

	screen.free()


func test_build_battle_slots_never_offers_locked_rare_card() -> void:
	var screen = RewardScreenScript.new()

	for i in range(20):
		var slots := screen._build_battle_slots()
		for slot in slots:
			var card: CardData = slot["card"]
			assert_true(
				ProfileManager.is_card_unlocked(card),
				"Награда обычного боя не должна предлагать заблокированную RARE-карту: %s" % card.card_name
			)

	screen.free()
