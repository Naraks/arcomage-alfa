extends GutTest
## Юнит-тесты EventScreen (ARC-014, UI 07/13): выбор исхода, цена/доступность
## решения, однократное применение, адаптивный макет и проверка структуры
## всего пула .tres событий. Экземпляр создаётся через load().new() без
## добавления в дерево сцены, как в tests/test_shop_screen.gd —
## _return_to_map() (трогает get_tree()) здесь не тестируется.

const EventScreenScript = preload("res://ui/event/event_screen.gd")
const SUPPORTED_EVENT_EFFECT_TYPES := [
	"gold",
	"add_card",
	"run_tower_bonus",
	"run_quarry_bonus",
	"run_magic_bonus",
	"run_dungeon_bonus",
]


func before_each() -> void:
	MatchSettings.world_map_data = null
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
		"outcomes":
		[
			{"chance": 70, "effects": [{"type": "gold", "value": 15}]},
			{"chance": 30, "effects": [{"type": "gold", "value": -5}]},
		]
	}

	assert_eq(screen._min_gold_delta(option), -5)

	screen.free()


func test_option_state_marks_risk_without_revealing_outcome() -> void:
	var screen = EventScreenScript.new()
	var option := {
		"text": "Испытать удачу",
		"outcomes":
		[
			{"chance": 50, "effects": [{"type": "gold", "value": 14}]},
			{"chance": 50, "effects": [{"type": "gold", "value": -5}]},
		],
	}

	var state: Dictionary = screen._option_state(option, 20)
	var details: String = screen._option_details_text(state)

	assert_true(state.is_risky)
	assert_eq(state.guaranteed_cost, 0)
	assert_eq(state.required_reserve, 5)
	assert_true(details.contains("Риск"))
	assert_false(details.contains("50"), "UI не должен раскрывать точные шансы/исходы")

	screen.free()


func test_option_state_shows_guaranteed_price_and_shortfall() -> void:
	var screen = EventScreenScript.new()
	var option := {
		"outcomes":
		[
			{"chance": 40, "effects": [{"type": "gold", "value": -10}]},
			{"chance": 60, "effects": [{"type": "gold", "value": -10}]},
		]
	}

	var state: Dictionary = screen._option_state(option, 6)

	assert_false(state.available)
	assert_eq(state.guaranteed_cost, 10)
	assert_eq(state.shortfall, 4)
	assert_eq(state.unavailable_reason, "Не хватает 4 золота")
	assert_true(screen._option_details_text(state).contains("Цена: 10 золота"))

	screen.free()


func test_layout_modes_cover_wide_four_by_three_and_portrait() -> void:
	var screen = EventScreenScript.new()

	assert_eq(screen._layout_mode_for_size(Vector2(1280, 720)), "wide")
	assert_eq(screen._layout_mode_for_size(Vector2(1024, 768)), "stacked")
	assert_eq(screen._layout_mode_for_size(Vector2(720, 1280)), "stacked")

	screen.free()


func test_event_draw_pile_has_no_repeats_before_exhaustion() -> void:
	var screen = EventScreenScript.new()
	var map := WorldMapData.new()
	MatchSettings.world_map_data = map
	var all_paths: Array[String] = screen._all_event_paths()
	var drawn: Array[String] = []

	for i in range(all_paths.size()):
		var path := screen._pick_random_event_path()
		assert_false(drawn.has(path), "Событие не должно повторяться до исчерпания shuffle bag")
		drawn.append(path)

	assert_eq(drawn.size(), all_paths.size())
	assert_true(map.event_draw_pile.is_empty())
	MatchSettings.world_map_data = null
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
	var effects: Array = [
		{"type": "run_tower_bonus", "value": 3},
		{"type": "run_quarry_bonus", "value": 1},
		{"type": "run_magic_bonus", "value": 1},
		{"type": "run_dungeon_bonus", "value": 1},
	]

	screen._apply_effects(effects)

	assert_eq(MatchSettings.run_tower_bonus, 3)
	assert_eq(MatchSettings.run_quarry_bonus, 1)
	assert_eq(MatchSettings.run_magic_bonus, 1)
	assert_eq(MatchSettings.run_dungeon_bonus, 1)

	screen.free()


# --- данные событий ---


func test_all_events_have_valid_structure() -> void:
	var screen = EventScreenScript.new()
	var paths: Array[String] = screen._all_event_paths()
	assert_gte(paths.size(), 15, "ARC-088: пул должен содержать минимум 15 событий")
	var titles := {}
	for path in paths:
		var event: EventData = load(path)

		assert_true(event != null, "Событие должно загружаться: %s" % path)
		assert_false(event.event_title.is_empty(), "Пустой заголовок: %s" % path)
		assert_false(event.event_description.is_empty(), "Пустое описание: %s" % path)
		assert_false(
			titles.has(event.event_title), "Заголовок события должен быть уникален: %s" % path
		)
		titles[event.event_title] = true
		assert_true(
			event.options.size() >= 2 and event.options.size() <= 3,
			"2-3 варианта выбора: %s" % path
		)
		var has_safe_exit := false

		for option in event.options:
			assert_false(
				String(option.get("text", "")).is_empty(), "Пустой текст варианта: %s" % path
			)
			var outcomes: Array = option.get("outcomes", [])
			assert_false(outcomes.is_empty(), "Вариант без исходов: %s" % path)
			if outcomes.size() == 1 and outcomes[0].get("chance", 0) == 100:
				has_safe_exit = outcomes[0].get("effects", []).is_empty() or has_safe_exit

			var total_chance := 0
			for outcome in outcomes:
				total_chance += int(outcome.get("chance", 0))
				assert_false(
					String(outcome.get("result_text", "")).is_empty(), "Пустой результат: %s" % path
				)
				for effect in outcome.get("effects", []):
					var effect_type: String = effect.get("type", "")
					assert_true(
						SUPPORTED_EVENT_EFFECT_TYPES.has(effect_type),
						"Неизвестный эффект %s: %s" % [effect_type, path]
					)
					if effect_type == "add_card":
						assert_true(
							ResourceLoader.exists(effect.get("card_path", "")),
							"Нет карты: %s" % path
						)
			assert_eq(total_chance, 100, "Сумма chance должна быть 100: %s" % path)
		assert_true(has_safe_exit, "У события должен быть безопасный выход без расходов: %s" % path)
	screen.free()


func test_apply_option_once_blocks_double_application() -> void:
	var screen = EventScreenScript.new()
	MatchSettings.run_gold = 20
	var option := {
		"outcomes":
		[
			{
				"chance": 100,
				"result_text": "Оплачено",
				"effects": [{"type": "gold", "value": -5}],
			}
		]
	}

	var first: Dictionary = screen._apply_option_once(option)
	var second: Dictionary = screen._apply_option_once(option)

	assert_eq(first.result_text, "Оплачено")
	assert_eq(second, {})
	assert_eq(MatchSettings.run_gold, 15, "Двойной клик не должен применить цену дважды")

	screen.free()
