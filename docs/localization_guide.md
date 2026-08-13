# Гайд по локализации

Проект использует стандартный gettext-механизм локализации Godot: `.po`-файлы в
`localization/`, подключённые в `project.godot` (`[internationalization]`).
Все видимые игроку строки — это **ключи**, а не текст напрямую; реальный текст
живёт только в `.po`.

## Структура

```
localization/
  arcomage.pot   # шаблон: список всех ключей без перевода (для новых языков)
  ru.po          # русский — исходный язык, msgstr дословно совпадает с текстом игры
  en.po          # английский
```

`project.godot`:

```
[internationalization]

locale/translations=PackedStringArray("res://localization/ru.po", "res://localization/en.po")
locale/fallback="ru"
```

Godot импортирует `.po` автоматически при открытии проекта в редакторе —
руками ничего компилировать не нужно.

## Конвенция ключей

Ключ — стабильный UPPER_SNAKE_CASE идентификатор, не меняется при правке
текста. Префиксы:

| Префикс | Где используется |
|---|---|
| `UI_<SCREEN>_<ELEMENT>` | текст конкретного экрана `ui/*_screen.gd` |
| `COMMON_<X>` | общие строки, переиспользуемые на нескольких экранах (`COMMON_BACK`, `COMMON_CANCEL`, `COMMON_SELECT`, `COMMON_CLOSE`, `COMMON_BACK_TO_MENU`, `COMMON_PROFILE_TITLE`) |
| `MSG_<CONTEXT>` | тосты/сообщения обратной связи (например, `MSG_META_SHOP_CARD_UNLOCKED`) |
| `CARD_<STEM>_NAME` / `CARD_<STEM>_DESC` | `data/cards/*.tres`, `<STEM>` — имя файла без расширения, capitalized snake_case |
| `ARTIFACT_<STEM>_NAME` / `ARTIFACT_<STEM>_DESC` | `data/artifacts/*.tres` |
| `EVENT_<STEM>_TITLE` / `_DESC` / `_OPTION_<n>` / `_RESULT_<n>` | `data/events/*.tres`; `<n>` — 1-based порядковый номер варианта/результата в порядке следования в файле (варианты и результаты нумеруются независимо) |
| `UPGRADE_<KEY>_NAME` / `_DESC` | `core/profile_manager.gd::UPGRADE_CATALOG` |

## Как переводится каждый слой

* **UI-код (`ui/*.gd`)** — напрямую `tr("KEY")`. Работает только в методах
  экземпляра (`Object`), т.к. `tr()` — метод `Object`.
* **Статические функции** (например `EventData.option_display_text()`,
  вызывается без экземпляра) — используют `TranslationServer.translate("KEY")`
  вместо `tr()`, т.к. `tr()` в `static func` недоступен.
* **Игровые ресурсы `.tres`** (`CardData`, `ArtifactData`, `EventData`) — поля
  `card_name`, `description`, `artifact_name`, `event_title`,
  `event_description`, а также вложенные `"text"`/`"result_text"` в массиве
  вариантов события хранят **ключ**, не текст. Показывать текст нужно только
  через геттеры экземпляра: `CardData.get_display_name()` /
  `get_display_description()`, `ArtifactData.get_display_name()` /
  `get_display_description()`, `EventData.get_display_title()` /
  `get_display_description()`, `EventData.option_display_text(dict)` /
  `EventData.outcome_display_result(dict)` (последние два — статические).
  **Не читать** `.card_name`/`.description`/`.artifact_name`/`.event_title`/
  `.event_description` напрямую для показа игроку — это сырой ключ.
* **Арт события** (`ui/event/event_illustration.gd::EVENT_ART_PATHS`) —
  ключирован по `event_title` (стабильному ключу), не по переведённому
  тексту: подбор иллюстрации и seed процедурного фона не должны зависеть от
  локали.
* **Сортировка карт** (`ui/card_sort_utils.gd`) — сравнивает
  `get_display_name()`, т.е. сортирует по переведённому имени в текущей
  локали, а не по ключу.

## Строки с параметрами и числами

Плейсхолдеры — через стандартный `%`-форматтер GDScript, без конкатенации
предложений из кусков:

```gdscript
# Правильно:
tr("UI_RUN_SUMMARY_FLOORS_PASSED") % floors_passed
tr("UI_MAIN_MENU_FLOOR_PROGRESS") % [next_floor, map_data.floor_count]

# Неправильно — нельзя собирать предложение из переведённых кусков:
tr("FLOORS") + ": " + str(floors_passed)
```

В `.po` `msgstr` соответственно содержит `%d`/`%s` на тех же местах, что и в
`ru.po`. У каждого языка порядок слов может отличаться, но плейсхолдеры и их
количество должны совпадать.

Множественное число в проекте пока не встречается (везде счётчики вида
`"Побеждено элит: %d"`, без склонений по числу) — если понадобится, Godot
поддерживает `tr_n()` / `msgid_plural` в `.po`; в проекте это пока не
используется.

## Выбор языка в настройках

`ui/settings/settings_screen.gd` — секция "Язык", список `LOCALE_ORDER`.
Выбор сохраняется через `ProfileManager.set_locale(code)` в
`profile["settings"]["locale"]` (в `profile.json`) и применяется мгновенно
через `TranslationServer.set_locale(code)`.

**Важно:** смена локали применяется без перезапуска **приложения**, но экран
настроек сам себя перестраивает через `get_tree().reload_current_scene()`,
чтобы уже нарисованные `Label`/`Button` обновили текст (Godot не
перерисовывает уже установленный `.text` автоматически при смене локали).
Остальные экраны получают актуальный текст естественным образом, т.к.
строятся заново при каждом переходе (`_build_ui()` в `_ready()`).

`ProfileManager.DEFAULT_LOCALE = "ru"` — используется, если в сохранении ещё
нет `settings.locale` (новый профиль или профиль до этой фичи).
`"locale"` намеренно не входит в `ProfileManager.DEFAULT_SETTINGS`, чтобы
`reset_settings()` (сброс звука) не сбрасывал выбранный язык.

## Добавление нового языка

1. Скопировать `localization/arcomage.pot` в `localization/<code>.po`
   (`<code>` — код локали Godot, например `de`, `es`, `uk`).
2. Заполнить `msgstr` для каждого `msgid` (ключа) переводом. Порядок ключей
   в `.po` не важен для Godot, но для читаемости диффов стоит сохранять
   исходный.
3. Добавить путь в `project.godot`:
   ```
   locale/translations=PackedStringArray("res://localization/ru.po", "res://localization/en.po", "res://localization/<code>.po")
   ```
4. Добавить код и подпись языка в `ui/settings/settings_screen.gd`:
   `LOCALE_LABELS[<code>] = "UI_SETTINGS_LANGUAGE_<CODE>"` и добавить
   `<code>` в `LOCALE_ORDER`, а сам `UI_SETTINGS_LANGUAGE_<CODE>` — во все
   существующие `.po` (иначе на других языках пункт меню будет показывать
   сырой ключ).
5. Прогнать `python3 tools/check_localization.py`, чтобы убедиться, что
   новый `.po` не потерял ни одного ключа (сравнение идёт против **всех**
   `.po`, перечисленных как источник использования в коде — на практике
   основной ориентир — `ru.po`/`en.po`, но иметь другой набор строк в
   новом `.po` не должно приводить к отсутствующим ключам, если файл
   сделан из актуального `arcomage.pot`).
6. Проверить вручную в редакторе Godot: переключить локаль в настройках,
   убедиться, что нигде не отображается сырой `UI_.../CARD_.../EVENT_...`
   ключ вместо текста (значит для этого ключа нет `msgstr` в новом `.po`
   или код читает сырое поле ресурса вместо `get_display_*()`).

## Проверка ключей (CI)

`tools/check_localization.py` (только stdlib Python3, Godot не нужен; джоб
`localization-check` в `.github/workflows/ci.yml`) сравнивает:

* ключи, реально встречающиеся в `ui/**/*.gd`, `entities/**/*.gd`,
  `core/**/*.gd` (вызовы `tr("KEY")`, а также значения-ключи в словарях типа
  `GENERATOR_LABELS`, `GROUP_LABEL_KEYS`, `UPGRADE_CATALOG`,
  `EVENT_ART_PATHS`) и в `data/cards|artifacts|events/*.tres`;
* ключи, объявленные в `localization/ru.po` и `localization/en.po`.

Падает, если: ключ используется, но отсутствует хотя бы в одном из
`ru.po`/`en.po` ("missing"), либо ключ объявлен в `.po`, но нигде не
используется ("unused", можно смягчить до предупреждения флагом
`--allow-unused`).

Ограничение: проверка основана на regex по строковым литералам, а не на
разборе AST/Godot-ресурсов — динамически собранный ключ (конкатенация строк
в рантайме) checker не увидит. В проекте на момент написания такого нет.

## Известные ограничения / незакрытые вопросы

* `GAME_TITLE` в `ui/main_menu.gd` (`"Башни магов: Дуэль"`, совпадает с
  `application/config/name` в `project.godot`) **не** заведён как ключ
  локализации — это название игры (бренд), а не переводимый UI-текст;
  сверяется тестом `tests/test_main_menu_screen.gd`.
* Отладочные `print("[DEBUG] ...")`, `push_error(...)` и подобные логи не
  локализуются намеренно — это не видимый игроку текст.
* Тексты `.po`, соответствующие UI-экранам, сконвертированным на `tr()` в
  этой сессии до сжатия контекста агента (`meta_shop`, `event_screen` (кроме
  заголовков секций), `shop`, `rest`, `battle`, `reward`, `deck`), написаны
  по памяти заново, с сохранением смысла и тона остального текста игры, но
  **без гарантии побайтового совпадения** с текстом, который был в интерфейсе
  до этого тикета. Если в GUT-тестах где-то остались сравнения с точным
  старым текстом экрана (`assert_eq(label.text, "...")`), их может
  понадобиться поправить под актуальный `ru.po` — см. раздел «Что не
  проверено» итогового комментария к тикету ARC (аудит тестов).
