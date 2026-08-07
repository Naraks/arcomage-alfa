extends Node
## Загрузка и отображение версии сборки.

const VERSION_FILE := "res://build_version.json"

var version: String = "dev"
var commit: String = ""
var built_at: String = ""


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(VERSION_FILE):
		return

	var file := FileAccess.open(VERSION_FILE, FileAccess.READ)
	if not file:
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return

	version = data.get("version", version)
	commit = data.get("commit", commit)
	built_at = data.get("built_at", built_at)


func get_display_string() -> String:
	if commit.is_empty():
		return version
	return "%s (%s)" % [version, commit]
