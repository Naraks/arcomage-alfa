class_name EffectData
extends Resource
## Типизированное описание одного эффекта карты/артефакта.

@export var type: String = ""
@export var target: String = "enemy"
@export var value: int = 0
@export var resource: String = ""
@export var field: String = ""
@export var op: String = "<"
@export var threshold: int = 0
@export var trigger: String = ""
@export var requires_card_type: int = -1
@export var chance: float = 0.0
@export var then_effect: EffectData
@export var else_effect: EffectData


## Собирает EffectData из старого формата Dictionary — используется тестами
## и fixtures.gd, чтобы не переписывать все литералы эффектов в tests/*.gd.
static func from_dict(d: Dictionary) -> EffectData:
	var effect := EffectData.new()
	effect.type = d.get("type", "")
	effect.target = d.get("target", "enemy")
	effect.value = int(d.get("value", 0))
	effect.chance = float(d.get("value", 0.0))
	effect.resource = d.get("resource", "")
	effect.field = d.get("field", "")
	effect.op = d.get("op", "<")
	effect.threshold = int(d.get("threshold", 0))
	effect.trigger = d.get("trigger", "")
	effect.requires_card_type = int(d.get("requires_card_type", -1))
	if d.has("then"):
		effect.then_effect = EffectData.from_dict(d["then"])
	if d.has("else"):
		effect.else_effect = EffectData.from_dict(d["else"])
	return effect
