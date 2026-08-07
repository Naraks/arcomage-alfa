extends GutTest
## Юнит-тесты ARC-046, UI 03/13 (#98): ProfileScreen — единая оболочка с
## общей шапкой, адаптивной навигацией и встроенными под-сценами.
## Каждая
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
const ProfileScreenScript = preload("res://ui/profile/profile_screen.gd")
const MetaShopScreenScript = preload("res://ui/meta_shop/meta_shop_screen.gd")
const StatsScreenScript = preload("res://ui/stats/stats_screen.gd")
const DeckScreenScript = preload("res://ui/deck/deck_screen.gd")

var _saved_profile: Dictionary


func before_each() -> void:
	_saved_profile = ProfileManager.profile.duplicate(true)
	ProfileManager.profile = {
		"fame": 1280,
		"unlocked_cards": [],
		"unlocked_artifacts": [],
		"upgrades": {},
	}
	ProfileScreenScript._last_tab_index = 0


func after_each() -> void:
	ProfileManager.profile = _saved_profile


func test_tab_container_has_three_tabs_in_expected_order() -> void:
	var screen = ProfileScreenScene.instantiate()
	var tabs: TabContainer = screen.get_node("Tabs")

	assert_eq(tabs.get_tab_count(), 3)
	assert_eq(tabs.get_tab_title(0), "Прокачка")
	assert_eq(tabs.get_tab_title(1), "Статистика")
	assert_eq(tabs.get_tab_title(2), "Колода")

	screen.free()


func test_subscreens_use_embedded_mode_without_duplicate_shells() -> void:
	var screen = ProfileScreenScene.instantiate()
	var tabs: TabContainer = screen.get_node("Tabs")

	for index in range(tabs.get_tab_count()):
		assert_true(tabs.get_child(index).embedded_in_profile)

	screen.free()


func test_layout_uses_sidebar_on_desktop_and_bottom_tabs_on_mobile() -> void:
	var screen = ProfileScreenScene.instantiate()

	assert_eq(screen._layout_mode_for_size(Vector2(1280, 720)), "desktop")
	assert_eq(screen._layout_mode_for_size(Vector2(720, 1280)), "mobile")

	screen.free()


func test_switching_tabs_preserves_single_scene_instances_and_active_state() -> void:
	var screen = ProfileScreenScene.instantiate()
	add_child_autoqfree(screen)
	await wait_process_frames(2)
	var tabs: TabContainer = screen.get_node("Tabs")
	var original_children := tabs.get_children()

	assert_true(screen._select_tab(2))
	assert_eq(tabs.current_tab, 2)
	assert_eq(tabs.get_children(), original_children, "Переключение не создаёт копии сцен")
	assert_eq(screen._last_tab_index, 2)
	assert_eq(ProfileManager.profile.fame, 1280, "Переключение не сбрасывает данные профиля")
	assert_false(screen._select_tab(99))
	assert_true(screen._side_buttons[2].button_pressed, "Активный раздел явно выделен")

	var restored = ProfileScreenScene.instantiate()
	add_child_autoqfree(restored)
	await wait_process_frames(2)
	assert_eq(restored.get_node("Tabs").current_tab, 2, "Активная вкладка восстанавливается")


func test_shared_header_state_contains_profile_fame_and_collection_progress() -> void:
	var screen = ProfileScreenScene.instantiate()

	assert_eq(screen._profile_identifier(), "Локальный профиль")
	assert_true("карты 0/" in screen._collection_progress_text())
	assert_true("артефакты 0/" in screen._collection_progress_text())

	screen.free()


func test_runtime_shell_has_focusable_touch_navigation_and_one_back_button() -> void:
	var screen = ProfileScreenScene.instantiate()
	add_child_autoqfree(screen)
	await wait_process_frames(2)

	assert_eq(screen._side_buttons.size(), 3)
	assert_eq(screen._bottom_buttons.size(), 3)
	for button in screen._side_buttons + screen._bottom_buttons:
		assert_eq(button.focus_mode, Control.FOCUS_ALL)
		assert_true(button.custom_minimum_size.y >= 44.0)
	var back_button: Button = screen.find_child("BackButton", true, false)
	assert_not_null(back_button)
	assert_true(back_button.custom_minimum_size.y >= 44.0)
	assert_true(back_button.pressed.is_connected(screen._on_back_pressed))
	assert_eq(_count_labels_with_text(screen, "ПРОФИЛЬ"), 1)
	assert_eq(_count_buttons_with_text(screen, "← Назад"), 1)
	assert_eq(_count_labels_with_text(screen, "МАГАЗИН ПРОКАЧКИ"), 0)

	screen._apply_layout(Vector2(720, 1280))
	assert_true(screen._bottom_nav.visible)
	assert_false(screen._side_nav.visible)
	assert_true(screen._tabs.offset_left >= 0)
	assert_true(screen._tabs.offset_right <= 0)


func _count_labels_with_text(root: Node, text: String) -> int:
	var count := 0
	for child in root.find_children("*", "Label", true, false):
		if child.text == text:
			count += 1
	return count


func _count_buttons_with_text(root: Node, text: String) -> int:
	var count := 0
	for child in root.find_children("*", "Button", true, false):
		if child.text == text:
			count += 1
	return count


func test_tabs_reuse_existing_screen_scripts_without_duplicating_logic() -> void:
	var screen = ProfileScreenScene.instantiate()
	var tabs: TabContainer = screen.get_node("Tabs")

	assert_eq(tabs.get_child(0).get_script(), MetaShopScreenScript)
	assert_eq(tabs.get_child(1).get_script(), StatsScreenScript)
	assert_eq(tabs.get_child(2).get_script(), DeckScreenScript)

	screen.free()
