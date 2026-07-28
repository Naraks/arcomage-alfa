extends Node
## ProfileManager (ARC-001): управляет мета-прогрессией и сохранениями.
## Автозагружен под именем ProfileManager (см. [autoload] в project.godot) —
## этого достаточно для глобального доступа, поэтому class_name здесь не
## ставим: он конфликтует с именем автозагрузки и роняет её загрузку с
## "hides an autoload singleton" (тот же баг уже был и починен в
## core/build_version.gd, см. ARC-069).

var profile: Dictionary = {
	"total_wins": 0,
	"unlocked_artifacts": [],
	"player_stats": {"tower_hp_bonus": 5, "resource_gain_bonus": 1},
	"fame": 0,
}


func _ready() -> void:
	load_profile()


## ARC-017: Слава — постоянная мета-валюта (design doc 9.1), начисляется по
## итогам каждого забега (ui/run_summary/run_summary_screen.gd). profile.get()
## с дефолтом — на случай старого save-файла без ключа "fame" (load_profile()
## целиком заменяет profile содержимым JSON, см. ниже).
func add_fame(amount: int) -> void:
	profile["fame"] = profile.get("fame", 0) + amount
	save_profile()


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
