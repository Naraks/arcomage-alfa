extends Control
## Статистика профиля.

const RewardScreenScript = preload("res://ui/reward/reward_screen.gd")

@export var embedded_in_profile := false

var _ui_built := false


func _ready() -> void:
	_build_ui()


func _rare_card_paths() -> Array:
	var result: Array = []
	for path in MatchManager.ALL_CARD_PATHS:
		var card: CardData = load(path)
		if card and card.rarity == CardData.Rarity.RARE:
			result.append(path)
	return result


func _unlocked_cards_text() -> String:
	var total := _rare_card_paths().size()
	var unlocked: int = ProfileManager.profile.get("unlocked_cards", []).size()
	return "Открыто редких карт: %d/%d" % [unlocked, total]


func _unlocked_artifacts_text() -> String:
	var total := RewardScreenScript.ALL_ARTIFACT_PATHS.size()
	var collected: int = ProfileManager.profile.get("unlocked_artifacts", []).size()
	return "Собрано артефактов: %d/%d" % [collected, total]


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	var root_margin := EmbeddedScreenLayout.build_shell(self, embedded_in_profile)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	root_margin.add_child(root_vbox)

	if not embedded_in_profile:
		var title := Label.new()
		title.text = "СТАТИСТИКА"
		title.add_theme_font_size_override("font_size", 28)
		root_vbox.add_child(title)

	_add_stat_label(root_vbox, "Побед: %d" % ProfileManager.profile.get("total_wins", 0))
	_add_stat_label(
		root_vbox, "Завершено забегов: %d" % ProfileManager.profile.get("total_runs", 0)
	)
	_add_stat_label(
		root_vbox,
		"Максимальная высота Башни: %d" % ProfileManager.profile.get("max_tower_height", 0)
	)
	_add_stat_label(root_vbox, _unlocked_cards_text())
	_add_stat_label(root_vbox, _unlocked_artifacts_text())

	if not embedded_in_profile:
		var back_button := Button.new()
		back_button.text = "Назад в меню"
		back_button.pressed.connect(_on_back_pressed)
		root_vbox.add_child(back_button)


func _add_stat_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
