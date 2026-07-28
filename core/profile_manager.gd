extends Node
## ProfileManager (ARC-001): управляет мета-прогрессией и сохранениями.
## Автозагружен под именем ProfileManager (см. [autoload] в project.godot) —
## этого достаточно для глобального доступа, поэтому class_name здесь не
## ставим: он конфликтует с именем автозагрузки и роняет её загрузку с
## "hides an autoload singleton" (тот же баг уже был и починен в
## core/build_version.gd, см. ARC-069).

## ARC-036: profile.currency из акцептанс-критерия — это уже существующий
## "fame" (Слава), а не новое поле. "fame" реализован в ARC-017 и по факту
## является постоянной мета-валютой из game_design_doc.md §9.1 ("Слава ...
## принципиально отдельна от золота забега"); заводить второе, параллельное
## поле currency с тем же смыслом под именем из черновика тикета ("Золото/
## Эссенция", устарело — дизайн-док впоследствии остановился на "Слава") —
## неоправданное дублирование. upgrades — теперь реально используемое поле
## (ARC-037): {upgrade_key: level}, level по умолчанию 0 для любого ключа
## (см. get_upgrade_level ниже).
##
## ARC-037: "player_stats" (tower_hp_bonus=5, resource_gain_bonus=1) убран —
## это был плоский, всегда включённый бонус-заглушка ещё с ARC-001, до того
## как появился настоящий магазин прокачки. Теперь тот же бонус (и ещё 4
## новых) — часть UPGRADE_CATALOG ниже, покупается за Славу, начинается с
## уровня 0 (без бонуса). Сознательный даунгрейд "бесплатного" стартового
## бонуса в "заработанный" — так и задуман прогресс-магазин; см. блокквот
## ARC-037 в dev_plan_tickets.md.
var profile: Dictionary = {
	"total_wins": 0,
	"unlocked_artifacts": [],
	"fame": 0,
	"upgrades": {},
	"unlocked_cards": [],
}

## ARC-038: правило блокировки — просто CardData.rarity == RARE. Никакого
## отдельного списка "какие пути залочены" не заводим (ещё один список,
## который надо было бы вручную поддерживать в синхроне с data/cards/*.tres —
## именно та болезнь, что чинили в ARC-024): редкость уже читается прямо из
## ресурса карты, единственного источника истины. profile.unlocked_cards
## хранит resource_path уже купленных RARE-карт; всё, что НЕ RARE, всегда
## доступно и никогда не появляется в этом списке.
##
## Заодно закрывает пробел, отмеченный (но отложенный) в комментарии у
## MatchManager.ALL_CARD_PATHS ещё с ARC-020: пул карт был общим для всех
## редкостей, и RARE-карты могли выпасть в награду обычного боя/магазин
## наравне с Common/Uncommon, хотя design doc §5.3 явно резервирует RARE за
## "награда за элитный бой/босса, мета-разблокировки". С фильтром по
## is_card_unlocked() (см. MatchManager.build_shop_offer(),
## ui/reward/reward_screen.gd) это по конструкции больше не может произойти.
const RARE_CARD_UNLOCK_COST := 150

## ARC-037: каталог покупаемых мета-улучшений — общий источник и для
## MetaShopScreen (что показывать и почём), и для MatchManager.setup_match()
## (какой бонус применить к PlayerData). "per_level" — прибавка за один
## купленный уровень; "max_level" — сколько уровней всего можно купить;
## цена уровня (level+1) = base_cost + level*cost_step (линейный рост, не
## экспонента — с base_cost/cost_step/max_level ниже цена макс. уровня
## остаётся в разумных пределах десятка забегов, а не сотен).
##
## "quarry"/"magic"/"dungeon" — конкретная реализация категории "Мастерство
## ресурсов" из game_design_doc.md §9.2 (там пример — "+10% урона картам
## определённого типа"). Выбрал бонус генератора вместо множителя урона:
## это то же самое "усилить всё, что связано с ресурсом X" по духу, но не
## требует трогать интерпретатор эффектов карт (apply_card_effects) —
## осознанно меньший объём работы при сохранении сути критерия приёмки
## ("реально влияющих на setup_match()").
const UPGRADE_CATALOG := {
	"tower": {
		"name": "Прочный Фундамент",
		"desc": "Стартовая Башня +%d",
		"per_level": 3,
		"max_level": 5,
		"base_cost": 60,
		"cost_step": 40,
	},
	"wall": {
		"name": "Крепостная Стена",
		"desc": "Стартовая Стена +%d",
		"per_level": 3,
		"max_level": 5,
		"base_cost": 60,
		"cost_step": 40,
	},
	"quarry": {
		"name": "Мастерство Кирпичей",
		"desc": "Генератор Кирпичей +%d",
		"per_level": 1,
		"max_level": 5,
		"base_cost": 80,
		"cost_step": 50,
	},
	"magic": {
		"name": "Мастерство Гемов",
		"desc": "Генератор Гемов +%d",
		"per_level": 1,
		"max_level": 5,
		"base_cost": 80,
		"cost_step": 50,
	},
	"dungeon": {
		"name": "Мастерство Зверей",
		"desc": "Генератор Зверей +%d",
		"per_level": 1,
		"max_level": 5,
		"base_cost": 80,
		"cost_step": 50,
	},
	"hand_size": {
		"name": "Вместительная Рука",
		"desc": "Лимит карт в руке +%d",
		"per_level": 1,
		"max_level": 3,
		"base_cost": 100,
		"cost_step": 80,
	},
}


func _ready() -> void:
	load_profile()


## ARC-017: Слава — постоянная мета-валюта (design doc 9.1), начисляется по
## итогам каждого забега (ui/run_summary/run_summary_screen.gd). profile.get()
## с дефолтом — на случай старого save-файла без ключа "fame" (load_profile()
## целиком заменяет profile содержимым JSON, см. ниже).
func add_fame(amount: int) -> void:
	profile["fame"] = profile.get("fame", 0) + amount
	save_profile()


## ARC-037: текущий купленный уровень улучшения key (0, если ни разу не
## покупалось, или ключ вообще не из UPGRADE_CATALOG — тот же дефолтный "0",
## что и для отсутствующего ключа, разницы вызывающему коду не нужно).
func get_upgrade_level(key: String) -> int:
	return profile.get("upgrades", {}).get(key, 0)


## Бонус к соответствующему полю PlayerData, который должен применить
## MatchManager.setup_match() — уровень * per_level. 0 для неизвестного key.
func get_upgrade_bonus(key: String) -> int:
	if not UPGRADE_CATALOG.has(key):
		return 0
	return get_upgrade_level(key) * UPGRADE_CATALOG[key]["per_level"]


## Цена СЛЕДУЮЩЕГО уровня (перехода level -> level+1); -1, если key не из
## каталога или уже на максимальном уровне — "покупать больше нечего".
func get_upgrade_next_cost(key: String) -> int:
	var def: Dictionary = UPGRADE_CATALOG.get(key, {})
	if def.is_empty():
		return -1
	var level := get_upgrade_level(key)
	if level >= def["max_level"]:
		return -1
	return def["base_cost"] + level * def["cost_step"]


func can_afford_upgrade(key: String) -> bool:
	var cost := get_upgrade_next_cost(key)
	return cost >= 0 and profile.get("fame", 0) >= cost


## Покупка следующего уровня улучшения key: списывает Славу, поднимает
## profile.upgrades[key] на 1, сохраняет профиль. Возвращает false и НИЧЕГО
## не меняет, если key неизвестен каталогу, уже на максимуме или не хватает
## Славы (can_afford_upgrade() покрывает оба случая через get_upgrade_next_cost()
## == -1).
func purchase_upgrade(key: String) -> bool:
	if not can_afford_upgrade(key):
		return false
	var cost := get_upgrade_next_cost(key)
	profile["fame"] = profile.get("fame", 0) - cost
	var upgrades: Dictionary = profile.get("upgrades", {})
	upgrades[key] = upgrades.get(key, 0) + 1
	profile["upgrades"] = upgrades
	save_profile()
	return true


## ARC-038: не-RARE карты всегда разблокированы (никогда не требуют
## покупки). RARE — только если её resource_path уже в profile.unlocked_cards.
## card без resource_path (напр. CardData.new() в тестах, без .tres-файла)
## никогда не будет найден в unlocked_cards — для RARE это "всегда
## заблокирована", что нормально: у синтетических тестовых карт нет
## реального пути для разблокировки, но обычно они и не RARE (rarity по
## умолчанию COMMON), так что на практике это не мешает.
func is_card_unlocked(card: CardData) -> bool:
	if card.rarity != CardData.Rarity.RARE:
		return true
	return profile.get("unlocked_cards", []).has(card.resource_path)


## Цена разблокировки card: RARE_CARD_UNLOCK_COST, если она RARE и ещё не
## куплена; -1, если её вообще не нужно (не RARE) или уже куплена — "нечего
## покупать", тот же контракт по -1, что и у get_upgrade_next_cost().
func get_card_unlock_cost(card: CardData) -> int:
	if is_card_unlocked(card):
		return -1
	return RARE_CARD_UNLOCK_COST


func can_afford_card_unlock(card: CardData) -> bool:
	var cost := get_card_unlock_cost(card)
	return cost >= 0 and profile.get("fame", 0) >= cost


## Покупка разблокировки card: списывает Славу, добавляет resource_path в
## profile.unlocked_cards, сохраняет профиль. false и ничего не меняет, если
## нечего покупать (не RARE/уже разблокирована) или не хватает Славы.
func unlock_card(card: CardData) -> bool:
	if not can_afford_card_unlock(card):
		return false
	profile["fame"] = profile.get("fame", 0) - RARE_CARD_UNLOCK_COST
	var unlocked: Array = profile.get("unlocked_cards", [])
	unlocked.append(card.resource_path)
	profile["unlocked_cards"] = unlocked
	save_profile()
	return true


func save_profile() -> void:
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(profile)
		file.store_string(json_string)
		print("[DEBUG] Profile saved")


func load_profile() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			profile = _restore_int_types(json.data)
			print("[DEBUG] Profile loaded")


## ARC-036: JSON.parse() в Godot возвращает АБСОЛЮТНО ВСЕ числа как float —
## формат JSON сам по себе не различает int/float, и движок не пытается
## угадать. Без этого прохода "fame"/"total_wins"/значения в "upgrades" (по
## смыслу всегда целые — счётчики, уровни прокачки) после каждой перезагрузки
## профиля тихо превращались бы в float (2 -> 2.0). Само по себе `2 == 2.0`
## в GDScript истинно, но строгое сравнение словарей (тесты; в будущем —
## сравнение уровня апгрейда в match/switch-подобной логике ARC-037) уже
## различает их. Рекурсивно приводит float без дробной части к int во
## вложенных Dictionary/Array; в profile нет полей, которым намеренно нужна
## именно дробная точность, так что это допущение безопасно для всего дерева.
func _restore_int_types(value):
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _restore_int_types(value[key])
		return result
	if value is Array:
		var result := []
		for item in value:
			result.append(_restore_int_types(item))
		return result
	if value is float and value == floor(value):
		return int(value)
	return value
