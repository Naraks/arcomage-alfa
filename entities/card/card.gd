extends Control

signal card_clicked(card_node: Node)
signal card_right_clicked(card_node: Node)

@export var card_data: CardData:
	set(value):
		card_data = value
		update_ui()

@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var description_label: Label = $DescriptionLabel
@onready var background: ColorRect = $Background
@onready var icon_texture: TextureRect = $IconTexture


func _ready() -> void:
	if card_data:
		update_ui()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
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
	# ARC-022: icon — плейсхолдер-арт по типу ресурса (может отсутствовать у
	# карт, добавленных до этого тикета, — тогда просто ничего не показываем).
	icon_texture.texture = card_data.icon
	icon_texture.visible = card_data.icon != null

	# Меняем цвет фона в зависимости от типа ресурса
	match card_data.type:
		CardData.ResourceType.BRICKS:
			background.modulate = Color(0.8, 0.4, 0.4)
		CardData.ResourceType.GEMS:
			background.modulate = Color(0.4, 0.4, 0.8)
		CardData.ResourceType.BEASTS:
			background.modulate = Color(0.4, 0.8, 0.4)


func _on_mouse_entered() -> void:
	print("[DEBUG] Mouse entered card: ", card_data.card_name if card_data else "null")
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD)
	z_index = 10


func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD)
	z_index = 0
