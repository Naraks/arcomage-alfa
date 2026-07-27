class_name BuildVersion
extends Node
## Версия сборки (ARC-069). CI пишет res://build_version.json перед экспортом
## (см. .github/workflows/ci.yml), используя `git describe --tags` на теге вида
## vX.Y.Z. В редакторе/локальных запусках файла нет — используются значения
## по умолчанию ниже, отображается как "dev".

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


## Короткая строка для UI ("v0.1.0 (a1b2c3d)") и багрепортов от плейтестеров.
func get_display_string() -> String:
	if commit.is_empty():
		return version
	return "%s (%s)" % [version, commit]
