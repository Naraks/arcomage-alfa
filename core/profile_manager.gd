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
## неоправданное дублирование. upgrades — новое поле, реально отсутствовавшее:
## структура под будущее дерево прокачки (ARC-037), пока всегда пустой словарь.
var profile: Dictionary = {
	"total_wins": 0,
	"unlocked_artifacts": [],
	"player_stats": {"tower_hp_bonus": 5, "resource_gain_bonus": 1},
	"fame": 0,
	"upgrades": {},
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
