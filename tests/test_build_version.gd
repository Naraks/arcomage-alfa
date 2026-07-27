extends GutTest
## Тесты BuildVersion (ARC-069). Синглтон уже поднят автозагрузкой к моменту
## тестов, поэтому сохраняем/восстанавливаем его поля, а не создаём инстанс.

var _orig_version: String
var _orig_commit: String


func before_each() -> void:
	_orig_version = BuildVersion.version
	_orig_commit = BuildVersion.commit


func after_each() -> void:
	BuildVersion.version = _orig_version
	BuildVersion.commit = _orig_commit


func test_get_display_string_without_commit_returns_version_only() -> void:
	BuildVersion.version = "dev"
	BuildVersion.commit = ""
	assert_eq(BuildVersion.get_display_string(), "dev")


func test_get_display_string_with_commit_includes_it() -> void:
	BuildVersion.version = "v1.2.3"
	BuildVersion.commit = "abc1234"
	assert_eq(BuildVersion.get_display_string(), "v1.2.3 (abc1234)")


func test_load_is_noop_when_file_missing() -> void:
	# В dev/тестовом окружении res://build_version.json не существует —
	# файл пишет только CI перед экспортом (см. .github/workflows/ci.yml).
	BuildVersion.version = "sentinel"
	BuildVersion.commit = "sentinel-commit"

	BuildVersion._load()

	assert_eq(BuildVersion.version, "sentinel", "_load() не должен трогать значения, если файла нет")
	assert_eq(BuildVersion.commit, "sentinel-commit")
