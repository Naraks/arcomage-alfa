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


# --- ARC-037: UPGRADE_CATALOG / get_upgrade_* / purchase_upgrade ---


func test_get_upgrade_level_defaults_to_zero_without_purchases() -> void:
	assert_eq(ProfileManager.get_upgrade_level("tower"), 0)


func test_get_upgrade_level_reads_from_profile_upgrades() -> void:
	ProfileManager.profile["upgrades"] = {"tower": 3}

	assert_eq(ProfileManager.get_upgrade_level("tower"), 3)


func test_get_upgrade_bonus_is_level_times_per_level() -> void:
	ProfileManager.profile["upgrades"] = {"quarry": 2}

	assert_eq(ProfileManager.get_upgrade_bonus("quarry"), 2 * ProfileManager.UPGRADE_CATALOG["quarry"]["per_level"])


func test_get_upgrade_bonus_unknown_key_is_zero() -> void:
	assert_eq(ProfileManager.get_upgrade_bonus("not_a_real_upgrade"), 0)


func test_get_upgrade_next_cost_at_level_zero_is_base_cost() -> void:
	assert_eq(ProfileManager.get_upgrade_next_cost("wall"), ProfileManager.UPGRADE_CATALOG["wall"]["base_cost"])


func test_get_upgrade_next_cost_grows_with_level() -> void:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["wall"]
	ProfileManager.profile["upgrades"] = {"wall": 2}

	assert_eq(ProfileManager.get_upgrade_next_cost("wall"), def["base_cost"] + 2 * def["cost_step"])


func test_get_upgrade_next_cost_is_negative_one_at_max_level() -> void:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["hand_size"]
	ProfileManager.profile["upgrades"] = {"hand_size": def["max_level"]}

	assert_eq(ProfileManager.get_upgrade_next_cost("hand_size"), -1)


func test_get_upgrade_next_cost_unknown_key_is_negative_one() -> void:
	assert_eq(ProfileManager.get_upgrade_next_cost("not_a_real_upgrade"), -1)


func test_can_afford_upgrade_false_when_not_enough_fame() -> void:
	ProfileManager.profile["fame"] = 0

	assert_false(ProfileManager.can_afford_upgrade("tower"))


func test_can_afford_upgrade_true_when_enough_fame() -> void:
	ProfileManager.profile["fame"] = ProfileManager.UPGRADE_CATALOG["tower"]["base_cost"]

	assert_true(ProfileManager.can_afford_upgrade("tower"))


func test_can_afford_upgrade_false_at_max_level_even_with_fame() -> void:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["hand_size"]
	ProfileManager.profile["upgrades"] = {"hand_size": def["max_level"]}
	ProfileManager.profile["fame"] = 999999

	assert_false(ProfileManager.can_afford_upgrade("hand_size"))


func test_purchase_upgrade_deducts_fame_and_increments_level() -> void:
	var cost: int = ProfileManager.UPGRADE_CATALOG["tower"]["base_cost"]
	ProfileManager.profile["fame"] = cost + 10

	var result := ProfileManager.purchase_upgrade("tower")

	assert_true(result)
	assert_eq(ProfileManager.profile["fame"], 10)
	assert_eq(ProfileManager.get_upgrade_level("tower"), 1)


func test_purchase_upgrade_fails_and_changes_nothing_without_enough_fame() -> void:
	ProfileManager.profile["fame"] = 0

	var result := ProfileManager.purchase_upgrade("tower")

	assert_false(result)
	assert_eq(ProfileManager.profile["fame"], 0)
	assert_eq(ProfileManager.get_upgrade_level("tower"), 0)


func test_purchase_upgrade_fails_at_max_level() -> void:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["hand_size"]
	ProfileManager.profile["upgrades"] = {"hand_size": def["max_level"]}
	ProfileManager.profile["fame"] = 999999

	var result := ProfileManager.purchase_upgrade("hand_size")

	assert_false(result)
	assert_eq(ProfileManager.get_upgrade_level("hand_size"), def["max_level"])


func test_purchase_upgrade_next_cost_increases_after_purchase() -> void:
	var def: Dictionary = ProfileManager.UPGRADE_CATALOG["tower"]
	ProfileManager.profile["fame"] = def["base_cost"]
	var cost_before := ProfileManager.get_upgrade_next_cost("tower")

	ProfileManager.purchase_upgrade("tower")

	assert_eq(ProfileManager.get_upgrade_next_cost("tower"), cost_before + def["cost_step"])
