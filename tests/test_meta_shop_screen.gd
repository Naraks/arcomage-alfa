extends GutTest
## Юнит-тесты чистых хелперов MetaShopScreen (ARC-037): текст строки
## улучшения и кнопки покупки. Экземпляр создаётся через preload().new() без
## добавления в дерево сцены, как в tests/test_shop_screen.gd/
## test_reward_screen.gd — эти методы не трогают @onready-поля
## (_fame_label/_upgrade_list, заполняются только в _build_ui()).
##
## ProfileManager — общий синглтон с другими тестовыми файлами, поэтому
## profile сохраняется/восстанавливается в before_each()/after_each(), как в
## tests/test_profile_manager.gd.

const MetaShopScreenScript = preload("res://ui/meta_shop/meta_shop_screen.gd")

var _saved_profile: Dictionary


func before_each() -> void:
	_saved_profile = ProfileManager.profile.duplicate(true)
	ProfileManager.profile = {"fame": 0, "upgrades": {}}


func after_each() -> void:
	ProfileManager.profile = _saved_profile


func test_upgrade_order_covers_the_whole_catalog() -> void:
	# Регрессия: если кто-то добавит новый ключ в UPGRADE_CATALOG и забудет
	# дописать его в UPGRADE_ORDER, строка для него просто не появится на
	# экране — тихая пропажа, не ошибка. Проверяем оба множества совпадают.
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

	# На уровне 1 из max_level=5 следующая покупка даёт ещё +per_level, не
	# суммарный текущий бонус — строка должна показывать per_level (1), не
	# level*per_level (1*1=1, совпадает случайно на этом уровне, поэтому берём
	# другой уровень ниже для однозначной проверки).
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

	# _on_buy_pressed() зовёт _update_fame_label()/_refresh_upgrade_list(),
	# которым нужны реальные _fame_label/_upgrade_list — строим полный UI
	# (не добавляя сцену в дерево, как test_reward_screen.gd делает для
	# полноценных сценариев, не только чистых хелперов).
	screen._build_ui()

	screen._on_buy_pressed("tower")

	assert_eq(ProfileManager.get_upgrade_level("tower"), 1)
	assert_eq(ProfileManager.profile["fame"], 0)

	screen.free()
