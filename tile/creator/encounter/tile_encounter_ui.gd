extends Control

@export_category("UI Nodes")
@export var behavior_ui: Control
@export var main: PanelContainer
@export var party_member_customizer: PanelContainer
@export var enemy_customizer: PanelContainer

var tile: Tile:
	set(value):
		tile = value
		
		main.tile = tile
		party_member_customizer.tile = tile
		enemy_customizer.tile = tile
var enemy_index: int = 0
var enemy: EncounterEnemy:
	get:
		return tile.encounter.enemies[enemy_index]
var old_grid_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#enemy.changed.connect(update_ui)
	
	main.behavior_ui = behavior_ui
	main.encounter_ui = self
	main.party_member_customizer = party_member_customizer
	main.enemy_customizer = enemy_customizer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
