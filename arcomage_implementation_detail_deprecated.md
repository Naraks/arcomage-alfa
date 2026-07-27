# Детальный план реализации: Arcomage Roguelike

Этот документ описывает техническую реализацию игры на движке Godot 4.3+.

## 1. Архитектура данных (Resources)

Вместо жесткого кодирования карт в скриптах, используем `Resource` для гибкости.

### 1.1 Базовый класс карты (`CardData.gd`)
```gdscript
extends Resource
class_name CardData

enum ResourceType { BRICKS, GEMS, BEASTS }

@export var card_name: String
@export var cost: int
@export var type: ResourceType
@export var icon: Texture2D
@export_multiline var description: String

# Эффекты (используем массив словарей или спец. объекты)
@export var effects: Array[Dictionary] = [
	{"type": "damage", "value": 10, "target": "enemy_tower"},
	{"type": "build", "value": 5, "target": "self_wall"}
]
```

### 1.2 Система Артефактов (`ArtifactData.gd`)
```gdscript
extends Resource
class_name ArtifactData

@export var artifact_name: String
@export var description: String
@export var icon: Texture2D

# Триггеры для системы событий
enum Trigger { ON_TURN_START, ON_CARD_PLAYED, ON_DAMAGE_TAKEN }
@export var trigger: Trigger
```

---

## 2. Логика боя (MatchManager)

Центральный узел (`MatchManager.gd`), управляющий состоянием игры.

### 2.1 Машина состояний (FSM)
- `START_MATCH`: Инициализация параметров, генерация колод.
- `PLAYER_TURN`: Ожидание ввода игрока (выбор карты).
- `PROCESS_CARD`: Анимация и применение эффектов.
- `AI_TURN`: Работа алгоритма противника.
- `CHECK_WIN`: Проверка HP башен или лимита ресурсов.
- `END_MATCH`: Переход к наградам.

### 2.2 Обработка урона
```gdscript
func apply_damage(amount: int, target_player: PlayerData, ignore_wall: bool = false):
	if ignore_wall:
		target_player.tower_hp -= amount
	else:
		var remaining_damage = amount - target_player.wall_hp
		target_player.wall_hp = max(0, target_player.wall_hp - amount)
		if remaining_damage > 0:
			target_player.tower_hp -= remaining_damage
```

---

## 3. Искусственный интеллект (AI)

Используем весовую систему для выбора карт.

### 3.1 Алгоритм выбора
1. Отфильтровать карты, на которые хватает ресурсов.
2. Для каждой доступной карты рассчитать "ценность":
   - **Урон:** `BaseValue * (100 / EnemyTowerHP)`. Чем меньше HP у врага, тем важнее урон.
   - **Защита:** `BaseValue * (1 - CurrentWall / MaxWall)`. Важнее, когда стена разрушена.
   - **Экономика:** `BaseValue * (1 / CurrentIncome)`. Важнее в начале игры.
3. Выбрать карту с максимальным весом. Если веса равны — случайный выбор.

---

## 4. Интерфейс (UI) и UX

### 4.1 Система карт в руке
- Используем `HBoxContainer` для размещения карт.
- Каждая карта — это сцена с `Area2D` или `Control` для детекции мыши.
- **Интерактив:** При наведении карта приподнимается (Tween). При клике — разыгрывается.

### 4.2 Визуализация ресурсов
- Три прогресс-бара для Кирпичей, Гемов и Зверей.
- Числовой индикатор прироста (например, `+2`).

---

## 5. Интеграция Яндекс Игр (SDK)

### 5.1 JS-мост (`yandex_sdk.gd`)
```gdscript
extends Node

var _window = JavaScriptBridge.get_interface("window")
var _ysdk

func _ready():
	if _window:
		# Ожидание инициализации SDK в index.html
		_ysdk = _window.ysdk

func show_rewarded_video(callback_name: String):
	if _ysdk:
		_ysdk.adv.showRewardedVideo(
			{
				"callbacks": {
					"onOpen": JavaScriptBridge.create_callback(func(_args): print("Ad open")),
					"onRewarded": JavaScriptBridge.create_callback(func(_args): get_tree().call_group("ads", callback_name)),
					"onClose": JavaScriptBridge.create_callback(func(_args): print("Ad closed")),
					"onError": JavaScriptBridge.create_callback(func(error): print("Error: ", error))
				}
			}
		)
```

---

## 6. Мета-прогрессия и Сохранения

### 6.1 Сохранение данных
- Используем `JSON` для сериализации профиля.
- В вебе данные отправляются через `ysdk.player.setData()`.

### 6.2 Магазин улучшений
- Дерево навыков, где каждый узел — это `bool` или `int` модификатор в `ProfileManager`.
- Пример: `start_wall_bonus = 5`.

---

## 7. Этапы разработки (Sprint Plan)

### Спринт 1: Прототип (1 неделя)
- [ ] Базовые сцены Карты и Стола.
- [ ] Логика ресурсов и хода.
- [ ] 5 тестовых карт.

### Спринт 2: Контент и ИИ (2 недели)
- [ ] Создание системы Resource для всех 60 карт.
- [ ] Реализация базового ИИ.
- [ ] Анимации Tween для карт.

### Спринт 3: Карта мира и Рогалик (1 неделя)
- [ ] Генерация путей на карте мира.
- [ ] Система артефактов и их влияния на бой.

### Спринт 4: SDK и Полировка (1 неделя)
- [ ] Интеграция рекламы Яндекса.
- [ ] Финальный UI/UX.
- [ ] Оптимизация размера бандла.
