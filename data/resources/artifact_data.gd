class_name ArtifactData
extends Resource
## Данные артефакта.

@export var artifact_name: String = "New Artifact"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var effects: Array[EffectData] = []
