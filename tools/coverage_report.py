#!/usr/bin/env python3
"""ARC-077: приблизительный отчёт о покрытии тестами.

Не настоящее line coverage (для GDScript/GUT такого инструмента в проекте нет —
единственный найденный, nano-coverage-godot, alpha-качества и требует сборки
GDExtension из C++ прямо в CI, что для "не строгого требования, но видимости
тренда" из тикета — явный overkill). Вместо этого — по-функциональная эвристика:
для каждой публичной функции в "ядровых" файлах (core/*.gd, AI-стратегии)
проверяем, упоминается ли её имя (как вызов) хоть в одном файле tests/*.gd.

Это не гарантирует, что тело функции реально выполнилось при вызове — но даёт
ровно то, что просит тикет: видимость, какие функции ядра вообще не упомянуты
ни в одном тесте, чтобы осознанно решать, где риск регрессии выше всего.

Запуск: python3 tools/coverage_report.py [--out coverage_report.txt]
"""
import argparse
import glob
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# "Ядро" по описанию тикета: match_manager.gd, artifact_manager.gd, AI-стратегии.
# core/*.gd обобщённо покрывает первые два (плюс остальные автозагрузки — та же
# логика, тот же риск регрессии); data/resources/*ai_strategy*.gd — AI-стратегии.
SOURCE_GLOBS = ["core/*.gd", "data/resources/*ai_strategy*.gd"]
TEST_GLOB = "tests/*.gd"

FUNC_DEF_RE = re.compile(r"^(?:static\s+)?func\s+(\w+)\s*\(", re.MULTILINE)


def extract_functions(path: Path) -> list[str]:
	text = path.read_text(encoding="utf-8")
	return FUNC_DEF_RE.findall(text)


def build_test_corpus() -> str:
	chunks = []
	for path in sorted(REPO_ROOT.glob(TEST_GLOB)):
		chunks.append(path.read_text(encoding="utf-8"))
	return "\n".join(chunks)


def is_referenced(func_name: str, test_corpus: str) -> bool:
	# \b на _ не срабатывает как границы слова в Python re (._ считается "word"
	# символом), поэтому GDScript-идентификаторы (snake_case) matчатся корректно
	# через \b по краям — то, что нужно.
	pattern = re.compile(r"\b" + re.escape(func_name) + r"\s*\(")
	return pattern.search(test_corpus) is not None


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--out", default="coverage_report.txt")
	args = parser.parse_args()

	test_corpus = build_test_corpus()

	source_files: list[Path] = []
	for pattern in SOURCE_GLOBS:
		source_files.extend(sorted(REPO_ROOT.glob(pattern)))

	lines = []
	lines.append("Отчёт о покрытии тестами (ARC-077)")
	lines.append("=" * 60)
	lines.append(
		"Эвристика: функция считается 'упомянутой', если её имя вызывается хоть\n"
		"в одном файле tests/*.gd. Это НЕ line coverage — не гарантирует, что тело\n"
		"функции реально выполнилось, только показывает, какие функции ядра вообще\n"
		"не всплывают ни в одном тесте."
	)
	lines.append("")

	total_funcs = 0
	total_covered = 0
	uncovered_summary: list[str] = []

	for path in source_files:
		rel = path.relative_to(REPO_ROOT).as_posix()
		funcs = extract_functions(path)
		if not funcs:
			continue

		covered = [f for f in funcs if is_referenced(f, test_corpus)]
		uncovered = [f for f in funcs if f not in covered]

		total_funcs += len(funcs)
		total_covered += len(covered)

		pct = 100.0 * len(covered) / len(funcs) if funcs else 0.0
		lines.append(f"{rel}: {len(covered)}/{len(funcs)} ({pct:.0f}%)")
		if uncovered:
			for f in uncovered:
				lines.append(f"  - не упомянута в тестах: {f}()")
				uncovered_summary.append(f"{rel}: {f}()")
		lines.append("")

	overall_pct = 100.0 * total_covered / total_funcs if total_funcs else 0.0
	lines.append("-" * 60)
	lines.append(f"Итого: {total_covered}/{total_funcs} функций упомянуты в тестах ({overall_pct:.0f}%)")
	if uncovered_summary:
		lines.append("")
		lines.append(f"Всего непокрытых функций: {len(uncovered_summary)}")

	report = "\n".join(lines) + "\n"
	out_path = REPO_ROOT / args.out
	out_path.write_text(report, encoding="utf-8")
	print(report)
	print(f"Отчёт записан в {out_path}")


if __name__ == "__main__":
	main()
