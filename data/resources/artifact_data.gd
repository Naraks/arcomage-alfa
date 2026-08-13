class_name ArtifactData
extends Resource
## Данные артефакта.

@export var artifact_name: String = "New Artifact"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var effects: Array[EffectData] = []


## artifact_name/description хранят стабильные ключи локализации, не текст
## для показа напрямую — см. docs/localization_guide.md.
func get_display_name() -> String:
	return tr(artifact_name)


func get_display_description() -> String:
	return tr(description)
