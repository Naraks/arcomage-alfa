class_name EffectType
extends RefCounted

enum Type {
	NONE = 0,
	DAMAGE = 1,
	DIRECT_DAMAGE = 2,
	BUILD_WALL = 3,
	BUILD_TOWER = 4,
	MOD_QUARRY = 5,
	MOD_MAGIC = 6,
	MOD_DUNGEON = 7,
	DRAW_CARD = 8,
	STEAL_RESOURCE = 9,
	CONDITIONAL = 10,
	GAIN_RESOURCE = 11,
	DRAIN_RESOURCE = 12,
	REDUCE_WALL = 13,
	SET_GENERATOR_LEVEL = 14,
	SET_MAX_HAND_SIZE = 15,
	REFLECT_DAMAGE = 16,
	SKIP_PAYMENT_CHANCE = 17,
}

const MOD_TYPES := [Type.MOD_QUARRY, Type.MOD_MAGIC, Type.MOD_DUNGEON]

const CARD_TYPES := [
	Type.DAMAGE,
	Type.DIRECT_DAMAGE,
	Type.BUILD_WALL,
	Type.BUILD_TOWER,
	Type.MOD_QUARRY,
	Type.MOD_MAGIC,
	Type.MOD_DUNGEON,
	Type.DRAW_CARD,
	Type.STEAL_RESOURCE,
	Type.CONDITIONAL,
	Type.GAIN_RESOURCE,
	Type.DRAIN_RESOURCE,
	Type.REDUCE_WALL,
]

const _FROM_STRING := {
	"damage": Type.DAMAGE,
	"direct_damage": Type.DIRECT_DAMAGE,
	"build_wall": Type.BUILD_WALL,
	"build_tower": Type.BUILD_TOWER,
	"mod_quarry": Type.MOD_QUARRY,
	"mod_magic": Type.MOD_MAGIC,
	"mod_dungeon": Type.MOD_DUNGEON,
	"draw_card": Type.DRAW_CARD,
	"steal_resource": Type.STEAL_RESOURCE,
	"conditional": Type.CONDITIONAL,
	"gain_resource": Type.GAIN_RESOURCE,
	"drain_resource": Type.DRAIN_RESOURCE,
	"reduce_wall": Type.REDUCE_WALL,
	"set_generator_level": Type.SET_GENERATOR_LEVEL,
	"set_max_hand_size": Type.SET_MAX_HAND_SIZE,
	"reflect_damage": Type.REFLECT_DAMAGE,
	"skip_payment_chance": Type.SKIP_PAYMENT_CHANCE,
}


static func from_string(key: String) -> Type:
	if not _FROM_STRING.has(key):
		push_warning("EffectType.from_string: неизвестный строковый ключ типа эффекта '%s'" % key)
		return Type.NONE
	return _FROM_STRING[key]
