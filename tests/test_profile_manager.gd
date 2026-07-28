extends GutTest
## Юнит-тесты ProfileManager.add_fame() (ARC-017) и структуры
## currency/upgrades (ARC-036). ProfileManager — autoload, тесты приводят
## profile к известному состоянию в before_each() и восстанавливают в
## after_each(), как test_match_manager.gd делает для MatchManager.

var _saved_profile: Dictionary


func before_each() -> void:
	_saved_profile = ProfileManager.profile.duplicate(true)
	ProfileManager.profile = {"fame": 0}


func after_each() -> void:
	ProfileManager.profile = _saved_profile


func test_add_fame_increments_from_zero() -> void:
	ProfileManager.add_fame(50)

	assert_eq(ProfileManager.profile["fame"], 50)


func test_add_fame_accumulates_across_calls() -> void:
	ProfileManager.add_fame(50)
	ProfileManager.add_fame(30)

	assert_eq(ProfileManager.profile["fame"], 80)


func test_add_fame_handles_missing_key_in_old_profile() -> void:
	# Регрессия: старый save-файл может не содержать "fame" вообще, если
	# load_profile() целиком заменил profile содержимым JSON без этого ключа.
	ProfileManager.profile = {"total_wins": 3}

	ProfileManager.add_fame(20)

	assert_eq(ProfileManager.profile["fame"], 20)


# --- ARC-036: profile.currency (= fame, см. комментарий в profile_manager.gd) / upgrades ---


func test_default_profile_has_currency_and_upgrades_fields() -> void:
	# Свежий экземпляр скрипта (не сам синглтон — у него profile уже мог быть
	# подменён другими тестами/load_profile()), не добавлен в дерево — _ready()
	# (а значит и load_profile()) не вызывается, значение поля — буквально
	# объявленный по умолчанию словарь.
	var pm = preload("res://core/profile_manager.gd").new()

	assert_true(pm.profile.has("fame"), "fame выполняет роль profile.currency из акцептанс-критерия ARC-036")
	assert_true(pm.profile.has("upgrades"))
	assert_eq(pm.profile["upgrades"], {})

	pm.free()


func test_save_and_load_round_trip_preserves_fame_and_upgrades() -> void:
	ProfileManager.profile = {"fame": 42, "upgrades": {"wall_tier": 2, "unlock_dragon": true}}
	ProfileManager.save_profile()

	ProfileManager.profile = {"fame": 0}
	ProfileManager.load_profile()

	assert_eq(ProfileManager.profile["fame"], 42)
	assert_eq(ProfileManager.profile["upgrades"], {"wall_tier": 2, "unlock_dragon": true})
