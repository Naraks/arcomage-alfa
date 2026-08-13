extends Node
## Воспроизведение звуковых эффектов через общую аудиошину.

var _pool: Array[AudioStreamPlayer] = []


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := _acquire_player()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "Master"
	player.play()


func _acquire_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	var player := AudioStreamPlayer.new()
	add_child(player)
	_pool.append(player)
	return player
