extends Node

var _window = JavaScriptBridge.get_interface("window")
var _ysdk


func _ready():
	if _window:
		# _window — это JavaScriptObject (обёртка над реальным window из браузера),
		# а не обычный GDScript Object: has_method() на нём пытается вызвать
		# одноимённый метод в самом JS ("window.has_method(...)"), которого не
		# существует, и падает с "obj[method] is not a function" (баг, пойманный
		# смоук-тестом ARC-075). Проверка наличия свойства — просто чтение самого
		# свойства: для отсутствующего в JS оно вернётся null/undefined без ошибки.
		_ysdk = _window.ysdk
		if not _ysdk:
			print("[YandexSDK] Running in debug/local mode (stub active)")


func show_rewarded_video(callback_name: String):
	if _ysdk:
		_ysdk.adv.showRewardedVideo(
			{
				"callbacks":
				{
					"onOpen": JavaScriptBridge.create_callback(func(_args): print("Ad open")),
					"onRewarded":
					JavaScriptBridge.create_callback(
						func(_args): get_tree().call_group("ads", callback_name)
					),
					"onClose": JavaScriptBridge.create_callback(func(_args): print("Ad closed")),
					"onError":
					JavaScriptBridge.create_callback(func(error): print("Error: ", error))
				}
			}
		)
	else:
		print("[YandexSDK] Stub: Reward granted for ", callback_name)
		get_tree().call_group("ads", callback_name)
