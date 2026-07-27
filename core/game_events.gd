extends Node

## Глобальная шина событий для Arcomage Roguelike

signal card_played(card: CardData, player: Resource)
signal turn_started(player: Resource)
signal turn_ended(player: Resource)
signal health_changed(player: Resource, amount: int)
signal resource_changed(player: Resource, type: String, amount: int)
signal match_started(player: Resource, enemy: Resource)
signal match_ended(winner: Resource)
signal artifact_triggered(artifact: ArtifactData, player: Resource)
