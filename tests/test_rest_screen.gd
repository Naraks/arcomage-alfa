extends GutTest
## Юнит-тесты RestScreen (ARC-013, UI 08/13): превью, лимиты, двухшаговый
## выбор и защита применения от двойного ввода.

const RestScreenScript = preload("res://ui/rest/rest_screen.gd")


func before_each() -> void:
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0


func test_pick_random_generator_returns_valid_key() -> void:
	var screen = RestScreenScript.new()

	for i in range(20):
		var key: String = screen._pick_random_generator()
		assert_true(
			key in ["quarry", "magic", "dungeon"],
			"Случайный генератор должен быть одним из трёх известных ключей"
		)

	screen.free()


func test_generator_label_has_entry_for_every_generator() -> void:
	var screen = RestScreenScript.new()

	for key in ["quarry", "magic", "dungeon"]:
		assert_ne(
			screen._generator_label(key),
			key,
			"Для каждого генератора должна быть человекочитаемая подпись"
		)

	screen.free()


func test_preview_shows_before_and_after_values() -> void:
	var screen = RestScreenScript.new()
	MatchSettings.run_tower_bonus = 10

	assert_eq(screen._preview_text("tower"), "Бонус: +10 → +15")

	screen.free()


func test_generator_preview_uses_offered_generator_current_value() -> void:
	var screen = RestScreenScript.new()
	screen._offered_generator = "magic"
	MatchSettings.run_magic_bonus = 2

	assert_eq(screen._preview_text("generator"), "Бонус: +2 → +3")

	screen.free()


func test_option_at_maximum_is_unavailable_and_explains_reason() -> void:
	var screen = RestScreenScript.new()
	MatchSettings.run_tower_bonus = RestScreenScript.MAX_TOWER_BONUS

	var state: Dictionary = screen._option_state("tower")
	assert_false(state.available)
	assert_eq(state.after, RestScreenScript.MAX_TOWER_BONUS)
	assert_true("максимум" in state.unavailable_reason)

	screen.free()


func test_layout_stacks_for_portrait_and_uses_row_for_wide_viewport() -> void:
	var screen = RestScreenScript.new()

	assert_eq(screen._layout_mode_for_size(Vector2(720, 1280)), "stacked")
	assert_eq(screen._layout_mode_for_size(Vector2(1280, 720)), "wide")

	screen.free()


func test_apply_tower_bonus_increments_run_tower_bonus() -> void:
	var screen = RestScreenScript.new()

	screen._apply_tower_bonus()

	assert_eq(MatchSettings.run_tower_bonus, RestScreenScript.TOWER_BONUS_AMOUNT)

	screen.free()


func test_apply_tower_bonus_stacks_across_multiple_visits() -> void:
	var screen = RestScreenScript.new()

	screen._apply_tower_bonus()
	screen._apply_tower_bonus()

	assert_eq(
		MatchSettings.run_tower_bonus,
		RestScreenScript.TOWER_BONUS_AMOUNT * 2,
		"Несколько посещений Отдыха с одним и тем же выбором должны накапливаться"
	)

	screen.free()


func test_apply_tower_bonus_does_not_exceed_maximum() -> void:
	var screen = RestScreenScript.new()
	MatchSettings.run_tower_bonus = RestScreenScript.MAX_TOWER_BONUS

	screen._apply_tower_bonus()

	assert_eq(MatchSettings.run_tower_bonus, RestScreenScript.MAX_TOWER_BONUS)
	screen.free()


func test_apply_generator_bonus_increments_correct_field() -> void:
	var screen = RestScreenScript.new()

	screen._apply_generator_bonus("quarry")
	assert_eq(MatchSettings.run_quarry_bonus, RestScreenScript.GENERATOR_BONUS_AMOUNT)
	assert_eq(
		MatchSettings.run_magic_bonus, 0, "Бонус карьера не должен задевать другие генераторы"
	)
	assert_eq(
		MatchSettings.run_dungeon_bonus, 0, "Бонус карьера не должен задевать другие генераторы"
	)

	screen.free()


func test_apply_generator_bonus_for_magic() -> void:
	var screen = RestScreenScript.new()

	screen._apply_generator_bonus("magic")
	assert_eq(MatchSettings.run_magic_bonus, RestScreenScript.GENERATOR_BONUS_AMOUNT)

	screen.free()


func test_apply_generator_bonus_for_dungeon() -> void:
	var screen = RestScreenScript.new()

	screen._apply_generator_bonus("dungeon")
	assert_eq(MatchSettings.run_dungeon_bonus, RestScreenScript.GENERATOR_BONUS_AMOUNT)

	screen.free()


func test_selected_bonus_is_applied_exactly_once() -> void:
	var screen = RestScreenScript.new()
	screen._selected_option = "tower"

	assert_true(screen._apply_selected_once())
	assert_false(screen._apply_selected_once(), "Повторный ввод должен игнорироваться")
	assert_eq(MatchSettings.run_tower_bonus, RestScreenScript.TOWER_BONUS_AMOUNT)

	screen.free()


func test_nothing_is_applied_before_confirmation() -> void:
	var screen = RestScreenScript.new()
	screen._selected_option = "tower"

	assert_eq(MatchSettings.run_tower_bonus, 0)
	assert_false(screen._choice_resolved)

	screen.free()
