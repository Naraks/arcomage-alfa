class_name CardData
extends Resource
## Данные игровой карты.

enum ResourceType { BRICKS, GEMS, BEASTS }

enum Rarity { COMMON, UNCOMMON, RARE }

@export_group("Visuals")
@export var card_name: String = "New Card"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var card_art: Texture2D

@export_group("Logic")
@export var cost: int = 1
@export var type: ResourceType = ResourceType.BRICKS
@export var rarity: Rarity = Rarity.COMMON

@export var effects: Array[EffectData] = []


## card_name/description хранят стабильные ключи локализации (см.
## docs/localization_guide.md), а не текст для показа игроку напрямую —
## отображать нужно через эти геттеры.
func get_display_name() -> String:
	return tr(card_name)


func get_display_description() -> String:
	return tr(description)
