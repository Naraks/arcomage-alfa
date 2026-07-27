#!/usr/bin/env python3
"""Parse dev_plan_tickets.md into a list of ticket dicts (JSON on stdout)."""
import re
import json
import sys

SRC = "/sessions/laughing-pensive-ptolemy/mnt/alfa/dev_plan_tickets.md"

with open(SRC, encoding="utf-8") as f:
    lines = f.readlines()

epic_re = re.compile(r"^##\s+Эпик\s+([A-Z])\s+—\s+(.+?)\s*$")
ticket_re = re.compile(r"^(#{2,4})\s+(ARC-\d+)\s+—\s+(.+?)\s*$")
meta_re = re.compile(
    r"^-\s+\*\*Тип:\*\*\s*(?P<type>[^·]+?)\s*·\s*\*\*Приоритет:\*\*\s*(?P<prio>[^·]+?)\s*·\s*\*\*Оценка:\*\*\s*(?P<sp>[^·]+?)"
    r"(?:\s*·\s*\*\*Зависит от:\*\*\s*(?P<deps>.+))?\s*$"
)

epic_name = None
epic_title = None
tickets = []
cur = None


def flush(cur):
    if cur is None:
        return
    # trim trailing blank lines / trailing '---'
    while cur["body"] and cur["body"][-1].strip() in ("", "---"):
        cur["body"].pop()
    tickets.append(cur)


for raw in lines:
    line = raw.rstrip("\n")

    m_epic = epic_re.match(line)
    if m_epic:
        flush(cur)
        cur = None
        epic_name, epic_title = m_epic.group(1), m_epic.group(2)
        continue

    # Any other heading level (## section, not an epic/ticket) also ends the
    # current ticket's body — e.g. "## 0. Аудит..." or "### Репозиторий и Git-процесс".
    if re.match(r"^#{1,4}\s+\S", line) and not ticket_re.match(line):
        flush(cur)
        cur = None
        continue

    m_ticket = ticket_re.match(line)
    if m_ticket:
        flush(cur)
        _, tid, title = m_ticket.groups()
        cur = {
            "id": tid,
            "title": title,
            "epic": epic_name,
            "epic_title": epic_title,
            "type": None,
            "priority": None,
            "sp": None,
            "deps": None,
            "body": [],
            "closed": False,
            "close_note": None,
        }
        continue

    if cur is None:
        continue

    if cur["type"] is None:
        m_meta = meta_re.match(line)
        if m_meta:
            cur["type"] = m_meta.group("type").strip()
            cur["priority"] = m_meta.group("prio").strip()
            cur["sp"] = m_meta.group("sp").strip()
            deps = m_meta.group("deps")
            if deps:
                deps = deps.strip()
                if deps in ("—", "-", ""):
                    deps = None
            cur["deps"] = deps
            continue

    cur["body"].append(line)

    stripped = line.strip()
    if stripped.startswith(">"):
        text = stripped.lstrip(">").strip()
        if "✅" in stripped:
            cur["closed"] = True
            cur["close_note"] = text
        elif cur["closed"] and cur["close_note"] is not None:
            # continuation line of the same blockquote (wrapped across lines)
            cur["close_note"] += " " + text

flush(cur)

print(json.dumps(tickets, ensure_ascii=False, indent=2))
print(f"TOTAL={len(tickets)}", file=sys.stderr)
