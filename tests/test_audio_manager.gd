extends GutTest
## Тесты воспроизведения звуков.

const AudioManagerScript = preload("res://core/audio_manager.gd")

var manager: Node


func before_each() -> void:
	manager = AudioManagerScript.new()
	add_child_autofree(manager)


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
