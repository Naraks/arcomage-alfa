extends Node
## ArtifactManager (autoload, ARC-030): роутер эффектов артефактов по триггерам.
##
## ARC-030: раньше не был autoload и НИГДЕ не создавался в реальной игре
## (ни в одной .tscn, ни в project.godot) — GUT-тесты создавали свои экземпляры
## напрямую через ArtifactManager.new() (тогда у скрипта был class_name), но
## в самой игре ни один артефакт не мог сработать: `_ready()` (где происходит
## GameEvents.*.connect(...)) никогда не вызывался. Сделан autoload (project.godot),
## class_name убран — конфликтует с именем автозагрузки (тот же паттерн, что у
## MatchManager/GameEvents/MatchSettings/ProfileManager/RunSaveManager, ни один
## из них не объявляет class_name). Тесты (tests/test_artifact_manager.gd)
## теперь обращаются к глобальному синглтону напрямую (`ArtifactManager.foo()`),
## как и tests/test_match_manager.gd к MatchManager, а не создают отдельные
## экземпляры через .new(). Также нужен как autoload (не просто узел сцены боя) для ARC-035:
## MatchManager.play_card_by_index() (сам всегда живёт как autoload) должен
## синхронно спросить ArtifactManager ДО списания ресурсов — не сделать этого
## через сигнал/раздельные сцены.


func _ready() -> void:
	GameEvents.card_played.connect(_on_card_played)
	GameEvents.turn_started.connect(_on_turn_started)
	# ARC-033: артефакты вида "в начале боя" (Рог Изобилия).
	GameEvents.match_started.connect(_on_match_started)
	# ARC-030: артефакты вида "при получении урона" (Шипастая Стена, ARC-031).
	GameEvents.damage_applied.connect(_on_damage_taken)


func _on_card_played(card: CardData, player: PlayerData) -> void:
	_check_artifacts(player, "card_played", {"card": card})


func _on_turn_started(player: PlayerData) -> void:
	_check_artifacts(player, "turn_started")


## ARC-033: сигнал несёт обе стороны сразу — проверяем артефакты у каждой (в
## реальной игре enemy_data артефактов не имеет, active_artifacts там всегда
## пуст, но симметричная проверка не вредит и не требует знать заранее, у кого
## они есть).
func _on_match_started(player: PlayerData, enemy: PlayerData) -> void:
	_check_artifacts(player, "match_started")
	_check_artifacts(enemy, "match_started")


## ARC-030/031: target — тот, у кого могла сработать защита (владелец стены/
## башни, которую ударили), НЕ атакующий. source — атакующий (может быть null,
## см. GameEvents.damage_applied); reflect_damage (ARC-031) без source просто
## не сработает — некому отвечать.
##
## _reflecting — защита от бесконечного пинг-понга: reflect_damage сам вызывает
## MatchManager.apply_damage() на атакующего, что заново эмитит damage_applied.
## Если у ОБЕИХ сторон есть Шипастая Стена, без этой защиты урон бы отражался
## туда-сюда бесконечно. Пока идёт обработка одного отражения, новые
## on_damage_taken триггеры игнорируются (по всем игрокам, не только по
## текущей паре) — этого достаточно для одного уровня артефактов такого рода.
var _reflecting := false


func _on_damage_taken(target: Resource, amount: int, hit_wall: bool, source: Resource) -> void:
	if _reflecting:
		return
	var player_target := target as PlayerData
	if not player_target:
		return
	_check_artifacts(
		player_target, "on_damage_taken", {"amount": amount, "hit_wall": hit_wall, "attacker": source}
	)


func _check_artifacts(player: PlayerData, trigger_type: String, context: Dictionary = {}) -> void:
	for artifact in player.active_artifacts:
		for effect in artifact.effects:
			if effect.get("trigger") == trigger_type:
				apply_artifact_effect(artifact, effect, player, context)


func apply_artifact_effect(
	artifact: ArtifactData, effect: Dictionary, player: PlayerData, context: Dictionary = {}
) -> void:
	var type = effect.get("type", "")
	var value = effect.get("value", 0)

	match type:
		"mod_quarry":
			player.quarry += value
		"mod_magic":
			player.magic += value
		"mod_dungeon":
			player.dungeon += value
		"build_wall":
			player.wall_hp += value
			GameEvents.value_built.emit(player, value, "wall")
		"build_tower":
			player.tower_hp += value
			GameEvents.value_built.emit(player, value, "tower")
		"gain_resource":
			# ARC-032: {"trigger": "card_played", "type": "gain_resource",
			# "resource": "gems", "value": 1, "requires_card_type": CardData.ResourceType.GEMS}
			# requires_card_type — необязательный фильтр по типу разыгранной карты
			# (см. CardData.ResourceType: BRICKS=0, GEMS=1, BEASTS=2 — тот же порядок,
			# что уже используют .tres карт, см. data/cards/*.tres поле "type").
			# Без совпадающей карты в context (не тот триггер/тип) эффект не срабатывает.
			if effect.has("requires_card_type"):
				var played_card = context.get("card")
				if not played_card or played_card.type != effect["requires_card_type"]:
					return
			_modify_resource(player, effect.get("resource", ""), value)
		"set_generator_level":
			# ARC-033: {"trigger": "match_started", "type": "set_generator_level", "value": 2}.
			# max(), а не прямое присваивание — "становятся уровня 2" не должно ОТКАТЫВАТЬ
			# уже более высокий генератор (напр. от бонусов ProfileManager/мета-прогрессии,
			# ARC-036, или будущих карт роста): "минимум 2", а не "ровно 2".
			player.quarry = max(player.quarry, value)
			player.magic = max(player.magic, value)
			player.dungeon = max(player.dungeon, value)
		"set_max_hand_size":
			# ARC-034: {"trigger": "match_started", "type": "set_max_hand_size", "value": 6}.
			# max() по той же причине, что и set_generator_level выше.
			player.max_hand_size = max(player.max_hand_size, value)
		"reflect_damage":
			# ARC-031: {"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}.
			# Срабатывает только на удар по СТЕНЕ (hit_wall) — название артефакта и
			# формулировка акцептанс-критерия ARC-031 буквально про стену, не про
			# direct_damage мимо неё. attacker резолвится из context (см. _on_damage_taken);
			# без него (source == null, напр. урон без известного источника) — молча
			# ничего не делает, отвечать некому.
			#
			# ignore_wall=true (как у "direct_damage") — сознательное решение, не
			# буквальная часть акцептанс-критерия: ответный удар "шипов" тематически
			# мгновенный/магический, не обычная атака по стене. Если бы отражённый
			# урон сам гасился стеной атакующего, артефакт был бы почти бесполезен
			# против любого противника с ненулевой стеной — 2 урона обычно даже
			# не пробьют её. Не переотражается на защитника благодаря _reflecting
			# (ниже), даже с ignore_wall=true.
			if not context.get("hit_wall", false):
				return
			var attacker := context.get("attacker") as PlayerData
			if attacker:
				_reflecting = true
				MatchManager.apply_damage(value, attacker, true)
				_reflecting = false

	# Обновляем UI, если нужно
	GameEvents.resource_changed.emit(player, "all", 0)

	GameEvents.artifact_triggered.emit(artifact, player)
	print("[DEBUG] Artifact triggered: ", artifact.artifact_name, " effect: ", type)


const RESOURCE_NAMES := ["bricks", "gems", "beasts"]


## Тот же словарь имён, что и MatchManager._modify_resource() (не переиспользуем
## MatchManager напрямую здесь — ArtifactManager до ARC-035 не имел зависимости
## от MatchManager вообще, кроме reflect_damage выше, которому она обязательна;
## этот же метод достаточно тривиален, чтобы не тянуть его отдельно).
func _modify_resource(player: PlayerData, resource_name: String, delta: int) -> void:
	match resource_name:
		"bricks":
			player.bricks += delta
		"gems":
			player.gems += delta
		"beasts":
			player.beasts += delta


## ARC-035: "Счастливая Монета" — 10% не потратить ресурсы при розыгрыше карты.
## Вызывается из MatchManager.play_card_by_index() ДО списания стоимости (сам
## этот метод — pre-play хук, отдельный от _check_artifacts()/триггеров выше,
## т.к. должен вернуть bool синхронно, а не просто применить эффект). Если
## сработало — эмитит artifact_triggered (та же телеметрия, что у остальных
## эффектов) и возвращает true, дальше play_card_by_index() пропускает списание.
func should_skip_payment(player: PlayerData) -> bool:
	for artifact in player.active_artifacts:
		for effect in artifact.effects:
			if effect.get("trigger") == "pre_play" and effect.get("type") == "skip_payment_chance":
				var chance: float = effect.get("value", 0.0)
				if randf() < chance:
					GameEvents.artifact_triggered.emit(artifact, player)
					return true
	return false
