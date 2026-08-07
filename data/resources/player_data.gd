class_name PlayerData
extends Resource
## Боевые характеристики игрока или противника.

@export_group("Logic")
@export var tower_hp: int = 25
@export var wall_hp: int = 8
@export var max_hand_size: int = 5

@export_group("Resources")
@export var bricks: int = 5
@export var gems: int = 5
@export var beasts: int = 5

@export_group("Generators")
@export var quarry: int = 1
@export var magic: int = 1
@export var dungeon: int = 1

@export_group("AI")
@export var ai_strategy: Resource

@export_group("Artifacts")
@export var active_artifacts: Array[ArtifactData] = []
