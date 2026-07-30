extends GutTest
## Юнит-тесты ARC-046: ProfileScreen — единый экран с TabContainer, каждая
## вкладка которого переиспользует уже существующую и уже покрытую тестами
## под-сцену (Прокачка = meta_shop_screen.tscn, Статистика = stats_screen.tscn,
## Коллекция = deck_screen.tscn). Здесь тестируется только сама компоновка
## (порядок и подписи вкладок, что каждая вкладка — инстанс ожидаемого
## скрипта), не логика вложенных экранов — та уже покрыта их собственными
## test_*_screen.gd файлами.
##
## Экземпляр создаётся через preload(".tscn").instantiate() без добавления в
## дерево сцены — как и во вложенных экранах, ни один _ready() здесь не
## трогает get_tree() (только их _on_back_pressed(), не вызываемые тестом).

const ProfileScreenScene = preload("res://ui/profile/profile_screen.tscn")
const MetaShopScreenScript = preload("res://ui/meta_shop/meta_shop_screen.gd")
const StatsScreenScript = preload("res://ui/stats/stats_screen.gd")
const DeckScreenScript = preload("res://ui/deck/deck_screen.gd")


func test_tab_container_has_three_tabs_in_expected_order() -> void:
	var screen = ProfileScreenScene.instantiate()
	var tabs: TabContainer = screen.get_node("Tabs")

	assert_eq(tabs.get_tab_count(), 3)
	assert_eq(tabs.get_tab_title(0), "Прокачка")
	assert_eq(tabs.get_tab_title(1), "Статистика")
	assert_eq(tabs.get_tab_title(2), "Коллекция")

	screen.free()


func test_tabs_reuse_existing_screen_scripts_without_duplicating_logic() -> void:
	var screen = ProfileScreenScene.instantiate()
	var tabs: TabContainer = screen.get_node("Tabs")

	assert_eq(tabs.get_child(0).get_script(), MetaShopScreenScript)
	assert_eq(tabs.get_child(1).get_script(), StatsScreenScript)
	assert_eq(tabs.get_child(2).get_script(), DeckScreenScript)

	screen.free()
