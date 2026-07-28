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


# --- ARC-038: is_card_unlocked / get_card_unlock_cost / unlock_card ---

## ФЕЙКОВЫЙ путь, не указывающий на реальный .tres — намеренно, НЕ путь
## настоящей RARE-карты вроде "res://data/cards/gem_10.tres". Присвоение
## card.resource_path = <путь, уже занятый другим загруженным ресурсом в
## ResourceCache> валит движок ("Method/function failed") — а к моменту, как
## этот файл тестов выполняется, gem_10.tres/brick_1.tres почти наверняка уже
## реально загружены где-то ещё (test_reward_screen.gd/test_meta_shop_screen.gd
## и т.п., GUT гоняет все файлы в одном процессе). Синтетическая CardData.new()
## здесь никогда не грузится через load() — ей нужна просто уникальная
## строка-ключ для bookkeeping в profile.unlocked_cards, не настоящий файл.
const _FAKE_RARE_CARD_PATH := "res://data/cards/__test_only_fake_rare_card__.tres"


func _make_card(rarity: int, path: String = "") -> CardData:
	var card := CardData.new()
	card.rarity = rarity
	card.card_name = "Тестовая карта"
	card.resource_path = path
	return card


func test_is_card_unlocked_true_for_non_rare_by_default() -> void:
	var card := _make_card(CardData.Rarity.COMMON)

	assert_true(ProfileManager.is_card_unlocked(card))


func test_is_card_unlocked_false_for_rare_by_default() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)

	assert_false(ProfileManager.is_card_unlocked(card))


func test_is_card_unlocked_true_for_rare_after_being_added_to_unlocked_cards() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["unlocked_cards"] = [_FAKE_RARE_CARD_PATH]

	assert_true(ProfileManager.is_card_unlocked(card))


func test_get_card_unlock_cost_negative_one_for_non_rare() -> void:
	var card := _make_card(CardData.Rarity.UNCOMMON)

	assert_eq(ProfileManager.get_card_unlock_cost(card), -1)


func test_get_card_unlock_cost_is_rare_unlock_cost_for_locked_rare() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)

	assert_eq(ProfileManager.get_card_unlock_cost(card), ProfileManager.RARE_CARD_UNLOCK_COST)


func test_get_card_unlock_cost_negative_one_for_already_unlocked_rare() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["unlocked_cards"] = [_FAKE_RARE_CARD_PATH]

	assert_eq(ProfileManager.get_card_unlock_cost(card), -1)


func test_can_afford_card_unlock_false_without_enough_fame() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["fame"] = 0

	assert_false(ProfileManager.can_afford_card_unlock(card))


func test_can_afford_card_unlock_true_with_enough_fame() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["fame"] = ProfileManager.RARE_CARD_UNLOCK_COST

	assert_true(ProfileManager.can_afford_card_unlock(card))


func test_unlock_card_deducts_fame_and_adds_to_unlocked_cards() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["fame"] = ProfileManager.RARE_CARD_UNLOCK_COST + 5

	var result := ProfileManager.unlock_card(card)

	assert_true(result)
	assert_eq(ProfileManager.profile["fame"], 5)
	assert_true(ProfileManager.is_card_unlocked(card))


func test_unlock_card_fails_without_enough_fame() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["fame"] = 0

	var result := ProfileManager.unlock_card(card)

	assert_false(result)
	assert_eq(ProfileManager.profile["fame"], 0)
	assert_false(ProfileManager.is_card_unlocked(card))


func test_unlock_card_fails_for_non_rare_card() -> void:
	var card := _make_card(CardData.Rarity.COMMON, "res://data/cards/__test_only_fake_common_card__.tres")
	ProfileManager.profile["fame"] = 999999

	var result := ProfileManager.unlock_card(card)

	assert_false(result, "Не-RARE карта уже 'разблокирована' — покупать нечего")


func test_unlock_card_fails_when_already_unlocked() -> void:
	var card := _make_card(CardData.Rarity.RARE, _FAKE_RARE_CARD_PATH)
	ProfileManager.profile["unlocked_cards"] = [_FAKE_RARE_CARD_PATH]
	ProfileManager.profile["fame"] = 999999
	var fame_before: int = ProfileManager.profile["fame"]

	var result := ProfileManager.unlock_card(card)

	assert_false(result)
	assert_eq(ProfileManager.profile["fame"], fame_before, "Повторная покупка не должна списывать Славу")


# --- ARC-042: get_volume / set_volume ---


func test_get_volume_defaults_to_one_without_settings_key() -> void:
	ProfileManager.profile = {"fame": 0}

	assert_eq(ProfileManager.get_volume(), 1.0)


func test_get_volume_reads_from_profile_settings() -> void:
	ProfileManager.profile["settings"] = {"volume": 0.4}

	assert_eq(ProfileManager.get_volume(), 0.4)


func test_set_volume_stores_value_in_profile_settings() -> void:
	ProfileManager.set_volume(0.6)

	assert_eq(ProfileManager.get_volume(), 0.6)


func test_set_volume_clamps_above_one() -> void:
	ProfileManager.set_volume(3.5)

	assert_eq(ProfileManager.get_volume(), 1.0)


func test_set_volume_clamps_below_zero() -> void:
	ProfileManager.set_volume(-2.0)

	assert_eq(ProfileManager.get_volume(), 0.0)


func test_set_volume_applies_to_master_audio_bus() -> void:
	ProfileManager.set_volume(0.5)

	var bus_index := AudioServer.get_bus_index("Master")
	assert_almost_eq(AudioServer.get_bus_volume_db(bus_index), linear_to_db(0.5), 0.001)


func test_volume_persists_across_save_and_load() -> void:
	ProfileManager.set_volume(0.25)

	# Подменяем profile целиком (другим значением громкости) перед load_profile(),
	# чтобы доказать, что 0.25 реально пришёл с диска, а не просто уцелел в
	# памяти — тот же приём, что test_save_and_load_round_trip_preserves_fame_and_upgrades.
	ProfileManager.profile = {"fame": 0, "settings": {"volume": 0.9}}

	ProfileManager.load_profile()

	assert_eq(ProfileManager.get_volume(), 0.25)
