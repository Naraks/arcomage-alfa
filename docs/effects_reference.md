# Справочник эффектов карт и артефактов

Этот документ описывает поля `EffectData` в `CardData.effects` и `ArtifactData.effects`. Он нужен при создании и проверке игрового контента.

Источники истины в коде:

- структура эффекта — `data/resources/effect_data.gd` (`EffectData`);
- эффекты карт — `MatchManager.apply_card_effects()` в `core/match_manager.gd`;
- общие правила целей, ресурсов и условий — `core/effect_utils.gd`;
- эффекты и триггеры артефактов — `core/artifact_manager.gd`.

Если поведение кода изменяется, этот справочник нужно обновить вместе с ним. На момент актуализации в проекте 68 карт и 8 артефактов.

## Общие соглашения

Эффект хранится как типизированный ресурс `EffectData` (не `Dictionary`). Поле `type` — это typed enum `EffectType.Type` (`data/resources/effect_type.gd`), а не свободная строка: в редакторе Godot оно задаётся выпадающим списком в инспекторе, поэтому опечатка в имени типа отлавливается на этапе выбора значения, а не проваливается тихо в рантайме. Неизвестное/незаданное значение (`EffectType.Type.NONE`) не применяется и выводит предупреждение. Остальные поля зависят от типа эффекта и не заданы (равны значению по умолчанию), если конкретному типу они не нужны.

В `.tres`-файлах карт и артефактов каждый эффект — это `[sub_resource type="Resource"]` со скриптом `effect_data.gd`, на который ссылается `effects = Array[ExtResource("effect_script")]([SubResource(...), ...])`; поле `type` сериализуется как целое число — значение `EffectType.Type`. В тестах (`tests/*.gd`) эффекты по-прежнему удобно описывать словарём со строковым ключом `type` (например, `"damage"`) и получать `EffectData` через `EffectData.from_dict({...})` — `TestFixtures.make_card()`/`make_artifact()` делают это автоматически, а сам `from_dict()` переводит строку в `EffectType.Type` через `EffectType.from_string()` (с предупреждением при неизвестном ключе). Поэтому ниже примеры даны в виде словаря там, где это тестовый контекст, и в виде `.tres`-фрагмента там, где это игровые данные.

Допустимые имена ресурсов:

| Значение | Ресурс | Генератор |
|---|---|---|
| `bricks` | кирпичи | карьер (`quarry`) |
| `gems` | самоцветы | магия (`magic`) |
| `beasts` | звери | подземелье (`dungeon`) |

## Эффекты карт

Базовая форма в `.tres` карты:

```
[sub_resource type="Resource" id="EffectData_1"]
script = ExtResource("effect_script")
type = 1
target = "enemy"
value = 6
```

`type = 1` — это `EffectType.Type.DAMAGE`; полное сопоставление чисел и типов см. в таблице ниже и в `data/resources/effect_type.gd`. В инспекторе Godot это значение выбирается по имени из выпадающего списка, а не вводится числом.

То же самое в тестах через словарь-шорткат:

```gdscript
{"type": "damage", "target": "enemy", "value": 6}
```

### Выбор цели

Ключ `target` необязателен; значение по умолчанию — `enemy`.

- строка, начинающаяся с `self`, выбирает игрока, разыгравшего карту;
- любая другая строка выбирает соперника.

Суффиксы наподобие `_wall` и `_tower` не влияют на выбор или часть укреплений. Рекомендуется использовать только `self` и `enemy`, а нужное действие выражать через `type`.

### Поддерживаемые типы

| `type` (тестовый словарь) | `EffectType.Type` / значение в `.tres` | Дополнительные ключи | Результат |
|---|---|---|---|
| `damage` | `DAMAGE` / `1` | `value` | Урон сначала поглощается стеной, остаток уменьшает башню. |
| `direct_damage` | `DIRECT_DAMAGE` / `2` | `value` | Уменьшает башню напрямую, игнорируя стену. |
| `build_wall` | `BUILD_WALL` / `3` | `value` | Добавляет `value` к стене. |
| `build_tower` | `BUILD_TOWER` / `4` | `value` | Добавляет `value` к башне. |
| `mod_quarry` | `MOD_QUARRY` / `5` | `value` | Изменяет карьер; итоговое значение не ниже нуля. |
| `mod_magic` | `MOD_MAGIC` / `6` | `value` | Изменяет магию; итоговое значение не ниже нуля. |
| `mod_dungeon` | `MOD_DUNGEON` / `7` | `value` | Изменяет подземелье; итоговое значение не ниже нуля. |
| `draw_card` | `DRAW_CARD` / `8` | `value` | Пытается добрать указанное количество карт с учётом предела руки. |
| `steal_resource` | `STEAL_RESOURCE` / `9` | `resource`, `value` | Переносит ресурс от выбранной цели к разыгравшему карту игроку. |
| `conditional` | `CONDITIONAL` / `10` | см. ниже | Проверяет условие и применяет одну вложенную ветку. |
| `gain_resource` | `GAIN_RESOURCE` / `11` | `resource`, `value` | Добавляет ресурс выбранной цели. |
| `drain_resource` | `DRAIN_RESOURCE` / `12` | `resource`, `value` | Отнимает у цели ресурс, не опуская запас ниже нуля. |
| `reduce_wall` | `REDUCE_WALL` / `13` | `value` | Уменьшает стену без переноса остатка урона в башню. |

`value` по умолчанию равен `0`. Для `gain_resource`, `drain_resource` и обычного `steal_resource` ключ `resource` должен содержать одно из допустимых имён ресурсов. У `steal_resource` также разрешено значение `random`: тип ресурса выбирается случайно при розыгрыше. Украсть можно не больше фактического запаса цели.

Пример нескольких последовательных эффектов одной карты (тестовый словарь-шорткат):

```gdscript
effects = [
    {"type": "mod_quarry", "target": "self", "value": 1},
    {"type": "gain_resource", "target": "self", "resource": "bricks", "value": 5},
]
```

Эффекты выполняются в порядке следования в массиве `CardData.effects`.

### Условный эффект

`then`/`else` в `EffectData` — это поля `then_effect`/`else_effect` (вложенный `EffectData`, не словарь; `else` — зарезервированное слово GDScript, поэтому имя поля отличается от словарного ключа). В `.tres` это ссылка на ещё один `SubResource`:

```
[sub_resource type="Resource" id="EffectData_1"]
script = ExtResource("effect_script")
type = 3
target = "self"
value = 3

[sub_resource type="Resource" id="EffectData_2"]
script = ExtResource("effect_script")
type = 3
target = "self"
value = 1

[sub_resource type="Resource" id="EffectData_3"]
script = ExtResource("effect_script")
type = 10
target = "self"
field = "wall_hp"
op = "<"
threshold = 3
then_effect = SubResource("EffectData_1")
else_effect = SubResource("EffectData_2")
```

(`type = 3` — `BUILD_WALL`, `type = 10` — `CONDITIONAL`.)

Тестовый словарь-шорткат (ключи `then`/`else` здесь допустимы — `EffectData.from_dict()` сам разворачивает их в `then_effect`/`else_effect`):

```gdscript
{
    "type": "conditional",
    "target": "self",
    "field": "wall_hp",
    "op": "<",
    "threshold": 3,
    "then": {"type": "build_wall", "target": "self", "value": 3},
    "else": {"type": "build_wall", "target": "self", "value": 1},
}
```

Параметры условия:

| Поле | Допустимые значения | По умолчанию |
|---|---|---|
| `target` | `self` или `enemy` | `enemy` (для `conditional` в игровых данных всегда задаётся явно) |
| `field` | `wall_hp`, `tower_hp`, `bricks`, `gems`, `beasts`, `quarry`, `magic`, `dungeon` | пустая строка, значение `0` |
| `op` | `<`, `<=`, `>`, `>=`, `==`, `!=` | `<` |
| `threshold` | сравниваемое число | `0` |
| `then_effect` | вложенный `EffectData` | не задан (`null`) |
| `else_effect` | вложенный `EffectData` | не задан (`null`) |

Цель внутри `then_effect`/`else_effect` задаётся независимо от цели, чьё поле проверяется. Если выбранная ветка не задана (`null`), эффект ничего не делает.

## Эффекты артефактов

Базовая форма в `.tres` артефакта:

```
[sub_resource type="Resource" id="EffectData_1"]
script = ExtResource("effect_script")
type = 5
trigger = "turn_started"
value = 1
```

(`type = 5` — `EffectType.Type.MOD_QUARRY`.)

То же самое в тестах через словарь-шорткат:

```gdscript
{"trigger": "turn_started", "type": "mod_quarry", "value": 1}
```

Артефакт всегда действует на своего владельца, поэтому поле `target` не используется. Набор типов отличается от эффектов карт.

### Триггеры

| `trigger` | Когда проверяется | Доступный контекст |
|---|---|---|
| `match_started` | В начале матча для обоих игроков | — |
| `turn_started` | В начале хода владельца | — |
| `card_played` | После розыгрыша владельцем карты | `card` |
| `on_damage_taken` | После получения владельцем урона | `amount`, `hit_wall`, `attacker` |
| `pre_play` | Перед оплатой карты | Обрабатывается только `skip_payment_chance`. |

### Поддерживаемые типы

| `type` (тестовый словарь) | `EffectType.Type` / значение в `.tres` | Дополнительные ключи | Результат |
|---|---|---|---|
| `mod_quarry` | `MOD_QUARRY` / `5` | `value` | Добавляет значение к карьеру. |
| `mod_magic` | `MOD_MAGIC` / `6` | `value` | Добавляет значение к магии. |
| `mod_dungeon` | `MOD_DUNGEON` / `7` | `value` | Добавляет значение к подземелью. |
| `build_wall` | `BUILD_WALL` / `3` | `value` | Добавляет значение к стене. |
| `build_tower` | `BUILD_TOWER` / `4` | `value` | Добавляет значение к башне. |
| `gain_resource` | `GAIN_RESOURCE` / `11` | `resource`, `value`, опционально `requires_card_type` | Добавляет владельцу указанный ресурс. |
| `set_generator_level` | `SET_GENERATOR_LEVEL` / `14` | `value` | Поднимает каждый из трёх генераторов минимум до указанного уровня. |
| `set_max_hand_size` | `SET_MAX_HAND_SIZE` / `15` | `value` | Поднимает максимальный размер руки минимум до указанного значения. |
| `reflect_damage` | `REFLECT_DAMAGE` / `16` | `value` | При попадании в стену наносит атакующему прямой урон по башне. |
| `skip_payment_chance` | `SKIP_PAYMENT_CHANCE` / `17` | `chance` | С вероятностью от `0.0` до `1.0` отменяет оплату карты. |

`requires_card_type` в `EffectData` — целое поле со значением по умолчанию `-1` («условие не задано»); используется только с `gain_resource` на триггере `card_played`. Остальные значения соответствуют `CardData.ResourceType`: `0` — кирпичи, `1` — самоцветы, `2` — звери.

`skip_payment_chance` — единственный тип эффекта, у которого дробное число хранится в отдельном поле `chance` (`float`), а не в целочисленном `value` — иначе `0.1` обнулилось бы. В тестовом словаре-шоркате по-прежнему пишется ключ `"value"` — `EffectData.from_dict()` сам кладёт его и в `value`, и в `chance`.

Примеры (`.tres`-поля / тестовый словарь):

```gdscript
# +1 самоцвет после розыгрыша карты самоцветов.
{"trigger": "card_played", "type": "gain_resource", "resource": "gems", "value": 1, "requires_card_type": 1}

# 10 % вероятности разыграть карту бесплатно (в .tres — chance = 0.1).
{"trigger": "pre_play", "type": "skip_payment_chance", "value": 0.1}

# 2 прямого урона атакующему, если удар пришёлся по стене.
{"trigger": "on_damage_taken", "type": "reflect_damage", "value": 2}
```

Защита от зацикливания не позволяет отражённому урону запустить новое отражение. `reflect_damage` ничего не делает при прямом уроне башне или при отсутствии атакующего.

## Проверка нового контента

Перед добавлением или изменением эффекта проверьте:

1. `type` существует в нужном обработчике — карточном или артефактном.
2. Указаны обязательные для этого типа ключи: `resource`, условие или ограничение типа карты.
3. `target` карточного эффекта явно задан как `self` или `enemy`.
4. Артефакт использует поддерживаемый `trigger`, совместимый с его `type`.
5. Числовой знак соответствует замыслу: генераторы карт ограничены снизу нулём, а артефактные `mod_*` такого ограничения не имеют.
6. Для новой механики одновременно обновлены код, тесты и этот справочник.
