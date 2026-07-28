extends GutTest
## Юнит-тесты EventScreen (ARC-014): выбор исхода по вероятности, худший
## денежный расход варианта, применение эффектов к MatchSettings, и проверка
## структуры всех 5 .tres событий. Экземпляр создаётся через load().new() без
## добавления в дерево сцены, как в tests/test_shop_screen.gd —
## _return_to_map() (трогает get_tree()) здесь не тестируется.

const EventScreenScript = preload("res://ui/event/event_screen.gd")


func before_each() -> void:
	MatchSettings.run_gold = 0
	MatchSettings.run_deck = []
	MatchSettings.run_tower_bonus = 0
	MatchSettings.run_quarry_bonus = 0
	MatchSettings.run_magic_bonus = 0
	MatchSettings.run_dungeon_bonus = 0


# --- _resolve_outcome ---


func test_resolve_outcome_returns_only_outcome_when_guaranteed() -> void:
	var screen = EventScreenScript.new()
	var outcomes: Array = [{"chance": 100, "result_text": "a", "effects": []}]

	for i in range(5):
		assert_eq(screen._resolve_outcome(outcomes), outcomes[0])

	screen.free()


func test_resolve_outcome_never_picks_zero_chance_outcome() -> void:
	var screen = EventScreenScript.new()
	var outcomes: Array = [
		{"chance": 0, "result_text": "never", "effects": []},
		{"chance": 100, "result_text": "always", "effects": []},
	]

	for i in range(5):
		assert_eq(screen._resolve_outcome(outcomes), outcomes[1])

	screen.free()


func test_resolve_outcome_returns_empty_dict_for_empty_outcomes() -> void:
	var screen = EventScreenScript.new()

	assert_eq(screen._resolve_outcome([]), {})

	screen.free()


# --- _min_gold_delta ---


func test_min_gold_delta_zero_when_no_gold_effects() -> void:
	var screen = EventScreenScript.new()
	var option := {"outcomes": [{"chance": 100, "effects": []}]}

	assert_eq(screen._min_gold_delta(option), 0)

	screen.free()


func test_min_gold_delta_picks_worst_outcome() -> void:
	var screen = EventScreenScript.new()
	var option := {
		"outcomes": [
			{"chance": 70, "effects": [{"type": "gold", "value": 15}]},
			{"chance": 30, "effects": [{"type": "gold", "value": -5}]},
		]
	}

	assert_eq(screen._min_gold_delta(option), -5)

	screen.free()


# --- _apply_effects ---


func test_apply_effects_gold_delta() -> void:
	var screen = EventScreenScript.new()
	MatchSettings.run_gold = 20

	screen._apply_effects([{"type": "gold", "value": -5}])

	assert_eq(MatchSettings.run_gold, 15)

	screen.free()


func test_apply_effects_gold_clamped_at_zero() -> void:
	var screen = EventScreenScript.new()
	MatchSettings.run_gold = 3

	screen._apply_effects([{"type": "gold", "value": -10}])

	assert_eq(MatchSettings.run_gold, 0, "Золото не должно уходить в минус")

	screen.free()


func test_apply_effects_add_card_appends_to_run_deck() -> void:
	var screen = EventScreenScript.new()

	screen._apply_effects([{"type": "add_card", "card_path": "res://data/cards/knight_card.tres"}])

	assert_eq(MatchSettings.run_deck.size(), 1)
	assert_eq(MatchSettings.run_deck[0].card_name, "Рыцарь")

	screen.free()


func test_apply_effects_run_bonuses() -> void:
	var screen = EventScreenScript.new()

	screen._apply_effects(
		[
			{"type": "run_tower_bonus", "value": 3},
			{"type": "run_quarry_bonus", "value": 1},
			{"type": "run_magic_bonus", "value": 1},
			{"type": "run_dungeon_bonus", "value": 1},
		]
	)

	assert_eq(MatchSettings.run_tower_bonus, 3)
	assert_eq(MatchSettings.run_quarry_bonus, 1)
	assert_eq(MatchSettings.run_magic_bonus, 1)
	assert_eq(MatchSettings.run_dungeon_bonus, 1)

	screen.free()


# --- данные событий ---


func test_all_events_have_valid_structure() -> void:
	for path in EventScreenScript.EVENT_PATHS:
		var event: EventData = load(path)

		assert_true(event != null, "Событие должно загружаться: %s" % path)
		assert_false(event.event_title.is_empty(), "Пустой заголовок: %s" % path)
		assert_false(event.event_description.is_empty(), "Пустое описание: %s" % path)
		assert_true(
			event.options.size() >= 2 and event.options.size() <= 3,
			"2-3 варианта выбора: %s" % path
		)

		for option in event.options:
			assert_false(String(option.get("text", "")).is_empty(), "Пустой текст варианта: %s" % path)
			var outcomes: Array = option.get("outcomes", [])
			assert_false(outcomes.is_empty(), "Вариант без исходов: %s" % path)

			var total_chance := 0
			for outcome in outcomes:
				total_chance += int(outcome.get("chance", 0))
			assert_eq(total_chance, 100, "Сумма chance должна быть 100: %s" % path)
