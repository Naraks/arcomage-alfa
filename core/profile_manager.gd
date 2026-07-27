extends Node

## ProfileManager: Управляет мета-прогрессией и сохранениями
class_name ProfileManager

var profile: Dictionary = {
	"total_wins": 0,
	"unlocked_artifacts": [],
	"player_stats": {
		"tower_hp_bonus": 5,
		"resource_gain_bonus": 1
	}
}

func _ready() -> void:
	load_profile()

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
			profile = json.data
			print("[DEBUG] Profile loaded")
