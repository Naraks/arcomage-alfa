class_name TestFixtures
extends RefCounted
## Общие тестовые фикстуры (ARC-074).
##
## Юнит-тесты ядра (MatchManager, ArtifactManager) не должны зависеть от боевого
## контента в data/cards/*.tres — та каталог часто меняется из-за баланса
## (см. Эпик C), и это сделало бы тесты хрупкими к правкам, никак не связанным
## с логикой, которую тест проверяет. Вместо load()/preload() реальных .tres
## тесты строят CardData/PlayerData/ArtifactData прямо здесь, с предсказуемыми
## значениями, не привязанными к конкретному контенту.
##
## Файл называется без префикса test_, поэтому GUT (.gutconfig.json, prefix
## "test_") не подхватывает его как отдельный test suite — это обычный
## вспомогательный скрипт, доступный по class_name из любого теста в tests/.
##
## Единственное легитимное исключение из правила "не читать data/cards/*.tres
## в тестах ядра" — отдельный контент-тест из ARC-019, который по своей сути
## обязан проверять реальные карты.


## PlayerData с безопасными дефолтами для тестов боя (они совпадают со значениями
## по умолчанию в PlayerData — здесь они явные и именованные, чтобы тест не
## зависел от того, не поменяются ли дефолты в самом PlayerData).
## overrides — словарь "имя_поля": значение, применяется поверх дефолтов, например
## make_player({"wall_hp": 0, "quarry": 3}).
static func make_player(overrides: Dictionary = {}) -> PlayerData:
	var player := PlayerData.new()
	player.tower_hp = 20
	player.wall_hp = 5
	player.bricks = 5
	player.gems = 5
	player.beasts = 5
	player.quarry = 1
	player.magic = 1
	player.dungeon = 1
	player.max_hand_size = 5
	for key in overrides:
		player.set(key, overrides[key])
	return player


## CardData с указанными стоимостью/ресурсом/эффектами — не читается из .tres.
static func make_card(
	cost: int, type: CardData.ResourceType, effects: Array[Dictionary] = []
) -> CardData:
	var card := CardData.new()
	card.cost = cost
	card.type = type
	card.effects = effects
	return card


## ArtifactData с указанными эффектами — не читается из .tres.
static func make_artifact(effects: Array[Dictionary] = []) -> ArtifactData:
	var artifact := ArtifactData.new()
	artifact.effects = effects
	return artifact
