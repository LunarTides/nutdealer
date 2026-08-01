extends PanelContainer

@export_category("UI Nodes")
@export var preview_button: Button
@export var party_members: VBoxContainer
@export var enemies: VBoxContainer

var tile: Tile:
	set(value):
		tile = value
		
		enemies.tile = tile
		party_members.tile = tile
var old_grid_position: Vector2
var behavior_ui: Control
var encounter_ui: Control:
	set(value):
		encounter_ui = value
		
		party_members.encounter_ui = encounter_ui
		enemies.encounter_ui = encounter_ui
var party_member_customizer: Control:
	set(value):
		party_member_customizer = value
		
		party_members.party_member_customizer = party_member_customizer
		enemies.party_member_customizer = party_member_customizer
var enemy_customizer: Control:
	set(value):
		enemy_customizer = value
		
		party_members.enemy_customizer = enemy_customizer
		enemies.enemy_customizer = enemy_customizer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()


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
