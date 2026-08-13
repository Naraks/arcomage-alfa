class_name EventData
extends Resource
## Данные случайного события и его исходов.

@export var event_title: String = "Событие"
@export_multiline var event_description: String = ""

@export var options: Array[Dictionary] = []


## event_title/event_description и options[]["text"]/outcomes[]["result_text"]
## хранят стабильные ключи локализации, не текст для показа напрямую — см.
## docs/localization_guide.md.
func get_display_title() -> String:
	return tr(event_title)


func get_display_description() -> String:
	return tr(event_description)


static func option_display_text(option: Dictionary) -> String:
	return TranslationServer.translate(String(option.get("text", "")))


static func outcome_display_result(outcome: Dictionary) -> String:
	return TranslationServer.translate(String(outcome.get("result_text", "")))
