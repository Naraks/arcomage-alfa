extends Control
## Отображение и ввод игровой карты.

signal card_clicked(card_node: Node)
signal card_right_clicked(card_node: Node)

const CurvedLabelScript = preload("res://entities/card/curved_label.gd")

const SEAL_TEXTURES := {
	CardData.Rarity.COMMON: preload("res://art/card_frame/seal_common.png"),
	CardData.Rarity.UNCOMMON: preload("res://art/card_frame/seal_uncommon.png"),
	CardData.Rarity.RARE: preload("res://art/card_frame/seal_rare.png"),
}

const HOVER_RUSTLE_SOUND = preload("res://audio/sfx/card_hover_rustle.wav")

@export var card_data: CardData:
	set(value):
		card_data = value
		update_ui()

@onready var name_label: CurvedLabelScript = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var description_label: Label = $DescriptionLabel
@onready var background: TextureRect = $Background
@onready var seal_badge: TextureRect = $SealBadge
@onready var card_art_texture: TextureRect = $CardArtTexture
@onready var icon_texture: TextureRect = $IconTexture


func _ready() -> void:
	if card_data:
		update_ui()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if not card_data:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("[DEBUG] Card node _gui_input left clicked: ", card_data.card_name)
			card_clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("[DEBUG] Card node _gui_input right clicked: ", card_data.card_name)
			card_right_clicked.emit(self)


func update_ui() -> void:
	if not is_inside_tree() or not card_data:
		return

	name_label.text = card_data.card_name
	cost_label.text = str(card_data.cost)
	description_label.text = card_data.description
	card_art_texture.texture = card_data.card_art
	card_art_texture.visible = card_data.card_art != null
	icon_texture.texture = card_data.icon
	icon_texture.visible = card_data.card_art == null and card_data.icon != null

	background.modulate = Color(1, 1, 1, 1)

	seal_badge.texture = SEAL_TEXTURES.get(card_data.rarity, SEAL_TEXTURES[CardData.Rarity.COMMON])

	var resource_tint := Color(1, 1, 1, 1)
	match card_data.type:
		CardData.ResourceType.BRICKS:
			resource_tint = Color(1.0, 0.35, 0.3)
		CardData.ResourceType.GEMS:
			resource_tint = Color(0.35, 0.5, 1.0)
		CardData.ResourceType.BEASTS:
			resource_tint = Color(0.35, 1.0, 0.35)
	seal_badge.modulate = resource_tint


func _on_mouse_entered() -> void:
	print("[DEBUG] Mouse entered card: ", card_data.card_name if card_data else "null")
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD)
	z_index = 10
	AudioManager.play_sfx(HOVER_RUSTLE_SOUND, -6.0)


func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD)
	z_index = 0
