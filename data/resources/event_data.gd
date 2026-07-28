class_name EventData
extends Resource
## ARC-014: узел «Событие» (docs/game_design_doc.md 7.1). По аналогии с
## CardData/ArtifactData — плоский Resource с эффектами-словарями, без
## отдельного класса на вариант выбора.

@export var event_title: String = "Событие"
@export_multiline var event_description: String = ""

## 2-3 варианта выбора. Каждый вариант — Dictionary:
## {"text": "...", "outcomes": [{"chance": 100, "result_text": "...", "effects": [...]}]}
## Несколько outcomes с chance в сумме 100 — риск: реальный исход выбирается
## случайно в момент выбора варианта (event_screen.gd._resolve_outcome).
## Эффекты используют тот же словарный формат, что и карты/артефакты, но со
## своим набором типов (run-состояние, не боевое): "gold" (value — дельта
## MatchSettings.run_gold), "add_card" (card_path — .tres, добавляется в
## run_deck), "run_tower_bonus"/"run_quarry_bonus"/"run_magic_bonus"/
## "run_dungeon_bonus" (value — дельта соответствующего поля MatchSettings,
## тот же механизм, что у узла «Отдых», ARC-013).
@export var options: Array[Dictionary] = []
