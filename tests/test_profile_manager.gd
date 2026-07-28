extends GutTest
## Юнит-тесты ProfileManager.add_fame() (ARC-017). ProfileManager — autoload,
## тесты приводят profile к известному состоянию в before_each() и
## восстанавливают в after_each(), как test_match_manager.gd делает для
## MatchManager.

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
