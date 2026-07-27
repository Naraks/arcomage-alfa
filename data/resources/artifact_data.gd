class_name ArtifactData
extends Resource

@export var artifact_name: String = "New Artifact"
@export_multiline var description: String = ""
@export var icon: Texture2D

## Эффекты артефакта. Пример: {"type": "mod_quarry", "value": 1}
@export var effects: Array[Dictionary] = []
