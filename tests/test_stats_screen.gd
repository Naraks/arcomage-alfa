extends GutTest
## Тесты статистики профиля.

const StatsScreenScript = preload("res://ui/stats/stats_screen.gd")
const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")

var _saved_profile: Dictionary


func before_each() -> void:
	_saved_profile = ProfileManager.profile.duplicate(true)
	ProfileManager.profile = {"fame": 0, "unlocked_cards": [], "unlocked_artifacts": []}


func after_each() -> void:
	ProfileManager.profile = _saved_profile


func test_rare_card_paths_only_contains_rare_cards() -> void:
	var screen = StatsScreenScript.new()

	var paths := screen._rare_card_paths()

	assert_false(paths.is_empty(), "В ALL_CARD_PATHS должна быть хотя бы одна RARE-карта")
	for path in paths:
		var card: CardData = load(path)
		assert_eq(card.rarity, CardData.Rarity.RARE)

	screen.free()


func test_unlocked_cards_text_shows_zero_of_total_by_default() -> void:
	var screen = StatsScreenScript.new()
	var total := screen._rare_card_paths().size()

	assert_eq(screen._unlocked_cards_text(), "Открыто редких карт: 0/%d" % total)

	screen.free()


func test_unlocked_cards_text_reflects_unlocked_count() -> void:
	var screen = StatsScreenScript.new()
	var rare_paths := screen._rare_card_paths()
	ProfileManager.profile["unlocked_cards"] = [rare_paths[0]]

	var total := rare_paths.size()
	assert_eq(screen._unlocked_cards_text(), "Открыто редких карт: 1/%d" % total)

	screen.free()


func test_unlocked_artifacts_text_shows_zero_of_total_by_default() -> void:
	var screen = StatsScreenScript.new()

	var text := screen._unlocked_artifacts_text()

	assert_eq(text, "Собрано артефактов: 0/%d" % RewardScreenScript.ALL_ARTIFACT_PATHS.size())

	screen.free()


func test_unlocked_artifacts_text_reflects_collected_count() -> void:
	var screen = StatsScreenScript.new()
	ProfileManager.profile["unlocked_artifacts"] = [RewardScreenScript.ALL_ARTIFACT_PATHS[0]]

	var text := screen._unlocked_artifacts_text()

	assert_eq(text, "Собрано артефактов: 1/%d" % RewardScreenScript.ALL_ARTIFACT_PATHS.size())

	screen.free()
