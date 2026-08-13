extends Node
## Глобальные сигналы игрового состояния.

signal card_played(card: CardData, player: PlayerData)
signal turn_started(player: PlayerData)
signal turn_ended(player: PlayerData)
signal damage_applied(target: PlayerData, amount: int, hit_wall: bool, source: PlayerData)
signal value_built(target: PlayerData, amount: int, part: String)
signal resource_changed(player: PlayerData, type: String, amount: int)
signal match_started(player: PlayerData, enemy: PlayerData)
signal match_ended(winner: PlayerData)
signal artifact_triggered(artifact: ArtifactData, player: PlayerData)
