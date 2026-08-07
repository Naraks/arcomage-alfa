extends Node
## ARC-043: глобальная пауза при потере фокуса окна или вкладки браузера.
## PROCESS_MODE_ALWAYS нужен, чтобы получить focus-in и снять только ту
## паузу, которую этот менеджер установил сам; чужая игровая пауза сохраняется.

var _paused_by_focus := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_set_application_focused(false)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_set_application_focused(true)


func _set_application_focused(focused: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not focused:
		if not tree.paused:
			tree.paused = true
			_paused_by_focus = true
		return
	if _paused_by_focus:
		tree.paused = false
		_paused_by_focus = false


func is_paused_by_focus() -> bool:
	return _paused_by_focus
