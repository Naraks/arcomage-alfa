extends Node
## Воспроизведение звуковых эффектов и фоновой музыки через общую аудиошину.

## Треки чередуются по кругу в главном меню и на карте мира — оба экрана
## делят один и тот же контекст "menu", поэтому переход между ними не
## обрывает и не перезапускает музыку (см. play_menu_music).
const MENU_MUSIC_PATHS := [
	"res://audio/music/overworld_theme_1.mp3",
	"res://audio/music/overworld_theme_2.mp3",
]

## Треки чередуются по кругу во время боя (battle_screen). Отдельный контекст
## "battle" — вход в бой переключает музыку, возврат на карту/в меню
## переключает её обратно через play_menu_music().
const BATTLE_MUSIC_PATHS := [
	"res://audio/music/battle_theme_1.mp3",
	"res://audio/music/battle_theme_2.mp3",
]

const MUSIC_CROSSFADE_SECONDS := 1.5
const MUSIC_SILENT_DB := -40.0

var _pool: Array[AudioStreamPlayer] = []

var _music_player: AudioStreamPlayer
var _fading_out_player: AudioStreamPlayer
var _music_tween: Tween
var _music_playlist: Array[AudioStream] = []
var _music_index: int = 0
var _music_context: String = ""
var _music_active: bool = false


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := _acquire_player()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "Master"
	player.play()


func play_menu_music() -> void:
	## Фоновая музыка меню и карты мира.
	play_music_playlist("menu", _load_streams(MENU_MUSIC_PATHS))


func play_battle_music() -> void:
	## Фоновая музыка боя.
	play_music_playlist("battle", _load_streams(BATTLE_MUSIC_PATHS))


func play_music_playlist(context: String, playlist: Array[AudioStream]) -> void:
	## Запускает плейлист музыки под меткой context. Повторный вызов с тем же
	## context, пока музыка уже активна, — no-op (не рестартует и не дёргает трек).
	## Смена контекста (например, меню -> бой) делает плавный кроссфейд вместо
	## резкого обрыва: старый трек затихает, новый одновременно нарастает.
	if playlist.is_empty():
		return
	if _music_context == context and _music_active:
		return
	var had_previous_track := _music_active and _music_player != null
	_music_context = context
	_music_playlist = playlist
	_music_index = 0
	_music_active = true
	if had_previous_track:
		_crossfade_to_new_player()
	else:
		_ensure_music_player()
		_music_player.volume_db = 0.0
		_play_current_track()


func stop_music() -> void:
	if _music_tween:
		_music_tween.kill()
	if _music_player:
		_music_player.stop()
	if _fading_out_player:
		_fading_out_player.stop()
		_fading_out_player.queue_free()
		_fading_out_player = null
	_music_active = false
	_music_context = ""


func _ensure_music_player() -> void:
	if _music_player:
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)


func _crossfade_to_new_player() -> void:
	if _fading_out_player:
		_fading_out_player.stop()
		_fading_out_player.queue_free()
	_fading_out_player = _music_player
	_fading_out_player.finished.disconnect(_on_music_finished)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = MUSIC_SILENT_DB
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_play_current_track()

	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	_music_tween.tween_property(
		_fading_out_player, "volume_db", MUSIC_SILENT_DB, MUSIC_CROSSFADE_SECONDS
	)
	_music_tween.tween_property(_music_player, "volume_db", 0.0, MUSIC_CROSSFADE_SECONDS)
	_music_tween.chain().tween_callback(_on_crossfade_finished)


func _on_crossfade_finished() -> void:
	if _fading_out_player:
		_fading_out_player.stop()
		_fading_out_player.queue_free()
		_fading_out_player = null


func _play_current_track() -> void:
	if _music_playlist.is_empty():
		return
	_music_player.stream = _music_playlist[_music_index]
	_music_player.play()


func _on_music_finished() -> void:
	if _music_playlist.is_empty():
		return
	_music_index = (_music_index + 1) % _music_playlist.size()
	_play_current_track()


func _load_streams(paths: Array) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	for path in paths:
		var stream := load(path) as AudioStream
		if stream:
			streams.append(stream)
	return streams


func _acquire_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	var player := AudioStreamPlayer.new()
	add_child(player)
	_pool.append(player)
	return player
