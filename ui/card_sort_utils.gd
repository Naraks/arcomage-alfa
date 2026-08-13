class_name CardSortUtils
extends RefCounted
## Общая сортировка карт для отображения: тип → цена → имя.

static func compare_by_type_cost_name(a: CardData, b: CardData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.card_name < b.card_name
