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
| `mod_quarry`      | `target.quarry = max(0, target.quarry + value)` — не уходит в минус (ARC-020) |
| `mod_magic`       | `target.magic = max(0, target.magic + value)`                              |
| `mod_dungeon`     | `target.dungeon = max(0, target.dungeon + value)`                          |
| `draw_card`       | `target` тянет `value` карт (`MatchManager.draw_card()` — уважает `max_hand_size`, ARC-003) |
| `steal_resource`  | см. ниже                                                                    |
| `conditional`     | см. ниже                                                                    |
| `gain_resource`   | см. ниже (ARC-020)                                                          |
| `drain_resource`  | см. ниже (ARC-020)                                                          |
| `reduce_wall`     | `target.wall_hp = max(0, target.wall_hp - value)` — плоский минус к Стене, без перелива в Башню (в отличие от `damage`) |

Раньше существовал ещё generic-тип `"build"`, который сам решал wall/tower по суффиксу `target` — убран (ARC-005):
использовался ровно одной картой (`wall_card.tres`, переведена на `build_wall`) и дублировал `build_wall`/
`build_tower` без единой причины для второго пути к тому же результату.

### `steal_resource` (ARC-021, `resource: "random"` — ARC-020)

`{"type": "steal_resource", "target": "enemy", "resource": "gems", "value": 3}`

`target` резолвится как обычно и определяет, **у кого крадут** (обычно `"enemy"`) — получает украденное всегда
`actor` (тот, кто разыграл карту), это не настраивается. `resource` — один из `"bricks"`/`"gems"`/`"beasts"`, либо
`"random"` — тип ресурса выбирается случайно **в момент розыгрыша карты** (нужно карте «Кража времени»: «украсть
любой ресурс врага, тот же ресурс приходит вам» — в данных заранее не фиксируется). Крадётся `min(value, сколько
реально есть у цели)` — увести ресурс в минус нельзя.

### `gain_resource` (ARC-020)

`{"type": "gain_resource", "target": "self", "resource": "bricks", "value": 5}`

Мгновенно `target.<resource> += value`. В отличие от `steal_resource`, у него только одна сторона — никто ничего
не теряет. Нужен картам вида «Генератор X +5, сразу +5 X» (Гномья шахта / Архимаг / Логово альфы) — сам рост
генератора это отдельный `mod_quarry`/`mod_magic`/`mod_dungeon` эффект в том же списке `effects`, `gain_resource`
только про мгновенную прибавку к текущему запасу ресурса.

### `drain_resource` (ARC-020)

`{"type": "drain_resource", "target": "enemy", "resource": "bricks", "value": 3}`

`target` теряет `min(value, сколько реально есть)` ресурса `resource` — в минус не уходит. В отличие от
`steal_resource`, никто ничего не получает — чистое «проклятие», а не кража. Карта на несколько ресурсов сразу
(«Ресурсы врага −N всех типов») — это просто три отдельных `drain_resource` в списке `effects`, по одному на
`"bricks"`/`"gems"`/`"beasts"`.

### `conditional` (ARC-021)

```
{
  "type": "conditional",
  "target": "self",
  "field": "wall_hp",
  "op": "<",
  "threshold": 3,
  "then": {"type": "build_wall", "target": "self", "value": 3},
  "else": {"type": "build_wall", "target": "self", "value": 1}
}
```

`target`/`field` определяют, что именно проверяется (`field` — одно из `wall_hp`/`tower_hp`/`bricks`/`gems`/
`beasts`/`quarry`/`magic`/`dungeon` резолвленного `target_player`). `op` — `<`, `<=`, `>`, `>=`, `==`, `!=`.
В зависимости от результата применяется вложенный эффект `"then"` или `"else"` (тот же формат словаря, что и
у любого другого эффекта, — включая свой собственный `target`, независимый от условия). Ветка необязательна:
если подходящий ключ (`"then"`/`"else"`) отсутствует, ничего не происходит.

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
