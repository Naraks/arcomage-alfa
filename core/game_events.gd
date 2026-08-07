extends Node
## Глобальные сигналы игрового состояния.

signal card_played(card: CardData, player: Resource)
signal turn_started(player: Resource)
signal turn_ended(player: Resource)
signal damage_applied(target: Resource, amount: int, hit_wall: bool, source: Resource)
signal value_built(target: Resource, amount: int, part: String)
signal resource_changed(player: Resource, type: String, amount: int)
signal match_started(player: Resource, enemy: Resource)
signal match_ended(winner: Resource)
signal artifact_triggered(artifact: ArtifactData, player: Resource)
