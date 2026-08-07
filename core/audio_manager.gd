extends Node
## Воспроизведение звуковых эффектов через общую аудиошину.


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
