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

Суффикс (`_wall` / `_tower`) в `resolve_target()` не участвует вообще — во всех типах ниже это чисто описательная
часть строки, ни на что не влияющая в коде. Пиши `target` как просто `"self"` или `"enemy"`; суффикс можно
добавить для читаемости (`"enemy_wall"` рядом с `damage` выглядит понятно), но менять поведение он не будет.

### `type` — что реально происходит

| `type`           | Что делает                                                                 |
|-------------------|-----------------------------------------------------------------------------|
| `damage`          | `apply_damage(value, target, ignore_wall=false)` — урон сначала съедает `wall_hp`, остаток идёт в `tower_hp` |
| `direct_damage`   | `apply_damage(value, target, ignore_wall=true)` — урон идёт в `tower_hp` напрямую, стена не участвует |
| `build_wall`      | `target.wall_hp += value`                                                  |
| `build_tower`     | `target.tower_hp += value`                                                 |
| `mod_quarry`      | `target.quarry += value`                                                   |
| `mod_magic`       | `target.magic += value`                                                    |
| `mod_dungeon`     | `target.dungeon += value`                                                  |

Раньше существовал ещё generic-тип `"build"`, который сам решал wall/tower по суффиксу `target` — убран (ARC-005):
использовался ровно одной картой (`wall_card.tres`, переведена на `build_wall`) и дублировал `build_wall`/
`build_tower` без единой причины для второго пути к тому же результату.

## Артефакты: `{"trigger": string, "type": string, "value": int}`

У артефактов (`ArtifactData.effects`, `ArtifactManager.apply_artifact_effect()`) ключа `target` нет вообще —
эффект всегда применяется к владельцу артефакта. Вместо `target` там `trigger` (`"turn_started"`, `"card_played"`),
определяющий, когда эффект срабатывает. Набор `type` тот же, что у карт (`mod_quarry`, `build_wall`, ...).

## Аудит существующего контента (ARC-005)

Все 34 текущие карты (`data/cards/*.tres`) и 1 артефакт (`data/artifacts/dwarf_pickaxe.tres`) проверены построчно:
ни одна не использует суффикс `target`, который противоречил бы реальному поведению (например, нет
`build_wall` с суффиксом `_tower`, нет `direct_damage` с суффиксом `_wall`, который намекал бы на несуществующее
поглощение стеной). `self_tower`/`enemy_tower` пока не встречаются вообще ни в одной карте — только в коде
(`match_manager.gd`, `data/resources/default_ai_strategy.gd`) как поддерживаемый, но неиспользуемый контентом
вариант.
