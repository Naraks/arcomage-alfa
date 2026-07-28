extends GutTest
## Юнит-тесты чистых хелперов SettingsScreen (ARC-042). Экземпляр создаётся
## через preload().new() без добавления в дерево сцены, как в
## tests/test_shop_screen.gd — _volume_percent_text() не трогает
## @onready-поля (_volume_slider/_volume_value_label, заполняются только в
## _build_ui()).
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


func test_on_volume_changed_updates_profile_manager() -> void:
	var screen = SettingsScreenScript.new()
	# _on_volume_changed() зовёт ProfileManager.set_volume() напрямую (не
	# трогает @onready-поля кроме _volume_value_label) — строим полный UI,
	# как test_meta_shop_screen.gd делает для _on_buy_pressed().
	screen._build_ui()

	screen._on_volume_changed(0.3)

	assert_eq(ProfileManager.get_volume(), 0.3)

	screen.free()
