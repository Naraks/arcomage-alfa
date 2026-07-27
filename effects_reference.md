# Справочник по словарю `effects` (карты и артефакты)

Короткий документ для контент-авторов (ARC-005). Описывает, что на самом деле делают ключи `type`/`target`/`value`
в `CardData.effects` и `ArtifactData.effects`, чтобы не закладывать в контент несуществующую механику. Источник
истины — `MatchManager.apply_card_effects()` и `ArtifactManager.apply_artifact_effect()`
(`core/match_manager.gd`, `core/artifact_manager.gd`); если этот документ разойдётся с кодом — прав код, документ
надо поправить.

## Карты: `{"type": ..., "value": int, "target": string}`

### `target` — как резолвится

`MatchManager.resolve_target(actor, enemy, target_str)` смотрит **только на префикс**:

* `target_str` начинается с `"self"` → эффект применяется к игроку, разыгравшему карту (`actor`).
* иначе (обычно `"enemy"` или `"enemy_*"`) → применяется к сопернику.

Суффикс (`_wall` / `_tower`) в `resolve_target()` не участвует вообще. Он имеет значение только для типа `"build"`
(см. ниже) — для всех остальных типов это чисто описательная часть строки, ни на что не влияющая в коде.

### `type` — что реально происходит

| `type`           | Что делает                                                                 | Роль суффикса `_wall`/`_tower` в `target` |
|-------------------|-----------------------------------------------------------------------------|--------------------------------------------|
| `damage`          | `apply_damage(value, target, ignore_wall=false)` — урон сначала съедает `wall_hp`, остаток идёт в `tower_hp` | Игнорируется. Стена поглощает урон всегда автоматически — суффикс `_wall` у `"enemy_wall"` только описывает то, что и так произойдёт, но не обязателен. |
| `direct_damage`   | `apply_damage(value, target, ignore_wall=true)` — урон идёт в `tower_hp` напрямую, стена не участвует | Игнорируется. |
| `build_wall`      | `target.wall_hp += value`                                                  | Игнорируется — тип уже однозначно указывает "стена". По конвенции пишем `self_wall`/`enemy_wall` для читаемости, но код смотрит только на префикс. |
| `build_tower`     | `target.tower_hp += value`                                                 | Игнорируется — аналогично, тип уже "башня". |
| `mod_quarry`      | `target.quarry += value`                                                   | Игнорируется. По конвенции — просто `self`/`enemy`. |
| `mod_magic`       | `target.magic += value`                                                    | Игнорируется. |
| `mod_dungeon`     | `target.dungeon += value`                                                  | Игнорируется. |
| `build`           | Универсальный тип. Какое поле меняется — решает **суффикс** `target`: `*_wall` → `wall_hp`, `*_tower` → `tower_hp`. Если суффикса нет — эффект не делает ничего. | **Единственный тип, где суффикс функционален.** Поддерживает и `self_wall`/`self_tower`, и `enemy_wall`/`enemy_tower` (ARC-005: раньше `enemy_wall`/`enemy_tower` тихо ничего не делали — исправлено). |

### Практическая рекомендация для новых карт

* Для `damage`/`direct_damage`/`build_wall`/`build_tower`/`mod_*` — пиши `target` как просто `"self"` или
  `"enemy"`. Суффикс можно добавить для читаемости (`"enemy_wall"` рядом с `damage` выглядит понятно), но он
  ничего не меняет в поведении.
* Для `build` — суффикс `_wall`/`_tower` обязателен, без него эффект не сработает.

## Артефакты: `{"trigger": string, "type": string, "value": int}`

У артефактов (`ArtifactData.effects`, `ArtifactManager.apply_artifact_effect()`) ключа `target` нет вообще —
эффект всегда применяется к владельцу артефакта. Вместо `target` там `trigger` (`"turn_started"`, `"card_played"`),
определяющий, когда эффект срабатывает. Набор `type` тот же, что у карт (`mod_quarry`, `build_wall`, ...), но без
generic `"build"` — в текущих артефактах он не встречается и код его не глядит.

## Аудит существующего контента (ARC-005)

Все 34 текущие карты (`data/cards/*.tres`) и 1 артефакт (`data/artifacts/dwarf_pickaxe.tres`) проверены построчно:
ни одна не использует суффикс `target`, который противоречил бы реальному поведению (например, нет
`build_wall` с суффиксом `_tower`, нет `direct_damage` с суффиксом `_wall`, который намекал бы на несуществующее
поглощение стеной). `self_tower`/`enemy_tower` пока не встречаются вообще ни в одной карте — только в коде
(`match_manager.gd`, `data/resources/default_ai_strategy.gd`) как поддерживаемый, но неиспользуемый контентом
вариант.
