extends Resource
class_name ArtifactData

@export var artifact_name: String = "New Artifact"
@export_multiline var description: String = ""
@export var icon: Texture2D

## Эффекты артефакта. Пример: {"type": "mod_quarry", "value": 1}
@export var effects: Array[Dictionary] = []
