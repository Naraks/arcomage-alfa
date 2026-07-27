extends Resource
class_name AIStrategy

# Базовый класс для всех стратегий ИИ
func get_best_card(_hand: Array[CardData], _actor: Resource, _enemy: Resource) -> CardData:
	return null

func can_afford(card: CardData, actor: Resource) -> bool:
	match card.type:
		CardData.ResourceType.BRICKS: return actor.bricks >= card.cost
		CardData.ResourceType.GEMS: return actor.gems >= card.cost
		CardData.ResourceType.BEASTS: return actor.beasts >= card.cost
	return false
