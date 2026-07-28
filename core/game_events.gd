extends Node

## Глобальная шина событий для Arcomage Roguelike

signal card_played(card: CardData, player: Resource)
signal turn_started(player: Resource)
signal turn_ended(player: Resource)
## ARC-004: заменяет health_changed — урон по стене/башне (amount всегда
## положительный, hit_wall = урон шёл через стену, а не напрямую по башне).
## ARC-030: source — кто нанёс урон (может быть null — сигналы GDScript не
## поддерживают значения по умолчанию для параметров; null проставляет сам
## MatchManager.apply_damage(), если вызван без source). Нужен ArtifactManager
## для триггера "on_damage_taken" (Шипастая Стена, ARC-031, должна знать,
## КОМУ отвечать уроном). Существующие подписчики с меньшим числом параметров
## (напр. battle_screen.gd) не ломаются — Godot позволяет подключать Callable
## с меньшей арностью, чем у сигнала.
signal damage_applied(target: Resource, amount: int, hit_wall: bool, source: Resource)
## ARC-004: заменяет health_changed — прирост wall_hp/tower_hp от строительства
## (part = "wall" | "tower").
signal value_built(target: Resource, amount: int, part: String)
signal resource_changed(player: Resource, type: String, amount: int)
signal match_started(player: Resource, enemy: Resource)
signal match_ended(winner: Resource)
signal artifact_triggered(artifact: ArtifactData, player: Resource)
