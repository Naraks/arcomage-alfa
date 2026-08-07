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

	assert_eq(text, "Купить за %d" % ProfileManager.UPGRADE_CATALOG["wall"]["base_cost"])

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
	var buy_button: Button = row.get_node("BuyButton")

	assert_true(buy_button.disabled)

	row.free()
	screen.free()


func test_make_upgrade_row_enables_buy_button_with_enough_fame() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = ProfileManager.UPGRADE_CATALOG["tower"]["base_cost"]

	var row := screen._make_upgrade_row("tower")
	var buy_button: Button = row.get_node("BuyButton")

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
	var unlock_button: Button = row.get_node("UnlockButton")

	assert_true(unlock_button.disabled)

	row.free()
	screen.free()


func test_make_unlock_row_enables_button_with_enough_fame() -> void:
	var screen = MetaShopScreenScript.new()
	ProfileManager.profile["fame"] = ProfileManager.RARE_CARD_UNLOCK_COST
	var path: String = screen._rare_card_paths()[0]

	var row := screen._make_unlock_row(path)
	var unlock_button: Button = row.get_node("UnlockButton")

	assert_false(unlock_button.disabled)

	row.free()
	screen.free()


func test_make_unlock_row_disables_button_when_already_unlocked() -> void:
	var screen = MetaShopScreenScript.new()
	var path: String = screen._rare_card_paths()[0]
	ProfileManager.profile["unlocked_cards"] = [path]
	ProfileManager.profile["fame"] = 999999

	var row := screen._make_unlock_row(path)
	var unlock_button: Button = row.get_node("UnlockButton")

	assert_true(unlock_button.disabled, "Уже открытую карту нельзя купить повторно")

	row.free()
	screen.free()


func test_on_unlock_pressed_unlocks_and_updates_fame() -> void:
	var screen = MetaShopScreenScript.new()
	var path: String = screen._rare_card_paths()[0]
	ProfileManager.profile["fame"] = ProfileManager.RARE_CARD_UNLOCK_COST

	screen._build_ui()

	screen._on_unlock_pressed(path)

	assert_eq(ProfileManager.profile["fame"], 0)
	assert_true(ProfileManager.is_card_unlocked(load(path)))

	screen.free()
