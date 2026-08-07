extends GutTest
## Юнит-тесты SettingsScreen (ARC-042, UI 04/13): загрузка текущего значения,
## применение/сохранение, подтверждаемый сброс и доступные размеры контролов.
##
## ProfileManager — общий синглтон с другими тестовыми файлами (см.
## tests/test_profile_manager.gd), поэтому profile сохраняется/
## восстанавливается в before_each()/after_each().

const SettingsScreenScript = preload("res://ui/settings/settings_screen.gd")

var _saved_profile: Dictionary


func before_each() -> void:
	_saved_profile = ProfileManager.profile.duplicate(true)
	ProfileManager.profile = {"fame": 0, "settings": {"volume": 1.0}}


func after_each() -> void:
	ProfileManager.profile = _saved_profile


func test_volume_percent_text_at_zero() -> void:
	var screen = SettingsScreenScript.new()

	assert_eq(screen._volume_percent_text(0.0), "0%")

	screen.free()


func test_volume_percent_text_at_full() -> void:
	var screen = SettingsScreenScript.new()

	assert_eq(screen._volume_percent_text(1.0), "100%")

	screen.free()


func test_volume_percent_text_rounds_instead_of_truncating() -> void:
	var screen = SettingsScreenScript.new()

	# 0.95 * 100 = 94.999... из-за погрешности float — round(), не int()/floor(),
	# должен всё равно дать "95%", не "94%".
	assert_eq(screen._volume_percent_text(0.95), "95%")

	screen.free()


func test_panel_width_fits_portrait_and_is_capped_on_wide_screen() -> void:
	var screen = SettingsScreenScript.new()

	assert_eq(screen._panel_width_for_viewport(Vector2(360, 640)), 328.0)
	assert_eq(screen._panel_width_for_viewport(Vector2(1280, 720)), 720.0)

	screen.free()


func test_on_volume_changed_updates_profile_manager() -> void:
	var screen = SettingsScreenScript.new()
	# _on_volume_changed() зовёт ProfileManager.set_volume() напрямую (не
	# трогает @onready-поля кроме _volume_value_label) — строим полный UI,
	# как test_meta_shop_screen.gd делает для _on_buy_pressed().
	screen._build_ui()

	screen._on_volume_changed(0.3)

	assert_eq(ProfileManager.get_volume(), 0.3)

	screen.free()


func test_build_ui_loads_saved_volume_into_slider_and_label() -> void:
	ProfileManager.profile["settings"]["volume"] = 0.65
	var screen = SettingsScreenScript.new()
	screen._build_ui()

	assert_eq(screen._volume_slider.value, 0.65)
	assert_eq(screen._volume_value_label.text, "65%")
	assert_eq(screen._volume_slider.focus_mode, Control.FOCUS_ALL)
	assert_true(screen._volume_slider.custom_minimum_size.y >= 44.0)

	screen.free()


func test_reset_confirmation_explains_scope_and_starts_hidden() -> void:
	var screen = SettingsScreenScript.new()
	screen._build_ui()

	assert_false(screen._reset_confirmation.visible)
	assert_true("громкость" in screen._reset_summary_text())
	assert_true("100%" in screen._reset_summary_text())

	screen._show_reset_confirmation()
	assert_true(screen._reset_confirmation.visible)

	screen.free()


func test_confirm_reset_restores_defaults_without_touching_progress() -> void:
	ProfileManager.profile["fame"] = 120
	ProfileManager.profile["settings"]["volume"] = 0.25
	var screen = SettingsScreenScript.new()
	screen._build_ui()

	screen._confirm_reset()

	assert_eq(ProfileManager.get_volume(), 1.0)
	assert_eq(screen._volume_slider.value, 1.0)
	assert_eq(screen._volume_value_label.text, "100%")
	assert_eq(ProfileManager.profile["fame"], 120, "Сброс не должен затрагивать прогресс")
	assert_false(screen._reset_confirmation.visible)

	screen.free()


func test_runtime_layout_keeps_settings_panel_visible() -> void:
	var screen = SettingsScreenScript.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autoqfree(screen)
	await wait_frames(2)

	var panel := screen.find_child("SettingsPanel", true, false) as Control
	var scroll := screen.find_child("SettingsScroll", true, false) as Control
	assert_not_null(panel)
	assert_not_null(scroll)
	assert_true(panel.is_visible_in_tree())
	assert_true(scroll.size.x > 0.0, "Область прокрутки не должна схлопываться по ширине")
	assert_true(scroll.size.y > 0.0, "Область прокрутки не должна схлопываться по высоте")
	assert_true(panel.size.x > 0.0, "Панель должна иметь ненулевую ширину в дереве сцены")
	assert_true(panel.size.y > 0.0, "Панель должна иметь ненулевую высоту в дереве сцены")
