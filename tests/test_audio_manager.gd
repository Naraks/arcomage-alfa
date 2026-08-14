extends GutTest
## Тесты воспроизведения звуков.

const AudioManagerScript = preload("res://core/audio_manager.gd")

var manager: Node


func before_each() -> void:
	manager = AudioManagerScript.new()
	add_child_autofree(manager)


func _playlist(streams: Array) -> Array[AudioStream]:
	var typed_streams: Array[AudioStream] = []
	typed_streams.assign(streams)
	return typed_streams


func test_play_sfx_with_null_stream_adds_no_children() -> void:
	manager.play_sfx(null)
	assert_eq(manager.get_child_count(), 0)


func test_play_sfx_creates_audio_stream_player_with_correct_properties() -> void:
	var stream := AudioStreamWAV.new()
	manager.play_sfx(stream, -6.0)
	assert_eq(manager.get_child_count(), 1)
	var player: AudioStreamPlayer = manager.get_child(0)
	assert_eq(player.stream, stream)
	assert_eq(player.volume_db, -6.0)
	assert_eq(player.bus, "Master")


func test_play_sfx_default_volume_is_zero_db() -> void:
	var stream := AudioStreamWAV.new()
	manager.play_sfx(stream)
	var player: AudioStreamPlayer = manager.get_child(0)
	assert_eq(player.volume_db, 0.0)


func test_play_sfx_supports_multiple_overlapping_calls() -> void:
	var stream_a := AudioStreamWAV.new()
	var stream_b := AudioStreamWAV.new()
	manager.play_sfx(stream_a)
	manager.play_sfx(stream_b)
	assert_eq(
		manager.get_child_count(), 2, "Оба звука должны звучать одновременно, не обрывая друг друга"
	)


func test_play_music_playlist_with_empty_array_does_nothing() -> void:
	manager.play_music_playlist("menu", _playlist([]))
	assert_eq(manager.get_child_count(), 0)


func test_play_music_playlist_starts_first_track_on_master_bus() -> void:
	var track_a := AudioStreamGenerator.new()
	var track_b := AudioStreamGenerator.new()
	manager.play_music_playlist("menu", _playlist([track_a, track_b]))
	assert_eq(manager.get_child_count(), 1)
	var player: AudioStreamPlayer = manager.get_child(0)
	assert_eq(player.stream, track_a)
	assert_eq(player.bus, "Master")


func test_play_music_playlist_repeat_call_same_context_is_noop() -> void:
	var track_a := AudioStreamGenerator.new()
	var track_b := AudioStreamGenerator.new()
	manager.play_music_playlist("menu", _playlist([track_a, track_b]))
	manager.play_music_playlist("menu", _playlist([track_a, track_b]))
	assert_eq(
		manager.get_child_count(),
		1,
		"Повторный вызов с тем же контекстом (переход между экранами) не должен пересоздавать плеер"
	)


func test_music_finished_advances_to_next_track_and_loops() -> void:
	var track_a := AudioStreamGenerator.new()
	var track_b := AudioStreamGenerator.new()
	manager.play_music_playlist("menu", _playlist([track_a, track_b]))
	var player: AudioStreamPlayer = manager.get_child(0)
	assert_eq(player.stream, track_a)
	manager._on_music_finished()
	assert_eq(player.stream, track_b, "После окончания первого трека должен включиться второй")
	manager._on_music_finished()
	assert_eq(player.stream, track_a, "Плейлист должен зациклиться на первый трек")


func test_stop_music_resets_active_state() -> void:
	var track_a := AudioStreamGenerator.new()
	manager.play_music_playlist("menu", _playlist([track_a]))
	assert_true(manager._music_active)
	manager.stop_music()
	assert_false(manager._music_active)


func test_play_music_playlist_different_context_switches_track() -> void:
	var track_a := AudioStreamGenerator.new()
	var track_b := AudioStreamGenerator.new()
	manager.play_music_playlist("menu", _playlist([track_a]))
	manager.play_music_playlist("battle", _playlist([track_b]))
	assert_eq(manager._music_player.stream, track_b, "Смена контекста должна переключить трек")


func test_context_switch_crossfades_instead_of_cutting_old_track() -> void:
	var track_a := AudioStreamGenerator.new()
	var track_b := AudioStreamGenerator.new()
	manager.play_music_playlist("menu", _playlist([track_a]))
	var menu_player: AudioStreamPlayer = manager.get_child(0)
	manager.play_music_playlist("battle", _playlist([track_b]))
	assert_eq(
		manager.get_child_count(),
		2,
		"На время кроссфейда старый и новый плеер должны звучать одновременно"
	)
	assert_eq(manager._fading_out_player, menu_player, "Старый плеер становится затухающим")
	assert_eq(manager._music_player.stream, track_b)
	assert_almost_eq(
		manager._music_player.volume_db,
		AudioManagerScript.MUSIC_SILENT_DB,
		0.01,
		"Новый трек стартует беззвучно и нарастает по tween'у"
	)


func test_crossfade_finished_stops_and_frees_old_player() -> void:
	manager.play_music_playlist("menu", _playlist([AudioStreamGenerator.new()]))
	manager.play_music_playlist("battle", _playlist([AudioStreamGenerator.new()]))
	assert_not_null(manager._fading_out_player)
	manager._on_crossfade_finished()
	assert_null(
		manager._fading_out_player, "После завершения кроссфейда старый плеер освобождается"
	)


func test_play_battle_music_uses_battle_context() -> void:
	manager.play_menu_music()
	manager.play_battle_music()
	assert_eq(manager._music_context, "battle")
	manager.play_menu_music()
	assert_eq(
		manager._music_context, "menu", "Возврат в меню/на карту должен переключить музыку обратно"
	)
