extends Node
## Мета-прогрессия, настройки и сохранение профиля.

const DEFAULT_SETTINGS := {"volume": 1.0}
const RARE_CARD_UNLOCK_COST := 150

const UPGRADE_CATALOG := {
	"tower":
	{
		"name": "Прочный Фундамент",
		"desc": "Стартовая Башня +%d",
		"per_level": 3,
		"max_level": 5,
		"base_cost": 60,
		"cost_step": 40,
	},
	"wall":
	{
		"name": "Крепостная Стена",
		"desc": "Стартовая Стена +%d",
		"per_level": 3,
		"max_level": 5,
		"base_cost": 60,
		"cost_step": 40,
	},
	"quarry":
	{
		"name": "Мастерство Кирпичей",
		"desc": "Генератор Кирпичей +%d",
		"per_level": 1,
		"max_level": 5,
		"base_cost": 80,
		"cost_step": 50,
	},
	"magic":
	{
		"name": "Мастерство Гемов",
		"desc": "Генератор Гемов +%d",
		"per_level": 1,
		"max_level": 5,
		"base_cost": 80,
		"cost_step": 50,
	},
	"dungeon":
	{
		"name": "Мастерство Зверей",
		"desc": "Генератор Зверей +%d",
		"per_level": 1,
		"max_level": 5,
		"base_cost": 80,
		"cost_step": 50,
	},
	"hand_size":
	{
		"name": "Вместительная Рука",
		"desc": "Лимит карт в руке +%d",
		"per_level": 1,
		"max_level": 3,
		"base_cost": 100,
		"cost_step": 80,
	},
}

var profile: Dictionary = {
	"total_wins": 0,
	"unlocked_artifacts": [],
	"fame": 0,
	"upgrades": {},
	"unlocked_cards": [],
	"settings": DEFAULT_SETTINGS.duplicate(true),
	"total_runs": 0,
	"max_tower_height": 0,
}


func _ready() -> void:
	load_profile()
	_apply_volume_to_audio_server(get_volume())
	GameEvents.match_ended.connect(_on_match_ended)


func _on_match_ended(_winner: Resource) -> void:
	if not MatchManager.player_data:
		return
	var height: int = MatchManager.player_data.tower_hp
	if height > profile.get("max_tower_height", 0):
		profile["max_tower_height"] = height
		save_profile()


func add_fame(amount: int) -> void:
	profile["fame"] = profile.get("fame", 0) + amount
	save_profile()


func record_run_finished(victory: bool) -> void:
	profile["total_runs"] = profile.get("total_runs", 0) + 1
	if victory:
		profile["total_wins"] = profile.get("total_wins", 0) + 1
	save_profile()


func record_artifact_collected(artifact: ArtifactData) -> void:
	var collected: Array = profile.get("unlocked_artifacts", [])
	if not collected.has(artifact.resource_path):
		collected.append(artifact.resource_path)
		profile["unlocked_artifacts"] = collected
		save_profile()


func get_upgrade_level(key: String) -> int:
	return profile.get("upgrades", {}).get(key, 0)


func get_upgrade_bonus(key: String) -> int:
	if not UPGRADE_CATALOG.has(key):
		return 0
	return get_upgrade_level(key) * UPGRADE_CATALOG[key]["per_level"]


func get_upgrade_next_cost(key: String) -> int:
	var def: Dictionary = UPGRADE_CATALOG.get(key, {})
	if def.is_empty():
		return -1
	var level := get_upgrade_level(key)
	if level >= def["max_level"]:
		return -1
	return def["base_cost"] + level * def["cost_step"]


func can_afford_upgrade(key: String) -> bool:
	var cost := get_upgrade_next_cost(key)
	return cost >= 0 and profile.get("fame", 0) >= cost


func purchase_upgrade(key: String) -> bool:
	if not can_afford_upgrade(key):
		return false
	var cost := get_upgrade_next_cost(key)
	profile["fame"] = profile.get("fame", 0) - cost
	var upgrades: Dictionary = profile.get("upgrades", {})
	upgrades[key] = upgrades.get(key, 0) + 1
	profile["upgrades"] = upgrades
	save_profile()
	return true


func is_card_unlocked(card: CardData) -> bool:
	if card.rarity != CardData.Rarity.RARE:
		return true
	return profile.get("unlocked_cards", []).has(card.resource_path)


func get_card_unlock_cost(card: CardData) -> int:
	if is_card_unlocked(card):
		return -1
	return RARE_CARD_UNLOCK_COST


func can_afford_card_unlock(card: CardData) -> bool:
	var cost := get_card_unlock_cost(card)
	return cost >= 0 and profile.get("fame", 0) >= cost


func unlock_card(card: CardData) -> bool:
	if not can_afford_card_unlock(card):
		return false
	profile["fame"] = profile.get("fame", 0) - RARE_CARD_UNLOCK_COST
	var unlocked: Array = profile.get("unlocked_cards", [])
	unlocked.append(card.resource_path)
	profile["unlocked_cards"] = unlocked
	save_profile()
	return true


func get_volume() -> float:
	return float(profile.get("settings", {}).get("volume", 1.0))


func set_volume(value: float) -> void:
	var clamped: float = clamp(value, 0.0, 1.0)
	var settings: Dictionary = profile.get("settings", {})
	settings["volume"] = clamped
	profile["settings"] = settings
	_apply_volume_to_audio_server(clamped)
	save_profile()


func reset_settings() -> void:
	profile["settings"] = DEFAULT_SETTINGS.duplicate(true)
	_apply_volume_to_audio_server(get_volume())
	save_profile()


func _apply_volume_to_audio_server(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func save_profile() -> void:
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(profile)
		file.store_string(json_string)
		print("[DEBUG] Profile saved")


func load_profile() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			profile = _restore_int_types(json.data)
			print("[DEBUG] Profile loaded")


func _restore_int_types(value):
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _restore_int_types(value[key])
		return result
	if value is Array:
		var result := []
		for item in value:
			result.append(_restore_int_types(item))
		return result
	if value is float and value == floor(value):
		return int(value)
	return value
