extends Node
## Сохранение и восстановление текущего забега.

const SAVE_PATH := "user://run_save.tres"


func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


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


func apply_save_data(data: RunSaveData) -> void:
	MatchSettings.world_map_data = data.world_map_data
	MatchSettings.run_deck = data.run_deck
	MatchSettings.run_gold = data.run_gold
	MatchSettings.run_tower_bonus = data.run_tower_bonus
	MatchSettings.run_quarry_bonus = data.run_quarry_bonus
	MatchSettings.run_magic_bonus = data.run_magic_bonus
	MatchSettings.run_dungeon_bonus = data.run_dungeon_bonus
	MatchSettings.run_artifacts = data.run_artifacts


func save_run() -> void:
	if not MatchSettings.world_map_data:
		return
	var data := build_save_data()
	var error := ResourceSaver.save(data, SAVE_PATH)
	if error != OK:
		push_error("RunSaveManager: не удалось сохранить забег, код ", error)


func load_run() -> bool:
	if not has_saved_run():
		return false

	var data: Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if data == null or not (data is RunSaveData):
		push_error("RunSaveManager: сохранение забега отсутствует или повреждено")
		return false

	if data.save_version != RunSaveData.CURRENT_VERSION:
		push_warning(
			(
				"RunSaveManager: версия сохранения забега (%d) не совпадает с текущей (%d) — миграция не выполнена"
				% [data.save_version, RunSaveData.CURRENT_VERSION]
			)
		)

	apply_save_data(data)
	return true


func clear_run() -> void:
	if has_saved_run():
		DirAccess.remove_absolute(SAVE_PATH)
