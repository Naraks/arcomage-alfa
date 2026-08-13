extends Node
## Headless-симулятор боёв между стратегиями ИИ.

const MAX_TURNS_PER_GAME := 300  # защита от зависшей игры без победителя (deck-out и т.п.)

const STRATEGY_PATHS := {
	"default": "res://data/resources/default_ai_strategy.gd",
	"aggressive": "res://data/resources/aggressive_ai_strategy.gd",
	"builder": "res://data/resources/builder_ai_strategy.gd",
	"economist": "res://data/resources/economist_ai_strategy.gd",
}

var _card_stats: Dictionary = {}  # card_name -> {"played": int, "wins": int}
var _matchup_stats: Dictionary = {}  # "a_vs_b" -> {"a_wins": int, "b_wins": int, "draws": int}
var _win_reason_stats: Dictionary = {}
var _game_card_plays: Array = []  # за текущую игру: [{"name": String, "side": "a"/"b"}]
var _current_winner_side: String = ""
var _current_win_reason: String = ""
var _current_win_resource: String = ""
var _game_rows: Array[Dictionary] = []


func _ready() -> void:
	var args := _parse_args()
	var requested_games: int = args.get("games", 500)
	var num_games: int = requested_games if requested_games % 2 == 0 else requested_games + 1
	var out_path: String = args.get("out", "res://balance_report.csv")
	var scheduler := RandomNumberGenerator.new()
	if args.has("seed"):
		scheduler.seed = args["seed"]
	else:
		scheduler.randomize()

	_seed_card_stats_from_all_cards()
	GameEvents.card_played.connect(_on_card_played)

	var strategy_names: Array = STRATEGY_PATHS.keys()

	for pair_index in range(int(num_games / 2)):
		var strat_a: String = strategy_names[scheduler.randi() % strategy_names.size()]
		var strat_b: String = strategy_names[scheduler.randi() % strategy_names.size()]
		var pair_seed: int = scheduler.randi()
		_run_one_game(strat_a, strat_b, pair_index, "a", pair_seed)
		_run_one_game(strat_a, strat_b, pair_index, "b", pair_seed)
		if (pair_index + 1) % 25 == 0:
			print("... ", (pair_index + 1) * 2, "/", num_games, " игр")

	_write_card_report(out_path)
	_write_matchup_report(out_path.get_basename() + "_matchups.csv")
	_write_win_reason_report(out_path.get_basename() + "_win_types.csv")
	_write_game_report(out_path.get_basename() + "_games.csv")

	print("Готово: ", num_games, " игр.")
	print("Отчёт по картам: ", out_path)
	print("Отчёт по матчапам стратегий: ", out_path.get_basename() + "_matchups.csv")
	print("Отчёт по типам победы: ", out_path.get_basename() + "_win_types.csv")
	print("Построчный отчёт по боям: ", out_path.get_basename() + "_games.csv")
	get_tree().quit()


func _seed_card_stats_from_all_cards() -> void:
	for path in MatchManager.ALL_CARD_PATHS:
		var card: CardData = load(path)
		if card and not _card_stats.has(card.card_name):
			_card_stats[card.card_name] = {"played": 0, "wins": 0}


func _build_full_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path in MatchManager.ALL_CARD_PATHS:
		var card = load(path)
		if card:
			pool.append(card)
	pool.shuffle()
	return pool


func _on_card_played(card: CardData, player: PlayerData) -> void:
	var side := "a" if player == MatchManager.player_data else "b"
	_game_card_plays.append({"name": card.card_name, "side": side})


func _run_one_game(
	strat_a_name: String, strat_b_name: String, pair_id: int, starting_side: String, pair_seed: int
) -> void:
	seed(pair_seed)
	var p_a := PlayerData.new()
	var p_b := PlayerData.new()
	p_a.ai_strategy = load(STRATEGY_PATHS[strat_a_name]).new()
	p_b.ai_strategy = load(STRATEGY_PATHS[strat_b_name]).new()
	var pair_deck_a := _build_full_card_pool()
	var pair_deck_b := _build_full_card_pool()

	_game_card_plays = []
	_current_winner_side = ""
	_current_win_reason = ""
	_current_win_resource = ""
	var on_match_ended := func(winner):
		_current_winner_side = "a" if winner == MatchManager.player_data else "b"
		_current_win_reason = MatchManager.last_win_reason
		_current_win_resource = MatchManager.last_win_resource
	GameEvents.match_ended.connect(on_match_ended, CONNECT_ONE_SHOT)

	MatchManager.setup_match(p_a, p_b, [], false, 0 if starting_side == "a" else 1, false)
	MatchManager.deck = (pair_deck_a if starting_side == "a" else pair_deck_b).duplicate()
	MatchManager.enemy_deck = (pair_deck_b if starting_side == "a" else pair_deck_a).duplicate()
	MatchManager.player_hand = []
	MatchManager.enemy_hand = []
	for i in range(5):
		MatchManager.draw_card(MatchManager.player_data)
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
	_record_win_reason(winner_label)
	_record_game(pair_id, starting_side, pair_seed, strat_a_name, strat_b_name, winner_label, turns)


func _record_game(
	pair_id: int,
	starting_side: String,
	pair_seed: int,
	strat_a: String,
	strat_b: String,
	winner: String,
	turns: int
) -> void:
	(
		_game_rows
		. append(
			{
				"pair_id": pair_id,
				"leg": starting_side,
				"seed": pair_seed,
				"strategy_a": strat_a,
				"strategy_b": strat_b,
				"starting_side": starting_side,
				"winner_side": winner,
				"turns": turns,
				"win_type": _win_reason_key(winner),
				"a_bricks": MatchManager.player_data.bricks,
				"a_gems": MatchManager.player_data.gems,
				"a_beasts": MatchManager.player_data.beasts,
				"b_bricks": MatchManager.enemy_data.bricks,
				"b_gems": MatchManager.enemy_data.gems,
				"b_beasts": MatchManager.enemy_data.beasts,
			}
		)
	)


func _write_game_report(out_path: String) -> void:
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		print("[ERROR] Не удалось открыть построчный отчёт симулятора: ", out_path)
		return
	var columns := [
		"pair_id",
		"leg",
		"seed",
		"strategy_a",
		"strategy_b",
		"starting_side",
		"winner_side",
		"turns",
		"win_type",
		"a_bricks",
		"a_gems",
		"a_beasts",
		"b_bricks",
		"b_gems",
		"b_beasts"
	]
	file.store_line(",".join(PackedStringArray(columns)))
	for row in _game_rows:
		var values: Array[String] = []
		for column in columns:
			values.append(str(row[column]))
		file.store_line(",".join(PackedStringArray(values)))
	file.close()


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


func _win_reason_key(winner_label: String) -> String:
	if winner_label == "draw":
		return "draw"
	if _current_win_reason == "resource":
		return "resource_%s" % _current_win_resource
	return _current_win_reason


func _record_win_reason(winner_label: String) -> void:
	var key := _win_reason_key(winner_label)
	_win_reason_stats[key] = _win_reason_stats.get(key, 0) + 1


func _write_win_reason_report(out_path: String) -> void:
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		print("[ERROR] Не удалось открыть файл отчёта по типам победы: ", out_path)
		return

	var total: int = 0
	for count in _win_reason_stats.values():
		total += count

	file.store_line("win_type,games,share")
	var known_order := [
		"tower_destroyed",
		"tower_height",
		"resource_bricks",
		"resource_gems",
		"resource_beasts",
		"draw"
	]
	for key in known_order:
		var count: int = _win_reason_stats.get(key, 0)
		var share: float = float(count) / total if total > 0 else 0.0
		file.store_line("%s,%d,%.3f" % [key, count, share])
	for key in _win_reason_stats.keys():
		if key in known_order:
			continue
		var count: int = _win_reason_stats[key]
		var share: float = float(count) / total if total > 0 else 0.0
		file.store_line("%s,%d,%.3f" % [key, count, share])
	file.close()


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
		file.store_line('"%s",%d,%d,%s' % [name, played, wins, win_rate])
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
		(
			file
			. store_line(
				(
					"%s,%s,%d,%.2f,%.2f,%.2f"
					% [
						parts[0],
						parts[1],
						total,
						float(stats["a_wins"]) / total,
						float(stats["b_wins"]) / total,
						float(stats["draws"]) / total,
					]
				)
			)
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
