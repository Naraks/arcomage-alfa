class_name CardData
extends Resource

enum ResourceType { BRICKS, GEMS, BEASTS }

## ARC-015: где карта встречается (стартовая колода/магазин/награда) —
## docs/game_design_doc.md 5.3. Пока используется только наградой за бой
## (ui/reward/reward_screen.gd); дефолт COMMON — все существующие карты до
## этого поля были неявно "обычными".
enum Rarity { COMMON, UNCOMMON, RARE }

@export_group("Visuals")
@export var card_name: String = "New Card"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Logic")
@export var cost: int = 1
@export var type: ResourceType = ResourceType.BRICKS
@export var rarity: Rarity = Rarity.COMMON

## Список эффектов. Пример: {"type": "damage", "value": 5, "target": "enemy_wall"}
## Формат ключей "type"/"target" и то, что реально на что влияет — см. docs/effects_reference.md (ARC-005).
@export var effects: Array[Dictionary] = []
