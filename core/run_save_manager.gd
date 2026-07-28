extends Node
## RunSaveManager (ARC-018): автосохранение состояния текущего забега в
## user://, чтобы «Продолжить» в главном меню (main_menu.gd) могло поднять
## забег после закрытия/перезагрузки вкладки браузера — см.
## docs/dev_plan_tickets.md, ARC-018.
##
## Сохраняется через ResourceSaver (не JSON, как ProfileManager) — состояние
## забега это граф Resource-ов (WorldMapData.map_nodes с перекрёстными
## connected_nodes) плюс карты/артефакты, уже загруженные как Resource из
## data/cards|artifacts/*.tres. ResourceSaver сам корректно сериализует both:
## процедурно созданные MapNodeData (без resource_path — сохраняются как
## вложенные под-ресурсы прямо в run_save.tres, включая разделяемые ссылки
## между connected_nodes) и карты/артефакты (у них resource_path уже указывает
## на res://data/..., поэтому они сохраняются как ссылка на исходный файл, а
## не дублируются). Ручной JSON-сериализатор графа узлов был бы существенно
## сложнее и хрупче ради того же результата.

const SAVE_PATH := "user://run_save.tres"


func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Сборка снимка из MatchSettings — чистая функция без обращения к диску,
## отдельная от save_run() специально, чтобы юнит-тесты могли проверить
## маппинг полей, не трогая файловую систему (см. tests/test_run_save_manager.gd).
func build_save_data() -> RunSaveData:
	var data := RunSaveData.new()
	data.world_map_data = MatchSettings.world_map_data
	data.run_deck = MatchSettings.run_deck.duplicate()
	data.run_gold = MatchSettings.run_gold
	data.run_tower_bonus = MatchSettings.run_tower_bonus
	data.run_quarry_bonus = MatchSettings.run_quarry_bonus
	data.run_magic_bonus = MatchSettings.run_magic_bonus
	data.run_dungeon_bonus = MatchSettings.run_dungeon_bonus
	data.run_artifacts = MatchSettings.run_artifacts.duplicate()
	return data


## Обратная операция — раскладывает снимок обратно в MatchSettings. Тоже
## чистая (без диска), тестируется отдельно от load_run().
func apply_save_data(data: RunSaveData) -> void:
	MatchSettings.world_map_data = data.world_map_data
	MatchSettings.run_deck = data.run_deck
	MatchSettings.run_gold = data.run_gold
	MatchSettings.run_tower_bonus = data.run_tower_bonus
	MatchSettings.run_quarry_bonus = data.run_quarry_bonus
	MatchSettings.run_magic_bonus = data.run_magic_bonus
	MatchSettings.run_dungeon_bonus = data.run_dungeon_bonus
	MatchSettings.run_artifacts = data.run_artifacts


## Вызывается из world_map_screen._ready() — то есть при каждом попадании на
## карту: и сразу после генерации нового забега, и при возврате с любого узла
## (shop/rest/event/reward уже выставляют is_completed/current_node_index и
## сбрасывают current_map_node в null ДО перехода сюда — см. их
## _on_back_pressed()/_return_to_map()). Из этого места это покрывает
## акцептанс-критерий "после каждого узла карты" без отдельного вызова в
## каждом из 4 screen'ов.
func save_run() -> void:
	if not MatchSettings.world_map_data:
		return
	var data := build_save_data()
	var error := ResourceSaver.save(data, SAVE_PATH)
	if error != OK:
		print("[ERROR] RunSaveManager: failed to save run, code ", error)


## true — успешно восстановлено (MatchSettings уже обновлён), false — сейва
## нет или он повреждён (тогда MatchSettings не трогаем).
func load_run() -> bool:
	if not has_saved_run():
		return false

	# CACHE_MODE_IGNORE — иначе повторная загрузка в той же игровой сессии
	# (например, после отладочного save_run() без рестарта игры) может
	# вернуть устаревший закэшированный ресурс вместо содержимого файла.
	var data = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if data == null or not (data is RunSaveData):
		print("[ERROR] RunSaveManager: saved run is missing or corrupted")
		return false

	apply_save_data(data)
	return true


## Забег закончился (победа/поражение босса — run_summary_screen.gd,
## единственная точка выхода) — сейв больше не должен предлагаться.
func clear_run() -> void:
	if has_saved_run():
		DirAccess.remove_absolute(SAVE_PATH)
