extends GutTest
## ARC-089 (docs/dev_plan_tickets.md, «Звуковые эффекты (SFX)») —
## core/audio_manager.gd: единая точка воспроизведения SFX.
##
## Реальное воспроизведение звука (фактический аудио-рендер) headless GUT'ом
## не проверить — как и с _draw() в curved_label.gd (см.
## tests/test_curved_label.gd), тестируем только то, что можно проверить без
## живого движка: play_sfx() создаёт/не создаёт дочерний AudioStreamPlayer с
## правильными свойствами.
##
## В отличие от большинства сцен-тестов в проекте (например
## tests/test_battle_screen.gd, где screen.new() намеренно НЕ добавляется в
## дерево, т.к. тестируемый код не трогает get_tree()) — здесь дерево нужно:
## play_sfx() сама вызывает player.play(), а AudioStreamPlayer.play() на узле
## вне дерева сцены роняет движковую ошибку "!node->is_inside_tree()", которую
## GUT засчитывает как провал теста (обнаружено по gut_results.xml с реального
## прогона в редакторе — headless-запуска в песочнице агента нет). Поэтому
## manager добавляется в дерево через add_child_autofree() — GUT сам уберёт
## его (и всех детей-AudioStreamPlayer) после теста.

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
	# Наведение мышью на несколько карт подряд не должно обрывать предыдущий
	# звук — у каждого вызова свой AudioStreamPlayer, не общий/переиспользуемый.
	var stream_a := AudioStreamWAV.new()
	var stream_b := AudioStreamWAV.new()
	manager.play_sfx(stream_a)
	manager.play_sfx(stream_b)
	assert_eq(
		manager.get_child_count(), 2, "Оба звука должны звучать одновременно, не обрывая друг друга"
	)
