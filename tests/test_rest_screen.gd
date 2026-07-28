extends GutTest
## Юнит-тесты RestScreen (ARC-013): выбор случайного генератора для
## предложения, подпись генератора и применение бонусов к MatchSettings.
##
## rest_screen.gd — обычный Control-скрипт сцены (без class_name), поэтому
## экземпляр создаётся через load().new() и НЕ добавляется в дерево сцены, как
## и в tests/test_shop_screen.gd. _apply_tower_bonus()/_apply_generator_bonus()
## трогают только MatchSettings (autoload-синглтон, доступен без дерева сцены)
## — специально вынесены из _on_*_chosen() отдельно от _return_to_map(),
## которая обращается к get_tree() и потому не тестируется здесь напрямую.

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
			screen._generator_label(key), key, "Для каждого генератора должна быть человекочитаемая подпись"
		)

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


func test_apply_generator_bonus_increments_correct_field() -> void:
	var screen = RestScreenScript.new()

	screen._apply_generator_bonus("quarry")
	assert_eq(MatchSettings.run_quarry_bonus, RestScreenScript.GENERATOR_BONUS_AMOUNT)
	assert_eq(MatchSettings.run_magic_bonus, 0, "Бонус карьера не должен задевать другие генераторы")
	assert_eq(MatchSettings.run_dungeon_bonus, 0, "Бонус карьера не должен задевать другие генераторы")

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
