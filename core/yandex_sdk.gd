extends Node

var _window = JavaScriptBridge.get_interface("window")
var _ysdk

func _ready():
	if _window:
		# В реальной среде здесь будет ожидание инициализации SDK
		# Для заглушки имитируем наличие объекта
		if _window.has_method("ysdk"):
			_ysdk = _window.ysdk
		else:
			print("[YandexSDK] Running in debug/local mode (stub active)")

func show_rewarded_video(callback_name: String):
	if _ysdk:
		_ysdk.adv.showRewardedVideo(
			{
				"callbacks": {
					"onOpen": JavaScriptBridge.create_callback(func(_args): print("Ad open")),
					"onRewarded": JavaScriptBridge.create_callback(func(_args): get_tree().call_group("ads", callback_name)),
					"onClose": JavaScriptBridge.create_callback(func(_args): print("Ad closed")),
					"onError": JavaScriptBridge.create_callback(func(error): print("Error: ", error))
				}
			}
		)
	else:
		print("[YandexSDK] Stub: Reward granted for ", callback_name)
		get_tree().call_group("ads", callback_name)
