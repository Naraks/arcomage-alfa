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


func test_empty_profile_has_no_winrate_and_offers_first_run_goal() -> void:
	var screen = StatsScreenScript.new()

	assert_eq(screen._win_summary(), {"wins": 0, "runs": 0, "winrate": -1})
	assert_eq(screen._empty_goal_text(), "Завершите первый забег, чтобы начать историю.")
	screen._build_ui()
	assert_null(screen.find_child("WinrateLabel", true, false))

	screen.free()


func test_filled_profile_reports_winrate_records_and_collection_progress() -> void:
	var screen = StatsScreenScript.new()
	var rare_paths := screen._rare_card_paths()
	ProfileManager.profile = {
		"total_runs": 8,
		"total_wins": 3,
		"max_tower_height": 61,
		"best_run_floors": 12,
		"unlocked_cards": [rare_paths[0]],
		"unlocked_artifacts": [RewardScreenScript.ALL_ARTIFACT_PATHS[0]],
	}

	assert_eq(screen._win_summary(), {"wins": 3, "runs": 8, "winrate": 38})
	assert_eq(screen._empty_goal_text(), "")
	assert_eq(screen._collection_progress("unlocked_cards", rare_paths.size()).count, 1)
	screen._build_ui()
	var winrate: Label = screen.find_child("WinrateLabel", true, false)
	assert_not_null(winrate)
	assert_eq(winrate.text, "Победы: 38%")
	assert_eq(screen._records_grid.get_child_count(), 2)

	screen.free()


func test_unsupported_best_run_metric_is_not_rendered() -> void:
	var screen = StatsScreenScript.new()
	ProfileManager.profile = {
		"total_runs": 1,
		"total_wins": 0,
		"max_tower_height": 20,
		"unlocked_cards": [],
		"unlocked_artifacts": [],
	}

	screen._build_ui()

	assert_eq(screen._records_grid.get_child_count(), 1)
	screen.free()


func test_layout_stacks_records_on_mobile() -> void:
	var screen = StatsScreenScript.new()

	assert_eq(screen._layout_mode_for_size(Vector2(1280, 720)), "desktop")
	assert_eq(screen._layout_mode_for_size(Vector2(540, 960)), "mobile")

	screen.free()
