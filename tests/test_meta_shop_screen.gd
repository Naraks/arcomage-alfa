extends GutTest
## Тесты постоянных улучшений.

const MetaShopScreenScript = preload("res://ui/meta_shop/meta_shop_screen.gd")

var _saved_profile: Dictionary


func before_each() -> void:
	_saved_profile = ProfileManager.profile.duplicate(true)
	ProfileManager.profile = {"fame": 0, "upgrades": {}}


func after_each() -> void:
	ProfileManager.profile = _saved_profile


func test_upgrade_order_covers_the_whole_catalog() -> void:
	var screen = MetaShopScreenScript.new()

	var order_set := {}
	for key in screen.UPGRADE_ORDER:
		order_set[key] = true

	assert_eq(order_set.keys().size(), ProfileManager.UPGRADE_CATALOG.keys().size())
	for key in ProfileManager.UPGRADE_CATALOG.keys():
		assert_true(order_set.has(key), "UPGRADE_ORDER не содержит ключ каталога: %s" % key)

	screen.free()


func test_upgrade_groups_cover_catalog_once_and_match_real_functions() -> void:
	var screen = MetaShopScreenScript.new()
	var grouped: Array = []
	for group_name in screen.GROUP_ORDER:
		grouped.append_array(screen.UPGRADE_GROUPS[group_name])

	assert_eq(grouped.size(), screen.UPGRADE_ORDER.size())
	for key in screen.UPGRADE_ORDER:
		assert_eq(grouped.count(key), 1, "%s должен входить ровно в одну категорию" % key)
	assert_eq(screen.UPGRADE_GROUPS["Основание"], ["tower", "wall"])
	assert_eq(screen.UPGRADE_GROUPS["Ресурсы"], ["quarry", "magic", "dungeon"])
	assert_eq(screen.UPGRADE_GROUPS["Утилити"], ["hand_size"])

	screen.free()


func test_upgrade_states_are_distinguishable_by_text_and_metadata() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = 0
	var locked := screen._make_upgrade_row("tower")
	assert_eq(locked.get_meta("state"), "locked")
	assert_true(locked.get_node("MarginContainer/VBoxContainer/StateLabel").text.contains("🔒"))

	ProfileManager.profile["fame"] = ProfileManager.UPGRADE_CATALOG["tower"]["base_cost"]
	var affordable := screen._make_upgrade_row("tower")
	assert_eq(affordable.get_meta("state"), "affordable")
	assert_true(affordable.get_node("MarginContainer/VBoxContainer/StateLabel").text.contains("✓"))

	ProfileManager.profile["upgrades"] = {
		"tower": ProfileManager.UPGRADE_CATALOG["tower"]["max_level"]
	}
	var maximum := screen._make_upgrade_row("tower")
	assert_eq(maximum.get_meta("state"), "max")
	assert_true(maximum.get_node("MarginContainer/VBoxContainer/StateLabel").text.contains("★"))

	locked.free()
	affordable.free()
	maximum.free()
	screen.free()


func test_upgrade_card_shows_level_next_effect_price_and_maximum() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = 999
	ProfileManager.profile["upgrades"] = {"wall": 2}
	var card := screen._make_upgrade_row("wall")

	assert_eq(card.get_node("MarginContainer/VBoxContainer/LevelLabel").text, "УРОВЕНЬ 2 / 5")
	assert_true(
		card.get_node("MarginContainer/VBoxContainer/NextEffectLabel").text.contains(
			"Следующий эффект"
		)
	)
	assert_true(card.get_node("MarginContainer/VBoxContainer/BuyButton").text.contains("славы"))

	card.free()
	screen.free()


func test_layout_switches_grids_to_one_column_on_portrait() -> void:
	var screen = MetaShopScreenScript.new()
	screen._build_ui()

	screen._apply_layout(Vector2(1280, 720))
	assert_eq(screen._upgrade_grids[0].columns, 2)
	assert_eq(screen._unlock_grid.columns, 2)
	screen._apply_layout(Vector2(720, 1280))
	assert_eq(screen._upgrade_grids[0].columns, 1)
	assert_eq(screen._unlock_grid.columns, 1)

	screen.free()


func test_row_label_text_shows_level_and_max() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["upgrades"] = {"tower": 2}

	var text := screen._row_label_text("tower")

	assert_true(text.contains("2/%d" % ProfileManager.UPGRADE_CATALOG["tower"]["max_level"]))
	assert_true(text.contains(ProfileManager.UPGRADE_CATALOG["tower"]["name"]))

	screen.free()


func test_row_label_text_shows_next_level_bonus_before_max() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["upgrades"] = {"quarry": 1}

	var text := screen._row_label_text("quarry")

	assert_true(text.contains("+%d" % ProfileManager.UPGRADE_CATALOG["quarry"]["per_level"]))

	screen.free()


func test_row_label_text_at_max_level_shows_total_bonus_not_per_level() -> void:
	var screen = MetaShopScreenScript.new()
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["hand_size"]
	ProfileManager.profile["upgrades"] = {"hand_size": def["max_level"]}

	var text := screen._row_label_text("hand_size")

	assert_true(text.contains("+%d" % (def["per_level"] * def["max_level"])))

	screen.free()


func test_buy_button_text_shows_cost_when_affordable_or_not() -> void:
	var screen = MetaShopScreenScript.new()

	var text := screen._buy_button_text("wall")

	assert_eq(text, "Купить · %d славы" % ProfileManager.UPGRADE_CATALOG["wall"]["base_cost"])

	screen.free()


func test_buy_button_text_shows_max_at_max_level() -> void:
	var screen = MetaShopScreenScript.new()
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["hand_size"]
	ProfileManager.profile["upgrades"] = {"hand_size": def["max_level"]}

	var text := screen._buy_button_text("hand_size")

	assert_eq(text, "МАКС.")

	screen.free()


func test_make_upgrade_row_disables_buy_button_without_enough_fame() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = 0

	var row := screen._make_upgrade_row("tower")
	var buy_button: Button = row.find_child("BuyButton", true, false)

	assert_true(buy_button.disabled)

	row.free()
	screen.free()


func test_make_upgrade_row_enables_buy_button_with_enough_fame() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = ProfileManager.UPGRADE_CATALOG["tower"]["base_cost"]

	var row := screen._make_upgrade_row("tower")
	var buy_button: Button = row.find_child("BuyButton", true, false)

	assert_false(buy_button.disabled)

	row.free()
	screen.free()


func test_on_buy_pressed_purchases_and_updates_fame_label_via_profile_manager() -> void:
	var screen = MetaShopScreenScript.new()
	var cost: int = ProfileManager.UPGRADE_CATALOG["tower"]["base_cost"]
	ProfileManager.profile["fame"] = cost

	screen._build_ui()

	screen._on_buy_pressed("tower")

	assert_eq(ProfileManager.get_upgrade_level("tower"), 1)
	assert_eq(ProfileManager.profile["fame"], 0)
	assert_true(screen._feedback_label.text.contains("приобретено"))
	var refreshed_card := screen._make_upgrade_row("tower")
	assert_eq(refreshed_card.get_meta("state"), "locked")
	refreshed_card.free()

	screen.free()


func test_rare_card_paths_only_contains_rare_cards() -> void:
	var screen = MetaShopScreenScript.new()

	var paths := screen._rare_card_paths()

	assert_false(paths.is_empty(), "В ALL_CARD_PATHS должна быть хотя бы одна RARE-карта")
	for path in paths:
		var card: CardData = load(path)
		assert_eq(
			card.rarity, CardData.Rarity.RARE, "%s не RARE, не место в списке разблокировок" % path
		)

	screen.free()


func test_unlock_row_text_shows_locked_status_by_default() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["unlocked_cards"] = []
	var path: String = screen._rare_card_paths()[0]

	var text := screen._unlock_row_text(path)

	assert_true(text.contains("заблокирована"))

	screen.free()


func test_unlock_row_text_shows_unlocked_status_after_unlock() -> void:
	var screen = MetaShopScreenScript.new()
	var path: String = screen._rare_card_paths()[0]
	ProfileManager.profile["unlocked_cards"] = [path]

	var text := screen._unlock_row_text(path)

	assert_true(text.contains("разблокирована"))

	screen.free()


func test_unlock_button_text_shows_cost_when_locked() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["unlocked_cards"] = []
	var path: String = screen._rare_card_paths()[0]

	assert_eq(
		screen._unlock_button_text(path), "Открыть за %d" % ProfileManager.RARE_CARD_UNLOCK_COST
	)

	screen.free()


func test_unlock_button_text_shows_open_when_already_unlocked() -> void:
	var screen = MetaShopScreenScript.new()
	var path: String = screen._rare_card_paths()[0]
	ProfileManager.profile["unlocked_cards"] = [path]

	assert_eq(screen._unlock_button_text(path), "Открыто")

	screen.free()


func test_make_unlock_row_disables_button_without_enough_fame() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = 0
	var path: String = screen._rare_card_paths()[0]

	var row := screen._make_unlock_row(path)
	var unlock_button: Button = row.find_child("UnlockButton", true, false)

	assert_true(unlock_button.disabled)

	row.free()
	screen.free()


func test_make_unlock_row_enables_button_with_enough_fame() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = ProfileManager.RARE_CARD_UNLOCK_COST
	var path: String = screen._rare_card_paths()[0]

	var row := screen._make_unlock_row(path)
	var unlock_button: Button = row.find_child("UnlockButton", true, false)

	assert_false(unlock_button.disabled)

	row.free()
	screen.free()


func test_make_unlock_row_disables_button_when_already_unlocked() -> void:
	var screen = MetaShopScreenScript.new()
	var path: String = screen._rare_card_paths()[0]
	ProfileManager.profile["unlocked_cards"] = [path]
	ProfileManager.profile["fame"] = 999999

	var row := screen._make_unlock_row(path)
	var unlock_button: Button = row.find_child("UnlockButton", true, false)

	assert_true(unlock_button.disabled, "Уже открытую карту нельзя купить повторно")

	row.free()
	screen.free()


func test_unlock_card_has_read_only_game_card_preview_and_explicit_state() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = 0
	var path: String = screen._rare_card_paths()[0]
	var panel := screen._make_unlock_row(path)
	var preview: Control = panel.find_child("CardPreview", true, false)

	assert_not_null(preview)
	assert_eq(preview.card_data, load(path))
	assert_eq(preview.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(panel.get_meta("state"), "locked")
	assert_true(panel.find_child("StateLabel", true, false).text.contains("🔒"))

	panel.free()
	screen.free()


func test_on_unlock_pressed_unlocks_and_updates_fame() -> void:
	var screen = MetaShopScreenScript.new()
	var path: String = screen._rare_card_paths()[0]
	ProfileManager.profile["fame"] = ProfileManager.RARE_CARD_UNLOCK_COST

	screen._build_ui()

	screen._on_unlock_pressed(path)

	assert_eq(ProfileManager.profile["fame"], 0)
	assert_true(ProfileManager.is_card_unlocked(load(path)))
	assert_true(screen._feedback_label.text.contains("открыта"))

	screen.free()
