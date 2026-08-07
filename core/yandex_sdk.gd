extends Node
## Безопасная интеграция с Yandex Games SDK.

var _window = JavaScriptBridge.get_interface("window")
var _ysdk


func _ready():
	if _window:
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
		# Локальная заглушка позволяет тестировать награду без SDK.
		print("[YandexSDK] Stub: Reward granted for ", callback_name)
		get_tree().call_group("ads", callback_name)
