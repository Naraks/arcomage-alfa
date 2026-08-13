class_name EmbeddedScreenLayout
extends RefCounted
## Общая "оболочка" экранов, которые могут открываться как отдельная сцена
## или как встроенная вкладка профиля (embedded_in_profile): фон и отступы
## раньше дублировались в deck/meta_shop/stats screens по отдельности.

const EMBEDDED_MARGIN := 12
const STANDALONE_MARGIN := 24

## Настраивает anchors корневого Control, добавляет фон (кроме embedded-режима)
## и возвращает MarginContainer с уже выставленными отступами, куда экран
## должен добавить остальное содержимое.
static func build_shell(control: Control, embedded_in_profile: bool) -> MarginContainer:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)

	if not embedded_in_profile:
		var bg := ColorRect.new()
		bg.color = UIColors.SCREEN_BACKGROUND
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := EMBEDDED_MARGIN if embedded_in_profile else STANDALONE_MARGIN
	root_margin.add_theme_constant_override("margin_left", margin)
	root_margin.add_theme_constant_override("margin_right", margin)
	root_margin.add_theme_constant_override("margin_top", margin)
	root_margin.add_theme_constant_override("margin_bottom", margin)
	control.add_child(root_margin)

	return root_margin
