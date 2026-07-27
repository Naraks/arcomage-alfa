class_name CardData
extends Resource

enum ResourceType { BRICKS, GEMS, BEASTS }

@export_group("Visuals")
@export var card_name: String = "New Card"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Logic")
@export var cost: int = 1
@export var type: ResourceType = ResourceType.BRICKS

## Список эффектов. Пример: {"type": "damage", "value": 5, "target": "enemy_wall"}
## Формат ключей "type"/"target" и то, что реально на что влияет — см. effects_reference.md (ARC-005).
@export var effects: Array[Dictionary] = []
