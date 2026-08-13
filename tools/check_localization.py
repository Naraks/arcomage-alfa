#!/usr/bin/env python3
"""Проверка ключей локализации (ARC: локализация проекта).

Сравнивает ключи, реально используемые в коде (ui/*.gd, entities/*.gd,
core/*.gd) и в игровых ресурсах (data/cards/*.tres, data/artifacts/*.tres,
data/events/*.tres), с ключами, объявленными в localization/ru.po и
localization/en.po.

Не требует Godot — только stdlib Python 3, как tools/coverage_report.py.
Используется в CI (см. .github/workflows/ci.yml, джоб localization-check) и
может запускаться локально: `python3 tools/check_localization.py`.

Проверяет:
  * "missing" — ключ используется в коде/данных, но отсутствует в ru.po
    и/или en.po (ошибка, ломает CI);
  * "unused"  — ключ объявлен в ru.po, но не встречается ни в одном
    известном месте использования (предупреждение уровня ошибки, но с
    более мягкой формулировкой — см. --allow-unused).

Ограничение: используется эвристика по regex, а не разбор AST/Godot-ресурсов,
поэтому ключ, собранный в рантайме через конкатенацию строк, не будет
считаться "использованным". Известные статические места использования
(константы-словари, tr("KEY"), поля .tres) этой эвристикой покрываются.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

CODE_GLOBS = ["ui/**/*.gd", "entities/**/*.gd", "core/**/*.gd"]
DATA_GLOBS = ["data/cards/**/*.tres", "data/artifacts/**/*.tres", "data/events/**/*.tres"]

# Ключи локализации всегда UPPER_SNAKE_CASE с одним из этих префиксов —
# см. соглашение об именовании в docs/localization_guide.md.
KEY_PREFIXES = (
    "UI_",
    "COMMON_",
    "MSG_",
    "UPGRADE_",
    "CARD_",
    "ARTIFACT_",
    "EVENT_",
)
KEY_RE = re.compile(r'"([A-Z][A-Z0-9_]*)"')

# Ключи, которые используются только как тестовые/сентинельные значения (не
# реальные записи локализации) — исключаются из проверки "missing".
KNOWN_NON_LOCALIZATION_SENTINELS = {
    "EVENT_UNKNOWN_TITLE",  # tests/test_event_screen.gd: заведомо отсутствующий ключ
}


def is_localization_key(token: str) -> bool:
    return token.startswith(KEY_PREFIXES) and len(token) > len(
        next(p for p in KEY_PREFIXES if token.startswith(p))
    )


def collect_used_keys() -> set[str]:
    used: set[str] = set()
    for pattern in CODE_GLOBS + DATA_GLOBS:
        for path in REPO_ROOT.glob(pattern):
            text = path.read_text(encoding="utf-8")
            for match in KEY_RE.finditer(text):
                token = match.group(1)
                if is_localization_key(token):
                    used.add(token)
    return used


def parse_po_keys(po_path: Path) -> set[str]:
    if not po_path.exists():
        return set()
    keys: set[str] = set()
    text = po_path.read_text(encoding="utf-8")
    for match in re.finditer(r'^msgid "((?:[^"\\]|\\.)*)"', text, re.MULTILINE):
        msgid = match.group(1)
        if msgid and is_localization_key(msgid):
            keys.add(msgid)
    return keys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--allow-unused",
        action="store_true",
        help="Не завершать с ошибкой из-за неиспользуемых ключей (только missing).",
    )
    args = parser.parse_args()

    ru_po = REPO_ROOT / "localization" / "ru.po"
    en_po = REPO_ROOT / "localization" / "en.po"

    used_keys = collect_used_keys()
    ru_keys = parse_po_keys(ru_po)
    en_keys = parse_po_keys(en_po)

    missing_ru = (used_keys - ru_keys) - KNOWN_NON_LOCALIZATION_SENTINELS
    missing_en = (used_keys - en_keys) - KNOWN_NON_LOCALIZATION_SENTINELS
    unused = (ru_keys | en_keys) - used_keys

    exit_code = 0

    if missing_ru:
        exit_code = 1
        print(f"ОШИБКА: {len(missing_ru)} ключ(ей) используются в коде/данных, но отсутствуют в localization/ru.po:")
        for key in sorted(missing_ru):
            print(f"  - {key}")

    if missing_en:
        exit_code = 1
        print(f"ОШИБКА: {len(missing_en)} ключ(ей) используются в коде/данных, но отсутствуют в localization/en.po:")
        for key in sorted(missing_en):
            print(f"  - {key}")

    if unused:
        if not args.allow_unused:
            exit_code = 1
        prefix = "ОШИБКА" if not args.allow_unused else "Предупреждение"
        print(f"{prefix}: {len(unused)} ключ(ей) объявлены в .po, но не найдены в местах использования:")
        for key in sorted(unused):
            print(f"  - {key}")

    print(f"\nВсего использовано ключей: {len(used_keys)}; в ru.po: {len(ru_keys)}; в en.po: {len(en_keys)}.")
    if exit_code == 0:
        print("OK: несоответствий не найдено.")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
