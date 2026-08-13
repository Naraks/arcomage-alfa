extends GutTest
## Тесты паузы при потере фокуса.

const FocusPauseManagerScript = preload("res://core/focus_pause_manager.gd")


func before_each() -> void:
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false


func test_focus_out_pauses_and_focus_in_resumes_tree() -> void:
	var manager = FocusPauseManagerScript.new()
	add_child_autoqfree(manager)

	manager._set_application_focused(false)
	assert_true(get_tree().paused)
	assert_true(manager.is_paused_by_focus())

	manager._set_application_focused(true)
	assert_false(get_tree().paused)
	assert_false(manager.is_paused_by_focus())


func test_focus_return_does_not_cancel_pause_owned_by_another_system() -> void:
	var manager = FocusPauseManagerScript.new()
	add_child_autoqfree(manager)
	get_tree().paused = true

	manager._set_application_focused(false)
	manager._set_application_focused(true)

	assert_true(get_tree().paused, "Менеджер не должен снимать чужую игровую паузу")
	assert_false(manager.is_paused_by_focus())


func test_repeated_focus_notifications_are_idempotent() -> void:
	var manager = FocusPauseManagerScript.new()
	add_child_autoqfree(manager)

	manager._set_application_focused(false)
	manager._set_application_focused(false)
	manager._set_application_focused(true)
	manager._set_application_focused(true)

	assert_false(get_tree().paused)
	assert_false(manager.is_paused_by_focus())


func test_ai_turn_timer_stops_while_tree_is_paused() -> void:
	var timer := MatchManager._create_ai_turn_timer(0.3)
	get_tree().paused = true
	var time_before := timer.time_left

	for i in range(5):
		await get_tree().process_frame

	assert_eq(
		timer.time_left, time_before, "Таймер ИИ не должен идти в фоне"
	)
	get_tree().paused = false
	await timer.timeout
	assert_true(timer.time_left <= 0.0, "После возврата фокуса таймер должен завершиться")
