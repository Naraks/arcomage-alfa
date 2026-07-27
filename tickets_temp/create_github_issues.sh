#!/usr/bin/env bash
# Автоматически сгенерировано из dev_plan_tickets.md — переносит весь бэклог
# (78 тикетов, ARC-001..ARC-078) в GitHub Issues репозитория Naraks/arcomage-alfa.
#
# Требования: `gh` CLI, авторизованный (`gh auth login`), с доступом к репозиторию.
# Идемпотентность НЕ гарантируется — повторный запуск создаст дубликаты issue.
# Уже закрытые в бэклоге тикеты (со статусом ✅) создаются и сразу закрываются —
# это сохраняет историю выполненной работы в GitHub.
set -euo pipefail

REPO="Naraks/arcomage-alfa"
echo "Репозиторий: $REPO"

# --- Метка соответствия ID тикета -> номер issue (для справки, пишется в файл) ---
MAP_FILE="arc_issue_map.tsv"
: > "$MAP_FILE"

# --- 1. Метки (labels) ---
echo "Создаю метки..."
gh label create 'epic: A' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: B' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: C' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: D' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: E' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: F' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: G' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: H' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: I' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'epic: J' --repo "$REPO" --color ededed --force >/dev/null 2>&1 || true
gh label create 'priority: critical' --repo "$REPO" --color b60205 --force >/dev/null 2>&1 || true
gh label create 'priority: high' --repo "$REPO" --color d93f0b --force >/dev/null 2>&1 || true
gh label create 'priority: low' --repo "$REPO" --color c2e0c6 --force >/dev/null 2>&1 || true
gh label create 'priority: medium' --repo "$REPO" --color fbca04 --force >/dev/null 2>&1 || true
gh label create 'type: bug' --repo "$REPO" --color d73a4a --force >/dev/null 2>&1 || true
gh label create 'type: story' --repo "$REPO" --color 0e8a16 --force >/dev/null 2>&1 || true
gh label create 'type: task' --repo "$REPO" --color 1d76db --force >/dev/null 2>&1 || true

# --- 2. Тикеты ---

# ARC-060 — Зафиксировать Git-процесс (ветвление, ревью, коммиты)
echo "Создаю ARC-060..."
BODY_ARC_060=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: High · Оценка: 2 SP


**Описание:** Определить и задокументировать (`CONTRIBUTING.md`): модель веток (рекомендация для соло/малой
команды — trunk-based: `main` + короткоживущие `feature/ARC-XXX-...`, без долгоживущего `develop`), формат
сообщений коммитов (например, `ARC-042: краткое описание`), обязательность связывания коммитов/PR с ID тикета
из этого бэклога.

**Критерии приёмки:**
- [x] `CONTRIBUTING.md` в корне репозитория описывает ветвление и формат коммитов.
- [x] Согласовано, что каждый PR ссылается на `ARC-XXX`.

> ✅ Реализовано: см. `CONTRIBUTING.md` в корне проекта.

---
_Перенесено из `dev_plan_tickets.md` (ARC-060)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-060: Зафиксировать Git-процесс (ветвление, ревью, коммиты)' --body "$BODY_ARC_060" --label 'type: task,priority: high,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-060\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: см. `CONTRIBUTING.md` в корне проекта.'
echo "  -> $ISSUE_URL"

# ARC-061 — Настроить Git LFS для бинарных ассетов
echo "Создаю ARC-061..."
BODY_ARC_061=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-008


**Описание:** По мере роста арт-контента (иконки карт из ARC-022, частицы из ARC-045, аудио) обычный git будет
раздувать историю. Уже сейчас в репозитории лежали случайные экспортные бинарники на ~100 МБ (ARC-008) —
признак того, что бинарные файлы не отделены от исходников политикой репозитория.

**Технические детали:**
- `.gitattributes` уже существует — расширить его правилами `*.png *.wav *.ogg *.ttf filter=lfs diff=lfs merge=lfs -text` и т.п.
- Прогнать `git lfs migrate` для уже закоммиченных крупных бинарников, если они есть в истории.

**Критерии приёмки:**
- [x] Новые бинарные ассеты автоматически уходят в LFS.
- [x] Размер обычной git-истории (без LFS) не растёт от добавления арта.

> ✅ Реализовано: `.gitattributes` расширен LFS-правилами, `git lfs install` выполнен в репозитории,
> инструкция — в `CONTRIBUTING.md`. Проверено вручную: тестовый `.png` закоммичен как LFS-pointer
> (`version https://git-lfs.github.com/spec/v1...`), а не бинарными байтами.

---
_Перенесено из `dev_plan_tickets.md` (ARC-061)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-061: Настроить Git LFS для бинарных ассетов' --body "$BODY_ARC_061" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-061\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: `.gitattributes` расширен LFS-правилами, `git lfs install` выполнен в репозитории, инструкция — в `CONTRIBUTING.md`. Проверено вручную: тестовый `.png` закоммичен как LFS-pointer (`version https://git-lfs.github.com/spec/v1...`), а не бинарными байтами.'
echo "  -> $ISSUE_URL"

# ARC-062 — Pre-commit хуки и единый стиль GDScript
echo "Создаю ARC-062..."
BODY_ARC_062=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 3 SP


**Описание:** В коде уже есть расхождения по стилю (например, `default_ai_strategy.gd` использует типизированные
сигнатуры `Array[CardData]`, `aggressive_ai_strategy.gd` — нет; часть файлов использует табы иначе, чем задано в
`.editorconfig`). Подключить `gdformat`/`gdlint` (пакет `gdtoolkit`) как pre-commit хук.

**Критерии приёмки:**
- [x] `pre-commit` конфиг форматирует/линтит `.gd`-файлы перед коммитом.
- [x] Весь существующий код прогнан через форматтер один раз (отдельный «чистый» коммит без функциональных изменений).

> ✅ Реализовано: `.pre-commit-config.yaml` (gdtoolkit `gdformat`/`gdlint`) и `.editorconfig` (`[*.gd]`
> — tab, размер 4) настроены. `pre-commit run --all-files` прогнан по всем 19 `.gd`-файлам, замечания
> `gdlint` (порядок `class_name`/`extends`, порядок `const`/`var`, неиспользуемый аргумент) исправлены,
> результат закоммичен отдельным коммитом `chore: прогнать gdformat по кодовой базе`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-062)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-062: Pre-commit хуки и единый стиль GDScript' --body "$BODY_ARC_062" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-062\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: `.pre-commit-config.yaml` (gdtoolkit `gdformat`/`gdlint`) и `.editorconfig` (`[*.gd]` — tab, размер 4) настроены. `pre-commit run --all-files` прогнан по всем 19 `.gd`-файлам, замечания `gdlint` (порядок `class_name`/`extends`, порядок `const`/`var`, неиспользуемый аргумент) исправлены, результат закоммичен отдельным коммитом `chore: прогнать gdformat по кодовой базе`.'
echo "  -> $ISSUE_URL"

# ARC-063 — Шаблоны PR/issue и правила ревью
echo "Создаю ARC-063..."
BODY_ARC_063=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Low · Оценка: 1 SP
Зависит от: ARC-060


**Описание:** Добавить `.github/PULL_REQUEST_TEMPLATE.md` (чеклист: тесты добавлены/обновлены, привязан ARC-ID,
проверено в редакторе) и шаблон issue для багов, найденных при плейтестах.

**Критерии приёмки:**
- [x] Шаблоны PR и issue существуют и используются при создании новых PR/issue.

> ✅ Реализовано: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/bug_report.md` и
> `config.yml` запушены в `github.com/Naraks/arcomage-alfa`. Проверено вручную: New Issue в GitHub UI
> подставляет заголовок `[BUG]` и структуру шаблона (Что произошло / Как воспроизвести / Ожидалось /
> Окружение / Связанный тикет).

---
_Перенесено из `dev_plan_tickets.md` (ARC-063)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-063: Шаблоны PR/issue и правила ревью' --body "$BODY_ARC_063" --label 'type: task,priority: low,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-063\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/bug_report.md` и `config.yml` запушены в `github.com/Naraks/arcomage-alfa`. Проверено вручную: New Issue в GitHub UI подставляет заголовок `[BUG]` и структуру шаблона (Что произошло / Как воспроизвести / Ожидалось / Окружение / Связанный тикет).'
echo "  -> $ISSUE_URL"

# ARC-064 — Защита ветки main
echo "Создаю ARC-064..."
BODY_ARC_064=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 1 SP
Зависит от: ARC-066


**Описание:** После появления CI (ARC-066) включить правило: PR нельзя смержить в `main`, пока не прошли
автотесты (обязательная проверка статуса).

**Критерии приёмки:**
- [x] `main` защищена от прямого пуша.
- [x] Мерж блокируется при красном статусе CI.

> ✅ Реализовано: branch protection rule на `main` в GitHub Settings → Branches — обязателен PR
> (прямой пуш запрещён) и обязательна зелёная проверка джоба `tests` из `ci.yml` (ARC-066) перед
> мержем.

---
_Перенесено из `dev_plan_tickets.md` (ARC-064)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-064: Защита ветки main' --body "$BODY_ARC_064" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-064\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: branch protection rule на `main` в GitHub Settings → Branches — обязателен PR (прямой пуш запрещён) и обязательна зелёная проверка джоба `tests` из `ci.yml` (ARC-066) перед мержем.'
echo "  -> $ISSUE_URL"

# ARC-065 — Ревизия .gitignore и очистка репозитория от бинарников
echo "Создаю ARC-065..."
BODY_ARC_065=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: High · Оценка: 1 SP
Зависит от: ARC-008


**Описание:** Расширяет ARC-008 — убедиться, что `.godot/` (кэш импорта), экспортные бандлы (`/web/`, `*.exe`,
`*.pck`, `*.console.exe`) и пользовательские сохранения не попадают в репозиторий вообще, а не только удалить
уже закоммиченные.

**Критерии приёмки:**
- [x] `git status` после полного экспорта в Web и Windows не показывает новых файлов на коммит.

> ✅ Реализовано и проверено: `.gitignore` почищен (убран задвоенный `/_to_delete/`) и расширен —
> добавлены служебные файлы GUT (`.gut_editor_config.json`, `/gut_results.xml`), `.DS_Store`/
> `Thumbs.db` и `/GTA_VI.*` (реальный `export_path` обоих пресетов — Windows и Web оба экспортируются
> в корень проекта под этим именем). Заодно нашли и исправили попутный баг: несколько бинарников GUT
> (`.ttf`/`.png`) были закоммичены в обход Git LFS из песочницы агента — перепривязаны. Пользовательские
> сохранения не попадают в репозиторий в принципе (виртуальный `user://` путь Godot вне папки проекта).
> После реального экспорта в Web и Windows `git status` — чистый (`nothing to commit, working tree clean`).

---
_Перенесено из `dev_plan_tickets.md` (ARC-065)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-065: Ревизия .gitignore и очистка репозитория от бинарников' --body "$BODY_ARC_065" --label 'type: task,priority: high,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-065\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано и проверено: `.gitignore` почищен (убран задвоенный `/_to_delete/`) и расширен — добавлены служебные файлы GUT (`.gut_editor_config.json`, `/gut_results.xml`), `.DS_Store`/ `Thumbs.db` и `/GTA_VI.*` (реальный `export_path` обоих пресетов — Windows и Web оба экспортируются в корень проекта под этим именем). Заодно нашли и исправили попутный баг: несколько бинарников GUT (`.ttf`/`.png`) были закоммичены в обход Git LFS из песочницы агента — перепривязаны. Пользовательские сохранения не попадают в репозиторий в принципе (виртуальный `user://` путь Godot вне папки проекта). После реального экспорта в Web и Windows `git status` — чистый (`nothing to commit, working tree clean`).'
echo "  -> $ISSUE_URL"

# ARC-066 — Базовый CI: сборка + прогон тестов на каждый push/PR
echo "Создаю ARC-066..."
BODY_ARC_066=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-073


**Описание:** Развёрнутая версия ARC-055. Настроить workflow (GitHub Actions, если репозиторий на GitHub) с
шагами: checkout → установка headless Godot 4.7 (через `barichello/godot-ci` образ или ручную загрузку бинаря
нужной версии) → импорт проекта (`--headless --editor --quit` для прогрева `.godot/`) → запуск тестов (после
ARC-073 — через GUT в headless-режиме с ненулевым exit-кодом при провале).

**Критерии приёмки:**
- [x] Workflow запускается на каждый push и PR.
- [x] При падении хотя бы одного теста джоба CI помечается как failed (не просто пишет в лог).
- [x] Время выполнения зафиксировано как baseline (для контроля деградации CI по мере роста тестов).

> ✅ Реализовано: `.github/workflows/ci.yml` (checkout+LFS → скачать Godot 4.7.1 → прогреть импорт →
> `gut_cmdln.gd -gexit` → JUnit-отчёт как artifact). По пути поймали и починили баг с булевыми
> CLI-флагами GUT (`optparse.gd` игнорирует значение после `=` у bool-опций — любое присутствие
> флага инвертирует дефолт; `-gexit_on_success` и `-gjunit_xml_timestamp=false` из-за этого либо
> мешали, либо делали обратное задуманному, оба убраны). Прогон на GitHub Actions зелёный, оба
> artifact'а (`gut-test-results`, `web-build`) приезжают корректно. Длительность прогона видна во
> вкладке Actions и служит baseline — отдельно фиксировать число в документе не нужно.

---
_Перенесено из `dev_plan_tickets.md` (ARC-066)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-066: Базовый CI: сборка + прогон тестов на каждый push/PR' --body "$BODY_ARC_066" --label 'type: task,priority: high,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-066\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: `.github/workflows/ci.yml` (checkout+LFS → скачать Godot 4.7.1 → прогреть импорт → `gut_cmdln.gd -gexit` → JUnit-отчёт как artifact). По пути поймали и починили баг с булевыми CLI-флагами GUT (`optparse.gd` игнорирует значение после `=` у bool-опций — любое присутствие флага инвертирует дефолт; `-gexit_on_success` и `-gjunit_xml_timestamp=false` из-за этого либо мешали, либо делали обратное задуманному, оба убраны). Прогон на GitHub Actions зелёный, оба artifact'\''а (`gut-test-results`, `web-build`) приезжают корректно. Длительность прогона видна во вкладке Actions и служит baseline — отдельно фиксировать число в документе не нужно.'
echo "  -> $ISSUE_URL"

# ARC-067 — CI-джоб автоматической сборки Web-экспорта
echo "Создаю ARC-067..."
BODY_ARC_067=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: High · Оценка: 3 SP
Зависит от: ARC-006, ARC-066


**Описание:** После настройки HTML5-пресета (ARC-006) — автоматизировать headless-экспорт
(`godot --headless --export-release "Web" ./web/index.html`) в CI на каждый мерж в `main`, чтобы сразу видеть,
если чьи-то изменения ломают веб-сборку.

**Критерии приёмки:**
- [x] Джоб собирает Web-бандл в CI без ошибок на текущем `main`.
- [x] Собранный бандл прикрепляется как build artifact (см. ARC-070).

> ✅ Реализовано и проверено: джоб `export-web` в `.github/workflows/ci.yml` (запускается после
> `tests`, `needs: tests`) — скачивает Godot и export-шаблоны, прогревает импорт, гонит
> `godot --headless --export-release "Web" ./web/index.html` и прикладывает `web/` как build artifact
> `web-build`. Прогон зелёный, artifact собирается.

---
_Перенесено из `dev_plan_tickets.md` (ARC-067)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-067: CI-джоб автоматической сборки Web-экспорта' --body "$BODY_ARC_067" --label 'type: task,priority: high,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-067\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано и проверено: джоб `export-web` в `.github/workflows/ci.yml` (запускается после `tests`, `needs: tests`) — скачивает Godot и export-шаблоны, прогревает импорт, гонит `godot --headless --export-release "Web" ./web/index.html` и прикладывает `web/` как build artifact `web-build`. Прогон зелёный, artifact собирается.'
echo "  -> $ISSUE_URL"

# ARC-068 — CI-джоб сборки Windows Desktop для внутренних плейтестов
echo "Создаю ARC-068..."
BODY_ARC_068=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-066


**Описание:** Отдельный пресет для внутренних тестировщиков (быстрее собирать/раздавать, чем просить открыть
браузерную сборку) — переименовать текущий стихийный пресет `Windows Desktop` (сейчас экспортирует в
`GTA_VI.exe`, см. ARC-008) в осмысленное имя и включить в CI по требованию (manual trigger / тег `playtest-*`).

**Критерии приёмки:**
- [x] Пресет переименован, путь экспорта — `./builds/alfa-windows/Alfa.exe`.
- [x] Сборка запускается по git-тегу вида `playtest-YYYYMMDD` или вручную из CI.

> ✅ Реализовано и проверено: `export_path` пресета `Windows Desktop` — `./builds/alfa-windows/Alfa.exe`
> (было `./GTA_VI.exe`); `/GTA_VI.*` убран из `.gitignore` как более не нужный. Джоб
> `build-windows-playtest` триггерится тегом `playtest-*` или вручную (`workflow_dispatch`), не
> запускается на обычных push/PR; собирает Windows-бинарник кросс-компиляцией на `ubuntu-latest` и
> прикладывает `alfa-windows-playtest` как artifact. Прогон подтверждён.

---
_Перенесено из `dev_plan_tickets.md` (ARC-068)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-068: CI-джоб сборки Windows Desktop для внутренних плейтестов' --body "$BODY_ARC_068" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-068\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано и проверено: `export_path` пресета `Windows Desktop` — `./builds/alfa-windows/Alfa.exe` (было `./GTA_VI.exe`); `/GTA_VI.*` убран из `.gitignore` как более не нужный. Джоб `build-windows-playtest` триггерится тегом `playtest-*` или вручную (`workflow_dispatch`), не запускается на обычных push/PR; собирает Windows-бинарник кросс-компиляцией на `ubuntu-latest` и прикладывает `alfa-windows-playtest` как artifact. Прогон подтверждён.'
echo "  -> $ISSUE_URL"

# ARC-069 — Автоматическое версионирование и CHANGELOG
echo "Создаю ARC-069..."
BODY_ARC_069=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-060


**Описание:** Ввести семантическое версионирование билдов (например, на основе тегов `vX.Y.Z`), автогенерацию
`CHANGELOG.md` из сообщений коммитов/PR (`git-cliff`, `release-please` или аналог), отображение версии сборки
в главном меню (полезно при багрепортах от плейтестеров и при сабмите в Яндекс Игры).

**Критерии приёмки:**
- [x] Версия автоматически подставляется в сборку (например, через `--define` при экспорте или JSON-файл версии).
- [x] `CHANGELOG.md` обновляется автоматически при релизном теге.

> ✅ Реализовано и проверено: `core/build_version.gd` (автозагрузка `BuildVersion`) читает
> `res://build_version.json` и отдаёт `get_display_string()` ("v1.2.3 (abc1234)" / "dev" в редакторе,
> где файла нет); `ui/main_menu.tscn`/`main_menu.gd` показывают её в `VersionLabel`. Тесты —
> `tests/test_build_version.gd`. `cliff.toml` настроен под соглашение коммитов репозитория
> (`ARC-XXX: ...` / `chore: ...`, без Conventional Commits) — группирует их в разделы "Тикеты"/"Прочее".
> `.github/workflows/release.yml` триггерится тегом `vX.Y.Z`: джоб `changelog-pr` генерирует
> `CHANGELOG.md` через `orhun/git-cliff-action` и открывает PR в `main` (`peter-evans/create-pull-request`,
> т.к. `main` защищён от прямого пуша — см. ARC-064); джоб `github-release` публикует GitHub Release с
> release-notes для тега. `ci.yml` (джобы `export-web`, `build-windows-playtest`) перед экспортом пишет
> `build_version.json` из `git describe --tags --always --dirty --match 'v*.*.*'` + короткий SHA.
> Прогон подтверждён на реальном теге: PR с CHANGELOG.md и GitHub Release создались, версия
> отображается в собранной игре.

---
_Перенесено из `dev_plan_tickets.md` (ARC-069)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-069: Автоматическое версионирование и CHANGELOG' --body "$BODY_ARC_069" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-069\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано и проверено: `core/build_version.gd` (автозагрузка `BuildVersion`) читает `res://build_version.json` и отдаёт `get_display_string()` ("v1.2.3 (abc1234)" / "dev" в редакторе, где файла нет); `ui/main_menu.tscn`/`main_menu.gd` показывают её в `VersionLabel`. Тесты — `tests/test_build_version.gd`. `cliff.toml` настроен под соглашение коммитов репозитория (`ARC-XXX: ...` / `chore: ...`, без Conventional Commits) — группирует их в разделы "Тикеты"/"Прочее". `.github/workflows/release.yml` триггерится тегом `vX.Y.Z`: джоб `changelog-pr` генерирует `CHANGELOG.md` через `orhun/git-cliff-action` и открывает PR в `main` (`peter-evans/create-pull-request`, т.к. `main` защищён от прямого пуша — см. ARC-064); джоб `github-release` публикует GitHub Release с release-notes для тега. `ci.yml` (джобы `export-web`, `build-windows-playtest`) перед экспортом пишет `build_version.json` из `git describe --tags --always --dirty --match '\''v*.*.*'\''` + короткий SHA. Прогон подтверждён на реальном теге: PR с CHANGELOG.md и GitHub Release создались, версия отображается в собранной игре.'
echo "  -> $ISSUE_URL"

# ARC-070 — Публикация билд-артефактов CI
echo "Создаю ARC-070..."
BODY_ARC_070=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 1 SP
Зависит от: ARC-067, ARC-068


**Описание:** Чтобы не пересобирать вручную для каждого плейтеста — публиковать Web/Windows сборки как
скачиваемые артефакты CI (или на отдельный staging-хостинг для Web-сборки, чтобы можно было открыть прямо по
ссылке в браузере, максимально близко к условиям Яндекс Игр).

**Критерии приёмки:**
- [ ] Любой участник команды может скачать последнюю успешную сборку без локальной сборки в Godot.
- [ ] Web-сборка доступна по прямой ссылке для проверки в браузере (в т.ч. на мобильном).

---
_Перенесено из `dev_plan_tickets.md` (ARC-070)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-070: Публикация билд-артефактов CI' --body "$BODY_ARC_070" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-070\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-071 — Уведомления о статусе CI
echo "Создаю ARC-071..."
BODY_ARC_071=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Low · Оценка: 1 SP
Зависит от: ARC-066


**Описание:** Небольшая, но полезная мелочь — падение CI/готовность новой сборки должны быть заметны без
захода в веб-интерфейс CI (уведомление в Telegram/Discord/почту).

**Критерии приёмки:**
- [ ] При падении обязательной проверки на `main` приходит уведомление.

---
_Перенесено из `dev_plan_tickets.md` (ARC-071)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-071: Уведомления о статусе CI' --body "$BODY_ARC_071" --label 'type: task,priority: low,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-071\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-072 — Перейти на полноценный тест-фреймворк (GUT)
echo "Создаю ARC-072..."
BODY_ARC_072=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: High · Оценка: 3 SP


**Описание:** Сейчас `tests/test_runner.gd` — это самописный `RefCounted`-скрипт с ручными `assert()`, который
запускается только вручную при дебаг-старте главного меню (`main_menu.gd._ready()`), без структуры test
suite/test case, без отчёта в формате, понятном CI (падение через `assert()` в дебаг-сборке останавливает всю
игру, а не отмечает один упавший тест). Нужен стандартный фреймворк — **GUT (Godot Unit Test)** — с поддержкой
headless-запуска и XML/JUnit-отчётов для CI.

**Критерии приёмки:**
- [x] Плагин GUT установлен и настроен (`addons/gut`), есть `.gutconfig.json`.
- [x] Тесты запускаются командой `godot --headless -s addons/gut/gut_cmdln.gd` с ненулевым exit-кодом при провале.

> ✅ Реализовано: GUT 9.7.1 установлен в `addons/gut`, плагин включён, `.gutconfig.json` настроен на
> `res://tests`. Прогон подтверждён вручную: 25 тестов, 30 assert'ов, всё зелёное за 0.44с. Ненулевой
> exit-код при провале — встроенное поведение `gut_cmdln.gd` (задокументировано автором фреймворка),
> отдельно намеренный провал не воспроизводили.

---
_Перенесено из `dev_plan_tickets.md` (ARC-072)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-072: Перейти на полноценный тест-фреймворк (GUT)' --body "$BODY_ARC_072" --label 'type: task,priority: high,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-072\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: GUT 9.7.1 установлен в `addons/gut`, плагин включён, `.gutconfig.json` настроен на `res://tests`. Прогон подтверждён вручную: 25 тестов, 30 assert'\''ов, всё зелёное за 0.44с. Ненулевой exit-код при провале — встроенное поведение `gut_cmdln.gd` (задокументировано автором фреймворка), отдельно намеренный провал не воспроизводили.'
echo "  -> $ISSUE_URL"

# ARC-073 — Мигрировать существующие тесты и расширить unit-покрытие
echo "Создаю ARC-073..."
BODY_ARC_073=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-072


**Описание:** Перенести `test_apply_damage` из `tests/test_runner.gd` в GUT-формат (`test_match_manager.gd` с
методами `test_...` и `assert_eq`/`assert_true` вместо голого `assert()`), затем добавить недостающее базовое
покрытие ядра, которое сейчас отсутствует полностью: розыгрыш карты и списание ресурсов (`can_afford`/
`play_card_by_index`), проверка условий победы (`check_win` по всем трём сценариям — высота башни, обнуление
HP, 300 ресурсов), сброс карты в патовой ситуации у ИИ.

**Критерии приёмки:**
- [x] Старый `test_runner.gd` удалён, вызов из `main_menu.gd._ready()` тоже.
- [x] Минимум 15 unit-тестов покрывают `match_manager.gd` и `artifact_manager.gd`.
- [x] Каждый новый тикет из Эпиков B–E, добавляющий логику в `match_manager`/`artifact_manager`, обязан приходить с тестом в том же PR (правило уже зафиксировано в чеклисте ревью `CONTRIBUTING.md`).

> ✅ Реализовано: `tests/test_match_manager.gd` (17 тестов: `apply_damage`, `can_afford`,
> `play_card_by_index`, `discard_card_by_index`, `check_win` по всем сценариям) и
> `tests/test_artifact_manager.gd` (7 тестов: `apply_artifact_effect`, `_check_artifacts` с
> совпадающим/несовпадающим триггером). `test_runner.gd` и вызов из `main_menu.gd._ready()` удалены.
> Прогон подтверждён вручную: GUT насчитал 25 тестов (30 assert'ов), все прошли.

---
_Перенесено из `dev_plan_tickets.md` (ARC-073)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-073: Мигрировать существующие тесты и расширить unit-покрытие' --body "$BODY_ARC_073" --label 'type: task,priority: high,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-073\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано: `tests/test_match_manager.gd` (17 тестов: `apply_damage`, `can_afford`, `play_card_by_index`, `discard_card_by_index`, `check_win` по всем сценариям) и `tests/test_artifact_manager.gd` (7 тестов: `apply_artifact_effect`, `_check_artifacts` с совпадающим/несовпадающим триггером). `test_runner.gd` и вызов из `main_menu.gd._ready()` удалены. Прогон подтверждён вручную: GUT насчитал 25 тестов (30 assert'\''ов), все прошли.'
echo "  -> $ISSUE_URL"

# ARC-074 — Тестовые фикстуры (dummy-карты, dummy-игроки)
echo "Создаю ARC-074..."
BODY_ARC_074=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-072


**Описание:** Чтобы тесты не зависели от реального контента (`data/cards/*.tres`, который будет часто меняться
из-за баланса — Эпик C), завести отдельные тестовые `CardData`/`PlayerData`/`ArtifactData` с предсказуемыми
значениями, создаваемые прямо в коде теста (`CardData.new()` + ручное заполнение полей), а не через `load()`
боевых `.tres`.

**Критерии приёмки:**
- [ ] Юнит-тесты ядра не имеют прямых путей к `data/cards/*.tres` в самих тестах (кроме отдельного
      контент-теста из ARC-019).

---
_Перенесено из `dev_plan_tickets.md` (ARC-074)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-074: Тестовые фикстуры (dummy-карты, dummy-игроки)' --body "$BODY_ARC_074" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-074\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-075 — Smoke-тест запуска экспортированного билда
echo "Создаю ARC-075..."
BODY_ARC_075=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-067


**Описание:** Юнит-тесты проверяют логику, но не гарантируют, что реальный экспортированный HTML5-билд вообще
запускается в браузере без JS-ошибок (частая проблема веб-экспорта Godot — падения только в WASM-окружении).
Добавить в CI шаг, поднимающий собранный Web-бандл (ARC-067) headless-браузером (Playwright/Chromium,
уже доступен в тулинге), который проверяет, что главное меню отрисовалось и в консоли браузера нет ошибок.

**Критерии приёмки:**
- [ ] CI-джоб открывает собранный Web-билд в headless Chromium и падает при JS/WASM-ошибках в консоли.

---
_Перенесено из `dev_plan_tickets.md` (ARC-075)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-075: Smoke-тест запуска экспортированного билда' --body "$BODY_ARC_075" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-075\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-076 — Регрессионный набор «полная партия»
echo "Создаю ARC-076..."
BODY_ARC_076=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-054, ARC-073


**Описание:** Дополняет балансировочный симулятор ИИ-против-ИИ (ARC-054) набором детерминированных
регрессионных сценариев: фиксированные стартовые руки/сиды, по которым заранее известен исход (например,
«игрок А выигрывает на ходу 7 при таких-то картах») — чтобы ловить не баланс, а именно поломки логики после
рефакторинга (ARC-004, ARC-005, ARC-021).

**Критерии приёмки:**
- [ ] Минимум 5 детерминированных сценариев с зафиксированным ожидаемым исходом встроены в набор тестов CI.

---
_Перенесено из `dev_plan_tickets.md` (ARC-076)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-076: Регрессионный набор «полная партия»' --body "$BODY_ARC_076" --label 'type: task,priority: medium,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-076\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-077 — Отчёт о покрытии тестами
echo "Создаю ARC-077..."
BODY_ARC_077=$(cat <<'ARC_EOF'
**Эпик J — Репозиторий, CI/CD и автоматизация тестирования**

Тип: Task · Приоритет: Low · Оценка: 2 SP
Зависит от: ARC-072


**Описание:** Не строгое требование 100% покрытия, но видимость тренда — какие файлы/функции ядра (в первую
очередь `match_manager.gd`, `artifact_manager.gd`, AI-стратегии) не покрыты тестами, чтобы осознанно решать,
где риск регрессии выше всего.

**Критерии приёмки:**
- [ ] После каждого прогона CI формируется отчёт о покрытии (даже в простом текстовом виде) как build artifact.

---
_Перенесено из `dev_plan_tickets.md` (ARC-077)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-077: Отчёт о покрытии тестами' --body "$BODY_ARC_077" --label 'type: task,priority: low,epic: J')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-077\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-001 — ProfileManager не зарегистрирован как Autoload
echo "Создаю ARC-001..."
BODY_ARC_001=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Bug · Приоритет: Blocker · Оценка: 1 SP


**Описание:** `match_manager.gd:30` вызывает `get_node_or_null("/root/ProfileManager")`, ожидая synglton, но в
`project.godot` секция `[autoload]` содержит только `YandexSDK`, `GameEvents`, `MatchManager`, `MatchSettings`.
В результате бонусы мета-прогрессии (`tower_hp_bonus`, `resource_gain_bonus`) никогда не применяются — молча,
без ошибки.

**Критерии приёмки:**
- [ ] `ProfileManager="*res://core/profile_manager.gd"` добавлен в `[autoload]`.
- [ ] В `setup_match()` подтверждено логом/тестом, что бонусы реально прибавляются к `tower_hp`/`quarry`.
- [ ] Написан unit-тест на применение бонуса (см. ARC-053).

---
_Перенесено из `dev_plan_tickets.md` (ARC-001)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-001: ProfileManager не зарегистрирован как Autoload' --body "$BODY_ARC_001" --label 'type: bug,priority: critical,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-001\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-002 — Замкнуть цикл «Бой → Карта мира»
echo "Создаю ARC-002..."
BODY_ARC_002=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Bug · Приоритет: Blocker · Оценка: 5 SP


**Описание:** `battle_screen.gd._on_match_ended()` показывает только Victory/Defeat и кнопку Restart, которая
вызывает `_test_setup()` заново. Игрок никогда не возвращается на карту мира, узел карты не помечается
`is_completed = true`, а `MatchSettings` вообще не хранит ссылку на то, с какого узла карты был начат бой.
Это блокирует весь роглик-цикл (Эпик B).

**Технические детали:**
- Добавить в `MatchSettings`: `came_from_map: bool`, `current_map_node: MapNodeData`.
- `world_map_screen._on_node_pressed()` перед переходом в бой должен проставлять эти поля.
- `battle_screen._on_match_ended()` должен: если `MatchSettings.came_from_map` — пометить узел завершённым и
  вызвать `change_scene_to_file("res://ui/map/world_map_screen.tscn")` (после экрана награды, см. ARC-015);
  если бой был тестовым (из главного меню) — оставить текущее поведение Restart.

**Критерии приёмки:**
- [ ] После победы в бою, начатом с карты, игрок возвращается на карту мира.
- [ ] Пройденный узел визуально помечен как завершённый (кнопка `disabled`).
- [ ] Прямой тестовый бой из главного меню продолжает работать как раньше.

---
_Перенесено из `dev_plan_tickets.md` (ARC-002)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-002: Замкнуть цикл «Бой → Карта мира»' --body "$BODY_ARC_002" --label 'type: bug,priority: critical,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-002\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-003 — Лимит карт в руке
echo "Создаю ARC-003..."
BODY_ARC_003=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Story · Приоритет: High · Оценка: 3 SP


**Описание:** По правилам Arcomage рука ограничена (документы говорят про 5 карт, артефакт «Книга Мудрости»
увеличивает до 6). Сейчас `PlayerData` не имеет поля лимита, а `draw_card()` в `match_manager.gd` добавляет карты
без ограничений.

**Технические детали:**
- Добавить `@export var max_hand_size: int = 5` в `data/resources/player_data.gd`.
- В `draw_card()` — если рука уже полна, не тянуть карту (карта остаётся в колоде) либо тянуть и сразу
  автоматически сбрасывать лишнюю — выбрать вариант, задокументировать в описании тикета после решения (по
  умолчанию: не тянуть, это ближе к оригинальным правилам Arcomage).

**Критерии приёмки:**
- [ ] Рука никогда не превышает `max_hand_size`.
- [ ] Юнит-тест на переполнение руки.
- [ ] UI не ломается при полной руке (карты не вылезают за пределы `HBoxContainer`).

---
_Перенесено из `dev_plan_tickets.md` (ARC-003)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-003: Лимит карт в руке' --body "$BODY_ARC_003" --label 'type: story,priority: high,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-003\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-004 — Разделить сигнал health_changed на явные события
echo "Создаю ARC-004..."
BODY_ARC_004=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Task · Приоритет: Medium · Оценка: 3 SP


**Описание:** Один сигнал `GameEvents.health_changed(player, amount)` используется и для урона (отрицательное
значение), и для строительства (положительное значение). Это уже создаёт путаницу в `_on_health_changed()`
(тряска экрана только при `amount < 0`) и заблокирует реализацию триггера «получен урон» для артефактов (ARC-030),
так как нет разделения «урон по стене» / «урон по башне» / «прирост».

**Технические детали:**
- Ввести `signal damage_applied(target, amount, hit_wall: bool)` и `signal value_built(target, amount, part: String)`.
- Обновить все точки вызова в `match_manager.gd`, `artifact_manager.gd`, `battle_screen.gd`.

**Критерии приёмки:**
- [ ] Старый `health_changed` удалён либо оставлен только как deprecated-обёртка.
- [ ] Тряска экрана и обновление UI по-прежнему работают.
- [ ] Существующие тесты (ARC-053) проходят.

---
_Перенесено из `dev_plan_tickets.md` (ARC-004)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-004: Разделить сигнал health_changed на явные события' --body "$BODY_ARC_004" --label 'type: task,priority: medium,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-004\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-005 — Аудит и унификация словаря target в эффектах
echo "Создаю ARC-005..."
BODY_ARC_005=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Task · Приоритет: Medium · Оценка: 2 SP


**Описание:** В разных `.tres`-файлах встречаются `"self"`, `"self_wall"`, `"self_tower"`, `"enemy"`,
`"enemy_wall"`. Фактически на поведение влияет только префикс `self`/`enemy` — суффикс `_wall`/`_tower` для типов
`damage`/`direct_damage` игнорируется (весь урон всё равно идёт через `apply_damage`). Нужно явно
задокументировать и/или реализовать разницу, иначе контент-авторы будут закладывать несуществующую механику.

**Критерии приёмки:**
- [ ] Написана функция `resolve_target(actor, enemy, target_str) -> PlayerData` в `match_manager.gd`.
- [ ] Обновлена документация эффектов (короткий `effects_reference.md`).
- [ ] Все существующие карты проверены на соответствие реальному поведению.

---
_Перенесено из `dev_plan_tickets.md` (ARC-005)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-005: Аудит и унификация словаря target в эффектах' --body "$BODY_ARC_005" --label 'type: task,priority: medium,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-005\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-006 — Настроить HTML5/Web export preset для Яндекс Игр
echo "Создаю ARC-006..."
BODY_ARC_006=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Task · Приоритет: Critical · Оценка: 5 SP


**Описание:** `export_presets.cfg` содержит единственный пресет `Windows Desktop` (сейчас экспортирует
`GTA_VI.exe`, судя по имени — тестовый/случайный экспорт). Пресета Web нет вообще, хотя вся игра целится в
Яндекс Игры (HTML5).

**Технические детали:**
- Добавить preset `platform="Web"`, `export_path="./web/index.html"`.
- Отключить Threads (`variant/thread_support=false`) — обязательное требование Яндекс Игр.
- Настроить `html/experimental_virtual_keyboard`, canvas resize policy под `stretch/mode=canvas_items`.
- Подготовить кастомный `index.html`/JS-обвязку с подключением Yandex Games SDK script (`https://yandex.ru/games/sdk/v2`).

**Критерии приёмки:**
- [x] Проект собирается в HTML5-бандл без ошибок.
- [x] Бандл открывается локально через `python -m http.server` и запускает главное меню.
- [x] Threads выключены, WASM грузится в браузере без SharedArrayBuffer.

> ✅ Реализовано и проверено: `export_path` пресета Web переведён на `./web/index.html` (было
> `./GTA_VI.html`, не совпадало с планом). `variant/thread_support=false`. `html/canvas_resize_policy`
> переведён с Adaptive(2) на Project(1) — сочетание Adaptive + `stretch/mode=canvas_items` даёт
> известный баг некорректного скейлинга в Godot 4 (см. issue godotengine/godot#70450). `html/head_include`
> подключает `https://yandex.ru/games/sdk/v2` и вызывает `YaGames.init()`, кладя результат в
> `window.ysdk` — то самое имя, которое уже ожидает `core/yandex_sdk.gd`. Экспорт собран и открыт
> через `python -m http.server` — главное меню запускается.

---
_Перенесено из `dev_plan_tickets.md` (ARC-006)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-006: Настроить HTML5/Web export preset для Яндекс Игр' --body "$BODY_ARC_006" --label 'type: task,priority: critical,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-006\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано и проверено: `export_path` пресета Web переведён на `./web/index.html` (было `./GTA_VI.html`, не совпадало с планом). `variant/thread_support=false`. `html/canvas_resize_policy` переведён с Adaptive(2) на Project(1) — сочетание Adaptive + `stretch/mode=canvas_items` даёт известный баг некорректного скейлинга в Godot 4 (см. issue godotengine/godot#70450). `html/head_include` подключает `https://yandex.ru/games/sdk/v2` и вызывает `YaGames.init()`, кладя результат в `window.ysdk` — то самое имя, которое уже ожидает `core/yandex_sdk.gd`. Экспорт собран и открыт через `python -m http.server` — главное меню запускается.'
echo "  -> $ISSUE_URL"

# ARC-007 — Убрать неиспользуемые фичи движка (3D-физика, лишние модули)
echo "Создаю ARC-007..."
BODY_ARC_007=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Task · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-006


**Описание:** `project.godot` включает `3d/physics_engine="Jolt Physics"` и тег фичи `"Forward Plus"` вместе с
`renderer/rendering_method="gl_compatibility"` — несогласованная конфигурация для чисто 2D-карточной игры,
раздувающая размер сборки (роадмап явно требует минимизировать WASM).

**Критерии приёмки:**
- [ ] 3D-физика отключена/не включена в экспорт.
- [ ] Feature tags согласованы с реальным рендерером.
- [ ] Итоговый размер `.wasm`/`.pck` замерен и задокументирован (baseline для будущих сравнений).

---
_Перенесено из `dev_plan_tickets.md` (ARC-007)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-007: Убрать неиспользуемые фичи движка (3D-физика, лишние модули)' --body "$BODY_ARC_007" --label 'type: task,priority: medium,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-007\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-008 — Убрать посторонние экспортированные бинарники из репозитория
echo "Создаю ARC-008..."
BODY_ARC_008=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Task · Приоритет: Low · Оценка: 1 SP


**Описание:** В корне проекта лежат `GTA_VI.exe` (~98 МБ), `GTA_VI.console.exe`, `GTA_VI.pck` — судя по всему,
случайный/тестовый экспорт с плейсхолдер-названием. Раздувает репозиторий и вводит в заблуждение.

**Критерии приёмки:**
- [ ] Файлы удалены из рабочей копии (или перемещены вне репозитория).
- [ ] `.gitignore` дополнен паттернами экспортных бинарников (`*.exe`, `*.pck`, `/web/`, `/build/`).

---
_Перенесено из `dev_plan_tickets.md` (ARC-008)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-008: Убрать посторонние экспортированные бинарники из репозитория' --body "$BODY_ARC_008" --label 'type: task,priority: low,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-008\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-078 — Баг: ход не возвращается игроку после хода ИИ
echo "Создаю ARC-078..."
BODY_ARC_078=$(cat <<'ARC_EOF'
**Эпик A — Критические баги и технический фундамент**

Тип: Bug · Приоритет: Critical · Оценка: 2 SP


**Описание:** В реальной игре (переход с карты мира в бой) матч навсегда зависал в состоянии `AI_TURN`
после первого хода игрока — противник не ходил и не возвращал ход. Причина: `world_map_screen.gd` и
`main_menu.gd` создают `enemy_data` через `PlayerData.new()`, не назначая `ai_strategy`.
`MatchManager.setup_match()` не подстраховывался, и `execute_ai_turn()` на пустой стратегии печатал
`[ERROR] AI Strategy not set!` и делал `return`, ни разу не вызвав `end_turn()`. Отдельно там же нашли
соседний баг того же класса: если рука ИИ пуста на момент хода, код печатал debug-сообщение и тоже
выходил без `end_turn()`.

**Технические детали:**
- `core/match_manager.gd` `setup_match()` — назначает `default_ai_strategy.gd` в `enemy_data.ai_strategy`,
  если она не задана (единая точка входа для всех боевых сценариев).
- `core/match_manager.gd` `execute_ai_turn()` — та же подстраховка на случай вызова в обход
  `setup_match()`; ветка с пустой рукой ИИ теперь тоже вызывает `end_turn()`.

**Критерии приёмки:**
- [x] После хода игрока ИИ либо играет карту, либо сбрасывает карту, либо (пустая рука) просто
      передаёт ход — во всех случаях состояние возвращается в `PLAYER_TURN`.
- [x] Тест на `setup_match()`, назначающий `ai_strategy` по умолчанию.
- [x] Тест на `execute_ai_turn()` с `ai_strategy == null`.
- [x] Тест на `execute_ai_turn()` с пустой рукой ИИ.

> ✅ Реализовано и проверено: `tests/test_match_manager.gd` — 3 новых теста в разделе `setup_match /
> execute_ai_turn`, все проходят. Проверено вживую в редакторе — ход корректно возвращается игроку
> после хода ИИ.

---
_Перенесено из `dev_plan_tickets.md` (ARC-078)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-078: Баг: ход не возвращается игроку после хода ИИ' --body "$BODY_ARC_078" --label 'type: bug,priority: critical,epic: A')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-078\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
gh issue close "$ISSUE_NUM" --repo "$REPO" --comment '✅ Реализовано и проверено: `tests/test_match_manager.gd` — 3 новых теста в разделе `setup_match / execute_ai_turn`, все проходят. Проверено вживую в редакторе — ход корректно возвращается игроку после хода ИИ.'
echo "  -> $ISSUE_URL"

# ARC-009 — Дизайн формата карты мира и типов узлов
echo "Создаю ARC-009..."
BODY_ARC_009=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: High · Оценка: 3 SP


**Описание:** `MapNodeData.NodeType` содержит `BATTLE, ELITE_BATTLE, SHOP, REST`, но в роадмапах упоминается ещё
и `EVENT` («случайные события») — его в enum нет. Нужно зафиксировать финальную схему уровней (сколько «этажей»,
сколько узлов на этаже, где стоит босс) до написания генератора.

**Критерии приёмки:**
- [ ] `NodeType` расширен до `BATTLE, ELITE_BATTLE, SHOP, REST, EVENT, BOSS`.
- [ ] Зафиксирован документ `docs/world_map_design.md`: количество этажей (рекомендация: 12–15), распределение
      типов узлов по вероятности, правило «на одном этаже 2–4 узла с ветвлением/схождением путей».
- [ ] `WorldMapData` расширен полями `floor_count`, `seed`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-009)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-009: Дизайн формата карты мира и типов узлов' --body "$BODY_ARC_009" --label 'type: story,priority: high,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-009\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-010 — Процедурный генератор путей карты
echo "Создаю ARC-010..."
BODY_ARC_010=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: High · Оценка: 8 SP
Зависит от: ARC-009


**Описание:** Заменить хардкод из `main_menu.gd._on_campaign_pressed()` (2 узла) на реальный алгоритм генерации
ветвящегося графа (по типу Slay the Spire): N этажей, случайное число узлов на этаж, случайные, но валидные
соединения (без пересечений «в обратную сторону»), гарантированный путь до босса.

**Критерии приёмки:**
- [ ] Генератор детерминирован по `seed` (для тестируемости).
- [ ] На каждом сгенерированном графе гарантированно существует путь от старта до `BOSS`.
- [ ] Юнит-тест генерирует 100 карт и проверяет валидность связности.

---
_Перенесено из `dev_plan_tickets.md` (ARC-010)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-010: Процедурный генератор путей карты' --body "$BODY_ARC_010" --label 'type: story,priority: high,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-010\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-011 — Ограничение доступных узлов и перемещение по карте
echo "Создаю ARC-011..."
BODY_ARC_011=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: High · Оценка: 3 SP
Зависит от: ARC-002, ARC-010


**Описание:** Сейчас в `world_map_screen.gd` кликабельны вообще все узлы карты. Нужно: кликабельны только узлы,
соединённые с `current_node_index` и ещё не пройденные; остальные — заблокированы визуально.

**Критерии приёмки:**
- [ ] Недоступные узлы задизейблены и визуально отличаются (тусклее/иконка замка).
- [ ] После победы в узле `current_node_index` обновляется, открываются следующие по графу узлы.

---
_Перенесено из `dev_plan_tickets.md` (ARC-011)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-011: Ограничение доступных узлов и перемещение по карте' --body "$BODY_ARC_011" --label 'type: story,priority: high,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-011\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-012 — Узел «Магазин» (Shop)
echo "Создаю ARC-012..."
BODY_ARC_012=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: Medium · Оценка: 5 SP
Зависит от: ARC-011, ARC-016


**Описание:** Реализация роадмапа 2.3/3.3 «Магазин карт и удаление ненужных карт из колоды». Нужна внутриигровая
валюта «Золото» на уровне забега (не путать с мета-валютой из Эпика F).

**Критерии приёмки:**
- [ ] Экран магазина показывает 3–5 карт на продажу и опцию «удалить карту из колоды» за золото.
- [ ] Золото списывается и сохраняется в `MatchSettings`/run-state.
- [ ] Покупка/удаление реально меняет колоду забега (см. ARC-016).

---
_Перенесено из `dev_plan_tickets.md` (ARC-012)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-012: Узел «Магазин» (Shop)' --body "$BODY_ARC_012" --label 'type: story,priority: medium,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-012\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-013 — Узел «Отдых» (Rest)
echo "Создаю ARC-013..."
BODY_ARC_013=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-011


**Описание:** Выбор одного из двух вариантов: восстановить стену/башню или улучшить генератор ресурса. Простая
логика без боя.

**Критерии приёмки:**
- [ ] Экран с 2 карточками-опциями, выбор применяет эффект к `player_data` забега и возвращает на карту.

---
_Перенесено из `dev_plan_tickets.md` (ARC-013)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-013: Узел «Отдых» (Rest)' --body "$BODY_ARC_013" --label 'type: story,priority: medium,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-013\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-014 — Узел «Событие» (Event)
echo "Создаю ARC-014..."
BODY_ARC_014=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: Medium · Оценка: 5 SP
Зависит от: ARC-009, ARC-011


**Описание:** Текстовые события со 2–3 вариантами выбора и последствиями (ресурсы/золото/карта/артефакт с
риском). Для MVP достаточно 5 уникальных событий.

**Критерии приёмки:**
- [ ] Данные события вынесены в `Resource` (`EventData.gd`) по аналогии с картами/артефактами.
- [ ] Минимум 5 событий реализовано и подключено к генератору карты.

---
_Перенесено из `dev_plan_tickets.md` (ARC-014)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-014: Узел «Событие» (Event)' --body "$BODY_ARC_014" --label 'type: story,priority: medium,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-014\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-015 — Экран награды после боя
echo "Создаю ARC-015..."
BODY_ARC_015=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-002, ARC-016


**Описание:** Роадмап 2.3/3.2: после победы в бою на карте — выбор 1 из 3 карт либо артефакт, прежде чем
вернуться на карту мира. Сейчас этого экрана нет вообще — после победы игрок либо перезапускает тестовый бой,
либо (после ARC-002) сразу видит карту без награды.

**Критерии приёмки:**
- [ ] Новая сцена `ui/reward/reward_screen.tscn` + `.gd`.
- [ ] Пул наград зависит от типа узла (обычный бой — 3 карты; элитный — карта редкости выше + шанс артефакта; босс — гарантированный артефакт).
- [ ] Выбранная карта добавляется в колоду забега (ARC-016), после чего — переход на карту мира.

---
_Перенесено из `dev_plan_tickets.md` (ARC-015)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-015: Экран награды после боя' --body "$BODY_ARC_015" --label 'type: story,priority: high,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-015\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-016 — Колода забега (Run Deck) как отдельная сущность
echo "Создаю ARC-016..."
BODY_ARC_016=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: Blocker (для Эпика B) · Оценка: 5 SP


**Описание:** Сейчас `MatchManager.deck` — это общий тестовый пул из 11 захардкоженных путей, который
дополняется случайными повторами до 20 карт (`_initialize_test_deck()`). Для роглик-цикла нужна персистентная
колода забега: стартовый набор + карты, добранные в наградах/магазине, которая передаётся между сценой карты и
сценой боя через `MatchSettings`.

**Технические детали:**
- Добавить `MatchSettings.run_deck: Array[CardData]`.
- `match_manager.setup_match()` должен принимать колоду извне вместо вызова `_initialize_test_deck()`, когда
  идёт забег (тестовый режим из главного меню оставить как fallback).

**Критерии приёмки:**
- [ ] Карта, полученная в награде/магазине, действительно доступна в следующем бою этого забега.
- [ ] Между боями внутри одного забега колода не сбрасывается.

---
_Перенесено из `dev_plan_tickets.md` (ARC-016)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-016: Колода забега (Run Deck) как отдельная сущность' --body "$BODY_ARC_016" --label 'type: story,priority: critical,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-016\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-017 — Узел-босс и завершение забега
echo "Создаю ARC-017..."
BODY_ARC_017=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Story · Приоритет: Medium · Оценка: 5 SP
Зависит от: ARC-010, ARC-015


**Описание:** Финальный узел карты — усиленный бой с уникальным ИИ/ставками. После победы/поражения — экран
итогов забега (пройденные этажи, собранные артефакты, заработанное золото/мета-валюта).

**Критерии приёмки:**
- [ ] Есть отдельный `BOSS`-узел с повышенными характеристиками противника.
- [ ] Экран итогов забега показывает статистику и ведёт в главное меню/мета-магазин.

---
_Перенесено из `dev_plan_tickets.md` (ARC-017)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-017: Узел-босс и завершение забега' --body "$BODY_ARC_017" --label 'type: story,priority: medium,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-017\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-018 — Автосохранение состояния текущего забега
echo "Создаю ARC-018..."
BODY_ARC_018=$(cat <<'ARC_EOF'
**Эпик B — Роглик-цикл: карта мира**

Тип: Task · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-010, ARC-016


**Описание:** Веб-вкладка браузера может быть закрыта/перезагружена в любой момент. Нужно периодически
сохранять состояние забега (карта, колода, золото, текущий узел) в `user://` (и позже — в Yandex Player Data,
см. ARC-040), чтобы «Продолжить» в главном меню (сейчас — заглушка, см. ARC-041) реально работало.

**Критерии приёмки:**
- [ ] Состояние забега сохраняется после каждого узла карты.
- [ ] При перезапуске игры кнопка «Продолжить» восстанавливает забег с того же места.

---
_Перенесено из `dev_plan_tickets.md` (ARC-018)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-018: Автосохранение состояния текущего забега' --body "$BODY_ARC_018" --label 'type: task,priority: medium,epic: B')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-018\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-019 — Аудит существующих 34 карт
echo "Создаю ARC-019..."
BODY_ARC_019=$(cat <<'ARC_EOF'
**Эпик C — Контент карт и баланс**

Тип: Task · Приоритет: High · Оценка: 3 SP


**Описание:** Сверить каждую `.tres` в `data/cards/` с описанием в `cards_list.md`: соответствует ли `type`
эффекта (`damage`/`direct_damage`) тексту описания («урон стене» vs «урон башне»), совпадает ли `cost` и
`value`. Обновить `cards_list.md`, добавив недокументированные `brick_11` и `gem_11`.

**Критерии приёмки:**
- [ ] Таблица расхождений «карта → найдено расхождение → исправлено».
- [ ] `cards_list.md` актуализирован под фактические 36 карт (34 контентных + wall/knight).

---
_Перенесено из `dev_plan_tickets.md` (ARC-019)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-019: Аудит существующих 34 карт' --body "$BODY_ARC_019" --label 'type: task,priority: high,epic: C')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-019\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-020 — Догенерировать контент до целевых 60+ карт
echo "Создаю ARC-020..."
BODY_ARC_020=$(cat <<'ARC_EOF'
**Эпик C — Контент карт и баланс**

Тип: Story · Приоритет: Medium · Оценка: 8 SP
Зависит от: ARC-019, ARC-021


**Описание:** Расширить пул карт вторым слоем контента: карты с добором карт («Ясновидение»), кражей ресурсов
(«Проклятие»), условными эффектами («Резервы»: если стена < 5 — построить 6) — ни одной такой карты пока нет в `.tres`.

**Критерии приёмки:**
- [ ] Минимум 25 новых карт, из них минимум по одной на каждый новый тип эффекта из ARC-021.
- [ ] Баланс дороже/сильнее карт растёт нелинейно по cost (см. ARC-023).

---
_Перенесено из `dev_plan_tickets.md` (ARC-020)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-020: Догенерировать контент до целевых 60+ карт' --body "$BODY_ARC_020" --label 'type: story,priority: medium,epic: C')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-020\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-021 — Расширить интерпретатор эффектов
echo "Создаю ARC-021..."
BODY_ARC_021=$(cat <<'ARC_EOF'
**Эпик C — Контент карт и баланс**

Тип: Story · Приоритет: High · Оценка: 5 SP


**Описание:** `apply_card_effects()` в `match_manager.gd` поддерживает только `damage`, `direct_damage`,
`build_wall`, `build_tower`, `mod_quarry/magic/dungeon`, `build`. Для карт вида «тянуть карту», «украсть
ресурсы врага», «условный эффект (если X < Y)» нужны новые типы: `draw_card`, `steal_resource`,
`conditional`.

**Критерии приёмки:**
- [ ] Добавлены обработчики `draw_card`, `steal_resource`, `conditional` (с вложенным под-эффектом).
- [ ] На каждый новый тип эффекта — юнит-тест в `tests/`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-021)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-021: Расширить интерпретатор эффектов' --body "$BODY_ARC_021" --label 'type: story,priority: high,epic: C')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-021\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-022 — Заглушки-иконки для карт
echo "Создаю ARC-022..."
BODY_ARC_022=$(cat <<'ARC_EOF'
**Эпик C — Контент карт и баланс**

Тип: Task · Приоритет: Low · Оценка: 2 SP


**Описание:** Поле `icon: Texture2D` в `CardData` не заполнено ни в одном проверенном `.tres`. Нужен временный
арт-пакет (хотя бы по 1 иконке на тип ресурса) для нормального вида в UI до прихода полноценного арта.

**Критерии приёмки:**
- [ ] Все карты имеют хотя бы плейсхолдер-иконку по типу ресурса.

---
_Перенесено из `dev_plan_tickets.md` (ARC-022)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-022: Заглушки-иконки для карт' --body "$BODY_ARC_022" --label 'type: task,priority: low,epic: C')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-022\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-023 — Балансировочный проход по стоимости/эффекту карт
echo "Создаю ARC-023..."
BODY_ARC_023=$(cat <<'ARC_EOF'
**Эпик C — Контент карт и баланс**

Тип: Task · Приоритет: Medium · Оценка: 5 SP
Зависит от: ARC-054


**Описание:** Использовать симулятор ИИ-против-ИИ (ARC-054) для сбора статистики: какие карты почти никогда не
разыгрываются (слишком дорогие/слабые), какие ломают баланс (побеждают почти всегда). Скорректировать `cost`/
`value`.

**Критерии приёмки:**
- [ ] Отчёт по winrate/usage rate каждой карты на выборке ≥500 симулированных боёв.
- [ ] Внесены и задокументированы правки баланса.

---
_Перенесено из `dev_plan_tickets.md` (ARC-023)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-023: Балансировочный проход по стоимости/эффекту карт' --body "$BODY_ARC_023" --label 'type: task,priority: medium,epic: C')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-023\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-024 — Синхронизация документации контента
echo "Создаю ARC-024..."
BODY_ARC_024=$(cat <<'ARC_EOF'
**Эпик C — Контент карт и баланс**

Тип: Task · Приоритет: Low · Оценка: 1 SP
Зависит от: ARC-019, ARC-020


**Описание:** После правок содержимого зафиксировать `cards_list.md` как единственный источник истины и
удалить/архивировать более не актуальные секции старых roadmap-файлов, дублирующие список карт.

---
_Перенесено из `dev_plan_tickets.md` (ARC-024)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-024: Синхронизация документации контента' --body "$BODY_ARC_024" --label 'type: task,priority: low,epic: C')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-024\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-025 — Профиль ИИ «Строитель»
echo "Создаю ARC-025..."
BODY_ARC_025=$(cat <<'ARC_EOF'
**Эпик D — Искусственный интеллект**

Тип: Story · Приоритет: Medium · Оценка: 3 SP


**Описание:** Должен существовать тип ИИ, приоритизирующий рост собственной башни через
кирпичи. Сейчас есть только `DefaultAIStrategy` (сбалансированный) и `AggressiveAIStrategy`. Создать
`builder_ai_strategy.gd extends ai_strategy.gd` с весами, смещёнными в сторону `build_tower`/`mod_quarry`.

**Критерии приёмки:**
- [ ] Новый файл стратегии со своей формулой приоритета.
- [ ] В тестовом бою «Строитель» реально быстрее отстраивает башню, чем разыгрывает атакующие карты.

---
_Перенесено из `dev_plan_tickets.md` (ARC-025)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-025: Профиль ИИ «Строитель»' --body "$BODY_ARC_025" --label 'type: story,priority: medium,epic: D')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-025\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-026 — Профиль ИИ «Маг / Экономист»
echo "Создаю ARC-026..."
BODY_ARC_026=$(cat <<'ARC_EOF'
**Эпик D — Искусственный интеллект**

Тип: Story · Приоритет: Medium · Оценка: 3 SP


**Описание:** Приоритет на манипуляции ресурсами и карты гемов, включая будущие эффекты кражи ресурсов
(ARC-021).

**Критерии приёмки:**
- [ ] Новый файл стратегии `economist_ai_strategy.gd`.
- [ ] Юнит/симуляционный тест показывает иное поведение относительно Default/Aggressive/Builder.

---
_Перенесено из `dev_plan_tickets.md` (ARC-026)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-026: Профиль ИИ «Маг / Экономист»' --body "$BODY_ARC_026" --label 'type: story,priority: medium,epic: D')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-026\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-027 — Привязка профиля ИИ к типу узла карты
echo "Создаю ARC-027..."
BODY_ARC_027=$(cat <<'ARC_EOF'
**Эпик D — Искусственный интеллект**

Тип: Story · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-010, ARC-025, ARC-026


**Описание:** Обычные бои — случайный/сбалансированный профиль; элитные — усиленная версия (Aggressive/Builder)
с бонусом к стартовым характеристикам; босс — отдельная скриптованная гибридная стратегия.

**Критерии приёмки:**
- [ ] Тип узла определяет, какой `ai_strategy` и с какими стартовыми бонусами получает противник.

---
_Перенесено из `dev_plan_tickets.md` (ARC-027)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-027: Привязка профиля ИИ к типу узла карты' --body "$BODY_ARC_027" --label 'type: story,priority: medium,epic: D')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-027\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-028 — Форсированный сброс карты у игрока в патовой ситуации
echo "Создаю ARC-028..."
BODY_ARC_028=$(cat <<'ARC_EOF'
**Эпик D — Искусственный интеллект**

Тип: Bug/Story · Приоритет: Medium · Оценка: 2 SP


**Описание:** Для ИИ авто-сброс при невозможности сыграть карту уже реализован (`execute_ai_turn`), но для
игрока аналогичной подсказки/защиты от «зависания хода» нет — если у игрока в руке нет ни одной играбельной
карты, интерфейс не подсказывает, что нужно сбросить карту правой кнопкой.

**Критерии приёмки:**
- [ ] Если ни одна карта в руке не может быть сыграна, UI показывает подсказку «Нет доступных карт — сбросьте
      одну» (текст `status_label` или тултип).

---
_Перенесено из `dev_plan_tickets.md` (ARC-028)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-028: Форсированный сброс карты у игрока в патовой ситуации' --body "$BODY_ARC_028" --label 'type: bug,priority: medium,epic: D')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-028\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-029 — Масштабирование сложности по этажам карты
echo "Создаю ARC-029..."
BODY_ARC_029=$(cat <<'ARC_EOF'
**Эпик D — Искусственный интеллект**

Тип: Story · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-010


**Описание:** Противники на дальних этажах карты должны быть сильнее (больше стартового HP/генераторов) —
сейчас `PlayerData.new()` всегда создаёт врага с базовыми характеристиками независимо от прогресса.

**Критерии приёмки:**
- [ ] Формула роста сложности от `floor_index` задокументирована и подключена при создании `enemy_data`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-029)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-029: Масштабирование сложности по этажам карты' --body "$BODY_ARC_029" --label 'type: story,priority: medium,epic: D')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-029\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-030 — Триггер on_damage_taken в системе артефактов
echo "Создаю ARC-030..."
BODY_ARC_030=$(cat <<'ARC_EOF'
**Эпик E — Артефакты**

Тип: Task · Приоритет: High · Оценка: 3 SP
Зависит от: ARC-004


**Описание:** `artifact_manager.gd` сейчас реагирует только на `card_played` и `turn_started`. Для «Шипастой
Стены» (урон в ответ при попадании по стене) и подобных артефактов нужен триггер на входящий урон.

**Критерии приёмки:**
- [ ] `ArtifactManager` подписан на новый сигнал урона (после ARC-004) и вызывает эффекты с `trigger = "on_damage_taken"`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-030)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-030: Триггер on_damage_taken в системе артефактов' --body "$BODY_ARC_030" --label 'type: task,priority: high,epic: E')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-030\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-031 — Артефакт «Шипастая Стена»
echo "Создаю ARC-031..."
BODY_ARC_031=$(cat <<'ARC_EOF'
**Эпик E — Артефакты**

Тип: Story · Приоритет: Medium · Оценка: 2 SP
Зависит от: ARC-030


**Критерии приёмки:**
- [ ] При ударе по стене владельца артефакта атакующий получает 2 урона.

---
_Перенесено из `dev_plan_tickets.md` (ARC-031)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-031: Артефакт «Шипастая Стена»' --body "$BODY_ARC_031" --label 'type: story,priority: medium,epic: E')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-031\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-032 — Артефакт «Сфера Маны»
echo "Создаю ARC-032..."
BODY_ARC_032=$(cat <<'ARC_EOF'
**Эпик E — Артефакты**

Тип: Story · Приоритет: Medium · Оценка: 2 SP


**Описание:** Возврат 1 ед. ресурса при розыгрыше карты типа Гемы. Нужен фильтр по типу разыгранной карты в
триггере `card_played`.

**Критерии приёмки:**
- [ ] При розыгрыше карты-гема владелец получает +1 гем сверх обычного дохода.

---
_Перенесено из `dev_plan_tickets.md` (ARC-032)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-032: Артефакт «Сфера Маны»' --body "$BODY_ARC_032" --label 'type: story,priority: medium,epic: E')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-032\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-033 — Артефакт «Рог Изобилия»
echo "Создаю ARC-033..."
BODY_ARC_033=$(cat <<'ARC_EOF'
**Эпик E — Артефакты**

Тип: Story · Приоритет: Medium · Оценка: 2 SP


**Описание:** Все генераторы владельца становятся уровня 2 в начале боя. Нужен новый триггер `match_started`
(сейчас отсутствует в `ArtifactManager` — там нет подписки на `GameEvents.match_started`).

**Критерии приёмки:**
- [ ] `ArtifactManager` подписывается на `match_started` и применяет эффект один раз в начале боя.

---
_Перенесено из `dev_plan_tickets.md` (ARC-033)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-033: Артефакт «Рог Изобилия»' --body "$BODY_ARC_033" --label 'type: story,priority: medium,epic: E')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-033\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-034 — Артефакт «Книга Мудрости»
echo "Создаю ARC-034..."
BODY_ARC_034=$(cat <<'ARC_EOF'
**Эпик E — Артефакты**

Тип: Story · Приоритет: Medium · Оценка: 1 SP
Зависит от: ARC-003


**Критерии приёмки:**
- [ ] Владелец артефакта имеет `max_hand_size = 6` вместо 5.

---
_Перенесено из `dev_plan_tickets.md` (ARC-034)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-034: Артефакт «Книга Мудрости»' --body "$BODY_ARC_034" --label 'type: story,priority: medium,epic: E')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-034\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-035 — Артефакт «Счастливая Монета»
echo "Создаю ARC-035..."
BODY_ARC_035=$(cat <<'ARC_EOF'
**Эпик E — Артефакты**

Тип: Story · Приоритет: Medium · Оценка: 3 SP


**Описание:** 10% шанс не тратить ресурсы при розыгрыше карты. Это требует хука **до** списания стоимости в
`play_card_by_index()` (сейчас все триггеры артефактов срабатывают уже после розыгрыша) — нужен новый механизм
`pre_play_hooks`, который может отменить списание.

**Критерии приёмки:**
- [ ] Добавлен pre-play хук в `match_manager.play_card_by_index()`.
- [ ] С вероятностью 10% ресурсы не списываются (проверяется тестом с фиксированным seed рандома).

---
_Перенесено из `dev_plan_tickets.md` (ARC-035)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-035: Артефакт «Счастливая Монета»' --body "$BODY_ARC_035" --label 'type: story,priority: medium,epic: E')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-035\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-036 — Редизайн ProfileManager: постоянная валюта и статистика
echo "Создаю ARC-036..."
BODY_ARC_036=$(cat <<'ARC_EOF'
**Эпик F — Мета-прогрессия и профиль игрока**

Тип: Story · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-001


**Описание:** Текущий `profile_manager.gd` хранит только `total_wins`, `unlocked_artifacts` и два бонуса
статов. Нужно ввести валюту «Золото/Эссенция» (постоянная, отдельно от золота забега из ARC-012) и структуру
для будущего дерева прокачки.

**Критерии приёмки:**
- [ ] `profile.currency`, `profile.upgrades: Dictionary` добавлены и сохраняются/загружаются корректно.

---
_Перенесено из `dev_plan_tickets.md` (ARC-036)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-036: Редизайн ProfileManager: постоянная валюта и статистика' --body "$BODY_ARC_036" --label 'type: story,priority: high,epic: F')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-036\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-037 — Экран мета-магазина / дерева прокачки
echo "Создаю ARC-037..."
BODY_ARC_037=$(cat <<'ARC_EOF'
**Эпик F — Мета-прогрессия и профиль игрока**

Тип: Story · Приоритет: High · Оценка: 8 SP
Зависит от: ARC-036


**Описание:** UI, где игрок тратит постоянную валюту на: старт. бонус к стене/башне, разблокировку карт в пул
наград, усиление эффектов определённого типа ресурса («мастерство»).

**Критерии приёмки:**
- [ ] Минимум 6 покупаемых улучшений, реально влияющих на `setup_match()`/пул наград.
- [ ] UI показывает текущий баланс и стоимость следующего уровня улучшения.

---
_Перенесено из `dev_plan_tickets.md` (ARC-037)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-037: Экран мета-магазина / дерева прокачки' --body "$BODY_ARC_037" --label 'type: story,priority: high,epic: F')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-037\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-038 — Система разблокировки карт и стартовых колод
echo "Создаю ARC-038..."
BODY_ARC_038=$(cat <<'ARC_EOF'
**Эпик F — Мета-прогрессия и профиль игрока**

Тип: Story · Приоритет: Medium · Оценка: 5 SP
Зависит от: ARC-020, ARC-037


**Описание:** Разделить понятия «карта существует в игре» и «карта доступна игроку» — сильные карты должны
быть заблокированы до разблокировки за мета-валюту.

**Критерии приёмки:**
- [ ] Пул карт наград (ARC-015) фильтруется по `profile.unlocked_cards`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-038)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-038: Система разблокировки карт и стартовых колод' --body "$BODY_ARC_038" --label 'type: story,priority: medium,epic: F')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-038\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-039 — Достижения и статистика профиля
echo "Создаю ARC-039..."
BODY_ARC_039=$(cat <<'ARC_EOF'
**Эпик F — Мета-прогрессия и профиль игрока**

Тип: Story · Приоритет: Low · Оценка: 3 SP


**Критерии приёмки:**
- [ ] Экран статистики: побед, максимальная высота башни, число забегов, открытые карты/артефакты.

---
_Перенесено из `dev_plan_tickets.md` (ARC-039)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-039: Достижения и статистика профиля' --body "$BODY_ARC_039" --label 'type: story,priority: low,epic: F')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-039\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-040 — Сохранение профиля в Yandex Player Data
echo "Создаю ARC-040..."
BODY_ARC_040=$(cat <<'ARC_EOF'
**Эпик F — Мета-прогрессия и профиль игрока**

Тип: Story · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-036, ARC-047


**Описание:** Сейчас `save_profile()`/`load_profile()` пишут только в `user://savegame.json` — на вебе это
локально для браузера/устройства и теряется при смене устройства. Нужна интеграция с
`ysdk.player.setData()`/`getData()` с фоллбеком на локальный файл (если SDK недоступен/оффлайн).

**Критерии приёмки:**
- [ ] Профиль сохраняется в облако Яндекса при наличии SDK.
- [ ] При отсутствии SDK (локальная разработка) fallback на файл работает как раньше.

---
_Перенесено из `dev_plan_tickets.md` (ARC-040)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-040: Сохранение профиля в Yandex Player Data' --body "$BODY_ARC_040" --label 'type: story,priority: high,epic: F')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-040\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-041 — Реальная логика главного меню
echo "Создаю ARC-041..."
BODY_ARC_041=$(cat <<'ARC_EOF'
**Эпик G — UI/UX и меню**

Тип: Story · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-018, ARC-046


**Описание:** `main_menu.gd._on_continue_pressed()` и `_on_deck_pressed()` — заглушки с `print(...)`. «Продолжить»
должен поднимать сохранённый забег (ARC-018), «Колода» — открывать просмотр текущей колоды/коллекции карт.

**Критерии приёмки:**
- [ ] «Продолжить» неактивна/скрыта, если нет сохранённого забега; иначе восстанавливает его.
- [ ] «Колода» открывает реальный экран (см. ARC-046).

---
_Перенесено из `dev_plan_tickets.md` (ARC-041)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-041: Реальная логика главного меню' --body "$BODY_ARC_041" --label 'type: story,priority: high,epic: G')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-041\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-042 — Экран настроек
echo "Создаю ARC-042..."
BODY_ARC_042=$(cat <<'ARC_EOF'
**Эпик G — UI/UX и меню**

Тип: Story · Приоритет: Medium · Оценка: 3 SP


**Критерии приёмки:**
- [ ] Регулировка громкости, (опционально) выбор языка, применяется и сохраняется между сессиями.

---
_Перенесено из `dev_plan_tickets.md` (ARC-042)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-042: Экран настроек' --body "$BODY_ARC_042" --label 'type: story,priority: medium,epic: G')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-042\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-043 — Пауза при потере фокуса вкладки/окна
echo "Создаю ARC-043..."
BODY_ARC_043=$(cat <<'ARC_EOF'
**Эпик G — UI/UX и меню**

Тип: Task · Приоритет: Medium · Оценка: 2 SP


**Описание:** Явное требование роадмапа 5.2 для веб-платформы — при уходе со вкладки браузера игра должна
ставиться на паузу (обработка `NOTIFICATION_APPLICATION_FOCUS_OUT`/`_OUT` и таймеров ИИ-хода, чтобы бой не
«убегал» без игрока).

**Критерии приёмки:**
- [ ] При потере фокуса `get_tree().paused = true`, таймер `execute_ai_turn()` корректно возобновляется после
      возврата фокуса.

---
_Перенесено из `dev_plan_tickets.md` (ARC-043)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-043: Пауза при потере фокуса вкладки/окна' --body "$BODY_ARC_043" --label 'type: task,priority: medium,epic: G')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-043\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-044 — Адаптация UI под мобильные разрешения
echo "Создаю ARC-044..."
BODY_ARC_044=$(cat <<'ARC_EOF'
**Эпик G — UI/UX и меню**

Тип: Story · Приоритет: Medium · Оценка: 5 SP


**Описание:** Значительная доля трафика Яндекс Игр — мобильные браузеры. Текущий `stretch/mode="canvas_items"`
настроен, но не протестирован на узких/высоких соотношениях сторон; размеры карт/кнопок рассчитаны на
десктопный клик мышью.

**Критерии приёмки:**
- [ ] Проверено на минимум 3 соотношениях сторон (16:9, 9:16, 4:3).
- [ ] Карты и кнопки достаточно велики для тач-инпута (рекомендация ≥ 44×44 пикселя логического размера).

---
_Перенесено из `dev_plan_tickets.md` (ARC-044)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-044: Адаптация UI под мобильные разрешения' --body "$BODY_ARC_044" --label 'type: story,priority: medium,epic: G')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-044\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-045 — Полировка визуальных эффектов
echo "Создаю ARC-045..."
BODY_ARC_045=$(cat <<'ARC_EOF'
**Эпик G — UI/UX и меню**

Тип: Story · Приоритет: Low · Оценка: 5 SP


**Описание:** Роадмап 5.1: частицы разрушения камня, эффекты заклинаний, более выразительная анимация роста
башен (сейчас — простые прогресс-бары и `Panel`-блоки).

**Критерии приёмки:**
- [ ] Добавлены минимум 3 вида партиклов (урон/строительство/победа) через `GPUParticles2D`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-045)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-045: Полировка визуальных эффектов' --body "$BODY_ARC_045" --label 'type: story,priority: low,epic: G')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-045\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-046 — Единый экран профиля/колоды в UI-флоу
echo "Создаю ARC-046..."
BODY_ARC_046=$(cat <<'ARC_EOF'
**Эпик G — UI/UX и меню**

Тип: Task · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-038


**Критерии приёмки:**
- [ ] Экран показывает открытые карты/артефакты и позволяет посмотреть (не редактировать в MVP) состав текущей
      стартовой колоды.

---
_Перенесено из `dev_plan_tickets.md` (ARC-046)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-046: Единый экран профиля/колоды в UI-флоу' --body "$BODY_ARC_046" --label 'type: task,priority: medium,epic: G')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-046\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-047 — Полная инициализация Yandex SDK
echo "Создаю ARC-047..."
BODY_ARC_047=$(cat <<'ARC_EOF'
**Эпик H — Yandex Games SDK и монетизация**

Тип: Story · Приоритет: Critical · Оценка: 5 SP
Зависит от: ARC-006


**Описание:** Текущий `yandex_sdk.gd` — заглушка, которая просто проверяет наличие `window.ysdk` синхронно в
`_ready()`. Реальная интеграция требует асинхронной инициализации через `YaGames.init()`, вызова
`ysdk.features.LoadingAPI.ready()` после загрузки первого экрана, определения языка/окружения.

**Критерии приёмки:**
- [ ] SDK инициализируется асинхронно, игра корректно сигнализирует Яндексу об окончании загрузки.
- [ ] Локальный запуск (без реального SDK) продолжает работать в режиме заглушки — как сейчас.

---
_Перенесено из `dev_plan_tickets.md` (ARC-047)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-047: Полная инициализация Yandex SDK' --body "$BODY_ARC_047" --label 'type: story,priority: critical,epic: H')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-047\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-048 — Rewarded Video в геймплейных хуках
echo "Создаю ARC-048..."
BODY_ARC_048=$(cat <<'ARC_EOF'
**Эпик H — Yandex Games SDK и монетизация**

Тип: Story · Приоритет: High · Оценка: 5 SP
Зависит от: ARC-047, ARC-036


**Описание:** Реализовать 3 точки интеграции: «второе дыхание» при поражении,
удвоение золота забега после победы, бесплатный артефакт в магазине.

**Критерии приёмки:**
- [ ] Каждый из 3 сценариев вызывает `show_rewarded_video()` и корректно обрабатывает `onRewarded`/`onClose`/`onError`.

---
_Перенесено из `dev_plan_tickets.md` (ARC-048)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-048: Rewarded Video в геймплейных хуках' --body "$BODY_ARC_048" --label 'type: story,priority: high,epic: H')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-048\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-049 — Interstitial реклама между боями
echo "Создаю ARC-049..."
BODY_ARC_049=$(cat <<'ARC_EOF'
**Эпик H — Yandex Games SDK и монетизация**

Тип: Story · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-047


**Критерии приёмки:**
- [ ] Реклама показывается не чаще 1 раза в 2–3 минуты игрового времени (таймер-ограничитель).

---
_Перенесено из `dev_plan_tickets.md` (ARC-049)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-049: Interstitial реклама между боями' --body "$BODY_ARC_049" --label 'type: story,priority: medium,epic: H')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-049\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-050 — Sticky banner в меню/на карте
echo "Создаю ARC-050..."
BODY_ARC_050=$(cat <<'ARC_EOF'
**Эпик H — Yandex Games SDK и монетизация**

Тип: Task · Приоритет: Low · Оценка: 1 SP
Зависит от: ARC-047


---
_Перенесено из `dev_plan_tickets.md` (ARC-050)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-050: Sticky banner в меню/на карте' --body "$BODY_ARC_050" --label 'type: task,priority: low,epic: H')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-050\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-051 — IAP через Yandex Games Payments
echo "Создаю ARC-051..."
BODY_ARC_051=$(cat <<'ARC_EOF'
**Эпик H — Yandex Games SDK и монетизация**

Тип: Story · Приоритет: Medium · Оценка: 5 SP
Зависит от: ARC-047, ARC-036


**Описание:** Наборы мета-валюты, Starter Pack (артефакт + золото + отключение обязательной рекламы),
косметические облики (можно вынести в отдельный тикет по мере готовности арта).

**Критерии приёмки:**
- [ ] Минимум 2 покупаемых лота работают через `ysdk.payments`.
- [ ] Отключение рекламы реально скрывает interstitial (ARC-049).

---
_Перенесено из `dev_plan_tickets.md` (ARC-051)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-051: IAP через Yandex Games Payments' --body "$BODY_ARC_051" --label 'type: story,priority: medium,epic: H')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-051\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-052 — Верификация офлайн-режима SDK после всех правок
echo "Создаю ARC-052..."
BODY_ARC_052=$(cat <<'ARC_EOF'
**Эпик H — Yandex Games SDK и монетизация**

Тип: Task · Приоритет: Low · Оценка: 1 SP
Зависит от: ARC-047–ARC-051


**Критерии приёмки:**
- [ ] Локальная разработка без реального Yandex-окружения не падает и не блокирует ни один экран.

---
_Перенесено из `dev_plan_tickets.md` (ARC-052)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-052: Верификация офлайн-режима SDK после всех правок' --body "$BODY_ARC_052" --label 'type: task,priority: low,epic: H')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-052\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-053 — Расширить unit-тесты
echo "Создаю ARC-053..."
BODY_ARC_053=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Story · Приоритет: High · Оценка: 5 SP (растёт по мере добавления фич)


**Описание:** Сейчас `tests/test_runner.gd` содержит один тест (`test_apply_damage`), запускаемый вручную при
дебаг-запуске главного меню. Нужно покрыть: лимит руки, разблокировку/пат ИИ, каждый новый тип эффекта карт,
применение бонусов мета-прогрессии, работу артефактов.

**Критерии приёмки:**
- [ ] Покрытие ключевых систем растёт вместе с каждым эпиком (добавлять тест в тот же PR, что и фичу).

---
_Перенесено из `dev_plan_tickets.md` (ARC-053)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-053: Расширить unit-тесты' --body "$BODY_ARC_053" --label 'type: story,priority: high,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-053\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-054 — Симулятор «ИИ против ИИ» для баланса
echo "Создаю ARC-054..."
BODY_ARC_054=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Story · Приоритет: High · Оценка: 8 SP
Зависит от: ARC-025, ARC-026


**Описание:** Прямое требование матрицы рисков («Автоматические тесты боя ИИ против
ИИ для сбора статистики»), которое пока не реализовано. Запуск сотен автобоёв в headless-режиме
(`godot --headless`) с логированием победителя, длительности, использованных карт.

**Критерии приёмки:**
- [ ] Скрипт прогоняет N боёв между произвольными комбинациями стратегий и пишет CSV/JSON отчёт.
- [ ] Отчёт используется в ARC-023 для баланса карт.

---
_Перенесено из `dev_plan_tickets.md` (ARC-054)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-054: Симулятор «ИИ против ИИ» для баланса' --body "$BODY_ARC_054" --label 'type: story,priority: high,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-054\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-055 — Настроить CI
echo "Создаю ARC-055..."
BODY_ARC_055=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Task · Приоритет: Medium · Оценка: 3 SP
Зависит от: ARC-053


**Критерии приёмки:**
- [ ] При каждом push/PR автоматически прогоняются unit-тесты в headless Godot.

> Детализировано и расширено в Эпике J (ARC-066 и далее) — там же вопросы репозитория и автосборки.

---
_Перенесено из `dev_plan_tickets.md` (ARC-055)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-055: Настроить CI' --body "$BODY_ARC_055" --label 'type: task,priority: medium,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-055\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-056 — Полный плейтест забега «от старта до босса»
echo "Создаю ARC-056..."
BODY_ARC_056=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Task · Приоритет: High · Оценка: 3 SP
Зависит от: Эпики B, E, F


**Критерии приёмки:**
- [ ] Хотя бы 3 независимых полных прохождения без критических багов/софтлоков.

---
_Перенесено из `dev_plan_tickets.md` (ARC-056)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-056: Полный плейтест забега «от старта до босса»' --body "$BODY_ARC_056" --label 'type: task,priority: high,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-056\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-057 — Подготовка ассетов для каталога Яндекс Игр
echo "Создаю ARC-057..."
BODY_ARC_057=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Task · Приоритет: Medium · Оценка: 3 SP


**Критерии приёмки:**
- [ ] Иконка, баннер, минимум 3 скриншота, короткое и длинное описание игры готовы.

---
_Перенесено из `dev_plan_tickets.md` (ARC-057)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-057: Подготовка ассетов для каталога Яндекс Игр' --body "$BODY_ARC_057" --label 'type: task,priority: medium,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-057\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-058 — Прохождение модерации Яндекс Игр
echo "Создаю ARC-058..."
BODY_ARC_058=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Task · Приоритет: Critical · Оценка: 3 SP (+ время ожидания ревью)
Зависит от: ARC-006, ARC-047, ARC-057


**Критерии приёмки:**
- [ ] Игра принята модерацией либо получен конкретный список правок для повторной подачи.

---
_Перенесено из `dev_plan_tickets.md` (ARC-058)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-058: Прохождение модерации Яндекс Игр' --body "$BODY_ARC_058" --label 'type: task,priority: critical,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-058\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

# ARC-059 — Пострелизный мониторинг
echo "Создаю ARC-059..."
BODY_ARC_059=$(cat <<'ARC_EOF'
**Эпик I — QA, автотесты, релиз**

Тип: Task · Приоритет: Low · Оценка: 2 SP


**Критерии приёмки:**
- [ ] Базовая аналитика через `ysdk` (события старта забега, победы/поражения) подключена.

---
_Перенесено из `dev_plan_tickets.md` (ARC-059)._
ARC_EOF
)
ISSUE_URL=$(gh issue create --repo "$REPO" --title 'ARC-059: Пострелизный мониторинг' --body "$BODY_ARC_059" --label 'type: task,priority: low,epic: I')
ISSUE_NUM=$(basename "$ISSUE_URL")
echo -e "ARC-059\t$ISSUE_NUM\t$ISSUE_URL" >> "$MAP_FILE"
echo "  -> $ISSUE_URL"

echo "Готово. Соответствие ID <-> issue сохранено в $MAP_FILE"
