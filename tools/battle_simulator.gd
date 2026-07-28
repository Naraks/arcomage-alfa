extends SceneTree
## ARC-054: headless-симулятор «ИИ против ИИ» для сбора статистики по картам
## (нужен ARC-023 для балансировки cost/value).
##
## Запуск (как GUT в CI, см. .github/workflows/ci.yml):
##   godot --headless --path . -s tools/battle_simulator.gd -- --games=500 --out=balance_report.csv
##
## Аргументы (все необязательные):
##   --games=N   сколько игр прогнать (по умолчанию 500, см. ARC-023: "выборка ≥500")
##   --out=PATH  путь для CSV со статистикой по картам (по умолчанию res://balance_report.csv)
##   --seed=N    зерно RNG для воспроизводимого прогона (по умолчанию не задаётся — каждый запуск другой)
##
## Каждая игра — независимый бой через MatchManager (тот же автозагруз, что использует
## battle_screen.gd и GUT-тесты), между двумя случайно выбранными профилями ИИ
## (Default/Aggressive/Builder/Economist, ARC-025/026). Обе стороны ведёт
## MatchManager._resolve_ai_turn(actor) напрямую — БЕЗ await/секундной задержки
## execute_ai_turn() (та существует только ради комфорта игрока-человека перед
## реальным battle_screen.gd; см. комментарий в match_manager.gd).
##
## Известная погрешность: MatchManager.setup_match() применяет бонусы
## ProfileManager (tower_hp/quarry) только к первому аргументу (player_data,
## "сторона A") — это специально асимметрично для реального single-player боя
## (мета-прогрессия у игрока-человека), но здесь превращается в небольшое
## систематическое преимущество той стороны, чья стратегия в конкретной игре
## оказалась на позиции A. Т.к. назначение стратегии на A/B рандомизируется
## независимо от самой стратегии, при достаточном числе игр эффект должен
## размываться, но для формально строгого сравнения матчапов эту асимметрию
## стоит иметь в виду — отчёт снят как приближённая эвристика (тот же уровень
## строгости, что у tools/coverage_report.py, ARC-077), не строгий A/B-тест.

const MAX_TURNS_PER_GAME := 300  # защита от зависшей игры без победителя (deck-out и т.п.)

const STRATEGY_PATHS := {
	"default": "res://data/resources/default_ai_strategy.gd",
	"aggressive": "res://data/resources/aggressive_ai_strategy.gd",
	"builder": "res://data/resources/builder_ai_strategy.gd",
	"economist": "res://data/resources/economist_ai_strategy.gd",
}

var _card_stats: Dictionary = {}  # card_name -> {"played": int, "wins": int}
var _matchup_stats: Dictionary = {}  # "a_vs_b" -> {"a_wins": int, "b_wins": int, "draws": int}
var _game_card_plays: Array = []  # за текущую игру: [{"name": String, "side": "a"/"b"}]
var _current_winner_side: String = ""


## Как addons/gut/gut_cmdln.gd (тот же способ запуска через `-s`, тот же
## Godot 4.7.1-stable в CI, см. .github/workflows/ci.yml): вход через _init(),
## а не _initialize() (у SceneTree в Godot 4 нет отдельного колбэка с таким
## именем) — и та же защитная пауза на случай, если движок ещё не
## зарегистрировал self как активный main loop к моменту вызова _init().
func _init() -> void:
	var max_iter := 20
	var iter := 0
	while Engine.get_main_loop() == null and iter < max_iter:
		await create_timer(0.01).timeout
		iter += 1
	if Engine.get_main_loop() == null:
		push_error("Main loop did not start in time.")
		quit(1)
		return

	var args := _parse_args()
	var num_games: int = args.get("games", 500)
	var out_path: String = args.get("out", "res://balance_report.csv")
	if args.has("seed"):
		seed(args["seed"])

	_seed_card_stats_from_all_cards()
	GameEvents.card_played.connect(_on_card_played)

	var strategy_names: Array = STRATEGY_PATHS.keys()

	for i in range(num_games):
		var strat_a: String = strategy_names[randi() % strategy_names.size()]
		var strat_b: String = strategy_names[randi() % strategy_names.size()]
		_run_one_game(strat_a, strat_b)
		if (i + 1) % 50 == 0:
			print("... ", i + 1, "/", num_games, " игр")

	_write_card_report(out_path)
	_write_matchup_report(out_path.get_basename() + "_matchups.csv")

	print("Готово: ", num_games, " игр.")
	print("Отчёт по картам: ", out_path)
	print("Отчёт по матчапам стратегий: ", out_path.get_basename() + "_matchups.csv")
	quit()


## Заранее заносит в _card_stats ВСЕ карты игры с нулевыми счётчиками — иначе
## карты, которые ни разу не были разыграны (самый интересный сигнал для
## ARC-023 — "почти никогда не разыгрываются"), просто не попали бы в отчёт.
func _seed_card_stats_from_all_cards() -> void:
	for path in MatchManager.ALL_CARD_PATHS:
		var card: CardData = load(path)
		if card and not _card_stats.has(card.card_name):
			_card_stats[card.card_name] = {"played": 0, "wins": 0}


## Полный, перемешанный пул всех карт игры (MatchManager.ALL_CARD_PATHS) — в
## отличие от MatchManager._build_generic_card_pool() (ограниченный
## STARTER_DECK_CARD_PATHS, ~11 уникальных карт), нужен, чтобы обе стороны
## симуляции реально видели весь контент, а не только стартовый набор.
func _build_full_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path in MatchManager.ALL_CARD_PATHS:
		var card = load(path)
		if card:
			pool.append(card)
	pool.shuffle()
	return pool


func _on_card_played(card: CardData, player: Resource) -> void:
	var side := "a" if player == MatchManager.player_data else "b"
	_game_card_plays.append({"name": card.card_name, "side": side})


func _run_one_game(strat_a_name: String, strat_b_name: String) -> void:
	var p_a := PlayerData.new()
	var p_b := PlayerData.new()
	p_a.ai_strategy = load(STRATEGY_PATHS[strat_a_name]).new()
	p_b.ai_strategy = load(STRATEGY_PATHS[strat_b_name]).new()

	_game_card_plays = []
	_current_winner_side = ""
	var on_match_ended := func(winner):
		_current_winner_side = "a" if winner == MatchManager.player_data else "b"
	GameEvents.match_ended.connect(on_match_ended, CONNECT_ONE_SHOT)

	# setup_match(p_run_deck=...) даёт полный пул карт стороне A (player_data), но
	# для стороны B (enemy_data) нет параметра — её колода всегда строится из
	# STARTER_DECK_CARD_PATHS (11 карт, см. _build_generic_card_pool()). Без
	# переопределения ниже сторона B (и значит половина сыгранных карт по всем
	# играм) никогда не видела бы 55 из 66 карт — usage-rate отчёт был бы
	# бессмысленным для всего контента ARC-019/020. Переопределяем колоду и
	# руку B на тот же полный пул сразу после setup_match() (та уже успела
	# раздать стартовую руку B из старого, ограниченного enemy_deck).
	MatchManager.setup_match(p_a, p_b, _build_full_card_pool())
	MatchManager.enemy_deck = _build_full_card_pool()
	MatchManager.enemy_hand = []
	for i in range(5):
		MatchManager.draw_card(MatchManager.enemy_data)

	var turns := 0
	while MatchManager.current_state != MatchManager.State.END_MATCH and turns < MAX_TURNS_PER_GAME:
		if MatchManager.current_state == MatchManager.State.PLAYER_TURN:
			MatchManager._resolve_ai_turn(MatchManager.player_data)
		elif MatchManager.current_state == MatchManager.State.AI_TURN:
			MatchManager._resolve_ai_turn(MatchManager.enemy_data)
		else:
			break
		turns += 1

	if GameEvents.match_ended.is_connected(on_match_ended):
		GameEvents.match_ended.disconnect(on_match_ended)

	var winner_label: String = _current_winner_side if _current_winner_side != "" else "draw"
	_record_card_plays(winner_label)
	_record_matchup(strat_a_name, strat_b_name, winner_label)


func _record_card_plays(winner_label: String) -> void:
	for play in _game_card_plays:
		var name: String = play["name"]
		if not _card_stats.has(name):
			_card_stats[name] = {"played": 0, "wins": 0}
		_card_stats[name]["played"] += 1
		if play["side"] == winner_label:
			_card_stats[name]["wins"] += 1


func _record_matchup(strat_a_name: String, strat_b_name: String, winner_label: String) -> void:
	var key := "%s_vs_%s" % [strat_a_name, strat_b_name]
	if not _matchup_stats.has(key):
		_matchup_stats[key] = {"a_wins": 0, "b_wins": 0, "draws": 0}
	if winner_label == "a":
		_matchup_stats[key]["a_wins"] += 1
	elif winner_label == "b":
		_matchup_stats[key]["b_wins"] += 1
	else:
		_matchup_stats[key]["draws"] += 1


func _write_card_report(out_path: String) -> void:
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		print("[ERROR] Не удалось открыть файл отчёта: ", out_path)
		return

	file.store_line("card_name,times_played,times_on_winning_side,win_rate_when_played")
	var names: Array = _card_stats.keys()
	names.sort()
	for name in names:
		var stats: Dictionary = _card_stats[name]
		var played: int = stats["played"]
		var wins: int = stats["wins"]
		var win_rate: String = "%.2f" % (float(wins) / played) if played > 0 else "n/a"
		file.store_line("\"%s\",%d,%d,%s" % [name, played, wins, win_rate])
	file.close()


func _write_matchup_report(out_path: String) -> void:
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		print("[ERROR] Не удалось открыть файл отчёта по матчапам: ", out_path)
		return

	file.store_line("strategy_a,strategy_b,games,a_win_rate,b_win_rate,draw_rate")
	var keys: Array = _matchup_stats.keys()
	keys.sort()
	for key in keys:
		var stats: Dictionary = _matchup_stats[key]
		var parts: PackedStringArray = key.split("_vs_")
		var total: int = stats["a_wins"] + stats["b_wins"] + stats["draws"]
		file.store_line(
			"%s,%s,%d,%.2f,%.2f,%.2f" % [
				parts[0],
				parts[1],
				total,
				float(stats["a_wins"]) / total,
				float(stats["b_wins"]) / total,
				float(stats["draws"]) / total,
			]
		)
	file.close()


func _parse_args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts: PackedStringArray = arg.substr(2).split("=", true, 1)
			var key: String = parts[0]
			var raw_value: String = parts[1]
			result[key] = raw_value.to_int() if raw_value.is_valid_int() else raw_value
	return result
