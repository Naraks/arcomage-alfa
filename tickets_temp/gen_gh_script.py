#!/usr/bin/env python3
"""Generate a bash script that recreates dev_plan_tickets.md as GitHub Issues via gh CLI."""
import json
import re

with open("tickets.json", encoding="utf-8") as f:
    tickets = json.load(f)

REPO = "Naraks/arcomage-alfa"

TYPE_LABEL = {
    "Task": "type: task",
    "Story": "type: story",
    "Bug": "type: bug",
    "Bug/Story": "type: bug",
}

PRIO_LABEL = {
    "Critical": "priority: critical",
    "Blocker": "priority: critical",
    "Blocker (для Эпика B)": "priority: critical",
    "High": "priority: high",
    "Medium": "priority: medium",
    "Low": "priority: low",
}

EPIC_NAME = {
    "J": "Репозиторий, CI/CD и автоматизация тестирования",
    "A": "Критические баги и технический фундамент",
    "B": "Роглик-цикл: карта мира",
    "C": "Контент карт и баланс",
    "D": "Искусственный интеллект",
    "E": "Артефакты",
    "F": "Мета-прогрессия и профиль игрока",
    "G": "UI/UX и меню",
    "H": "Yandex Games SDK и монетизация",
    "I": "QA, автотесты, релиз",
}


def esc_sq(s: str) -> str:
    """Escape a string for embedding inside a single-quoted bash string."""
    return s.replace("'", "'\\''")


def type_label(t):
    return TYPE_LABEL.get(t, "type: task")


def prio_label(p):
    return PRIO_LABEL.get(p, "priority: medium")


def clean_title(title: str) -> str:
    return title.replace("`", "")


all_labels = set()
for t in tickets:
    all_labels.add(type_label(t["type"]))
    all_labels.add(prio_label(t["priority"]))
    all_labels.add(f"epic: {t['epic']}")
LABEL_COLORS = {
    "type: task": "1d76db",
    "type: story": "0e8a16",
    "type: bug": "d73a4a",
    "priority: critical": "b60205",
    "priority: high": "d93f0b",
    "priority: medium": "fbca04",
    "priority: low": "c2e0c6",
}

out = []
out.append("#!/usr/bin/env bash")
out.append("# Автоматически сгенерировано из dev_plan_tickets.md — переносит весь бэклог")
out.append("# (78 тикетов, ARC-001..ARC-078) в GitHub Issues репозитория " + REPO + ".")
out.append("#")
out.append("# Требования: `gh` CLI, авторизованный (`gh auth login`), с доступом к репозиторию.")
out.append("# Идемпотентность НЕ гарантируется — повторный запуск создаст дубликаты issue.")
out.append("# Уже закрытые в бэклоге тикеты (со статусом ✅) создаются и сразу закрываются —")
out.append("# это сохраняет историю выполненной работы в GitHub.")
out.append("set -euo pipefail")
out.append("")
out.append(f'REPO="{REPO}"')
out.append('echo "Репозиторий: $REPO"')
out.append("")
out.append("# --- Метка соответствия ID тикета -> номер issue (для справки, пишется в файл) ---")
out.append('MAP_FILE="arc_issue_map.tsv"')
out.append(': > "$MAP_FILE"')
out.append("")
out.append("# --- 1. Метки (labels) ---")
out.append('echo "Создаю метки..."')
for lbl in sorted(all_labels):
    color = LABEL_COLORS.get(lbl, "ededed")
    out.append(
        f"gh label create '{esc_sq(lbl)}' --repo \"$REPO\" --color {color} --force >/dev/null 2>&1 || true"
    )
out.append("")

# Order: J epic first (matches doc's own recommended execution order), then A..I,
# within each epic preserve document order (tickets list is already in doc order).
out.append("# --- 2. Тикеты ---")

for t in tickets:
    tid = t["id"]
    title = clean_title(t["title"])
    epic = t["epic"]
    epic_title = EPIC_NAME.get(epic, t.get("epic_title") or "")
    body_lines = []
    body_lines.append(f"**Эпик {epic} — {epic_title}**")
    body_lines.append("")
    body_lines.append(f"Тип: {t['type']} · Приоритет: {t['priority']} · Оценка: {t['sp']}")
    if t["deps"]:
        body_lines.append(f"Зависит от: {t['deps']}")
    body_lines.append("")
    body_lines.extend(t["body"])
    body_lines.append("")
    body_lines.append("---")
    body_lines.append(f"_Перенесено из `dev_plan_tickets.md` ({tid})._")
    body = "\n".join(body_lines)

    labels = [type_label(t["type"]), prio_label(t["priority"]), f"epic: {epic}"]
    label_arg = ",".join(labels)

    out.append("")
    out.append(f"# {tid} — {title}")
    out.append(f'echo "Создаю {tid}..."')
    out.append(f"BODY_{tid.replace('-', '_')}=$(cat <<'ARC_EOF'")
    out.append(body)
    out.append("ARC_EOF")
    out.append(")")
    out.append(
        f'ISSUE_URL=$(gh issue create --repo "$REPO" '
        f"--title '{esc_sq(tid + ': ' + title)}' "
        f'--body "$BODY_{tid.replace("-", "_")}" '
        f"--label '{esc_sq(label_arg)}')"
    )
    out.append('ISSUE_NUM=$(basename "$ISSUE_URL")')
    out.append(f'echo -e "{tid}\\t$ISSUE_NUM\\t$ISSUE_URL" >> "$MAP_FILE"')
    if t["closed"]:
        note = t["close_note"] or "Реализовано и проверено."
        out.append(
            f"gh issue close \"$ISSUE_NUM\" --repo \"$REPO\" "
            f"--comment '{esc_sq(note)}'"
        )
    out.append('echo "  -> $ISSUE_URL"')

out.append("")
out.append('echo "Готово. Соответствие ID <-> issue сохранено в $MAP_FILE"')

with open("create_github_issues.sh", "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")

print(f"Wrote create_github_issues.sh — {len(tickets)} tickets, {len(all_labels)} labels")
