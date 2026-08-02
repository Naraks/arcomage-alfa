extends GutTest
## ARC-089 (docs/dev_plan_tickets.md, «Звуковые эффекты (SFX)») —
## core/audio_manager.gd: единая точка воспроизведения SFX.
##
## Реальное воспроизведение звука (AudioStreamPlayer.play(), фактический
## аудио-рендер) headless GUT'ом не проверить — как и с _draw() в
## curved_label.gd (см. tests/test_curved_label.gd), тестируем только то, что
## можно проверить без живого движка: play_sfx() создаёт/не создаёт дочерний
## AudioStreamPlayer с правильными свойствами. Экземпляр AudioManager не
## добавляется в дерево сцены (как и остальные тесты в этом проекте — см.
## tests/test_battle_screen.gd) — Node.add_child() на свободный (вне дерева)
## узел работать не мешает, а .play() внутри play_sfx() тестами не проверяем.

const AudioManagerScript = preload("res://core/audio_manager.gd")

var manager: Node


func before_each() -> void:
	manager = AudioManagerScript.new()


func after_each() -> void:
	manager.free()


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
	# Наведение мышью на несколько карт подряд не должно обрывать предыдущий
	# звук — у каждого вызова свой AudioStreamPlayer, не общий/переиспользуемый.
	var stream_a := AudioStreamWAV.new()
	var stream_b := AudioStreamWAV.new()
	manager.play_sfx(stream_a)
	manager.play_sfx(stream_b)
	assert_eq(
		manager.get_child_count(), 2, "Оба звука должны звучать одновременно, не обрывая друг друга"
	)
