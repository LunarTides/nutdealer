extends Control

@export_category("UI Nodes")
@export var behavior_ui: Control
@export var preview_button: Button
@export var party_members: VBoxContainer
@export var enemies: VBoxContainer
@export var party_member_info: PanelContainer
@export var enemy_info: PanelContainer

var tile: Tile
var enemy_index: int = 0
var enemy: EncounterEnemy:
	get:
		return tile.encounter_enemies[enemy_index]
var old_grid_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()
	#enemy.changed.connect(update_ui)
	
	enemy_info.tile = tile
	party_member_info.tile = tile
	
	enemies.tile = tile
	party_members.tile = tile


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_ui() -> void:
	if Engine.is_editor_hint():
		return
	
	preview_button.text = "Start Encounter" if Game.playing else "Preview"


func _on_preview_button_pressed() -> void:
	if Room.bounds.size() <= 0:
		Game.feedback("There are no rooms to preview from.", Game.FeedbackType.Error)
		return
	
	var previewing: bool = Game.playing
	if not previewing:
		Creator.start_preview(0)
	
	behavior_ui.hide()
	Encounter.start(tile)
	Encounter.ended.connect(func(_tile: Tile, won: bool) -> void:
		if not previewing:
			Creator.stop_preview()
		
		behavior_ui.show()
	, ConnectFlags.CONNECT_ONE_SHOT)
