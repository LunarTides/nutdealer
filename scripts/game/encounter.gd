extends Node

const ENCOUNTER_UI: PackedScene = preload("uid://dhefrdnkspjje")
const ENCOUNTER_PARTY_MEMBER: PackedScene = preload("uid://db1npunkjreud")

signal started(tile: Tile)
signal ended(tile: Tile)

var in_encounter: bool = false
var encounter_tile: Tile
var ui: EncounterUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.play_end.connect(func() -> void:
		if Encounter.in_encounter:
			Encounter.end()
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if in_encounter and Creator.enabled and event.is_action_pressed(&"debug_end_encounter"):
		end()

func start(tile: Tile) -> void:
	# Setup variables
	Game.mode = Game.Mode.Encounter
	in_encounter = true
	encounter_tile = tile
	
	# Setup tiles
	for t: Tile in Game.tiles.get_all():
		t.process_mode = Node.PROCESS_MODE_DISABLED
		t.hide()
	Game.player.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Create UI
	ui = ENCOUNTER_UI.instantiate()
	add_child(ui)
	
	var player_position: Vector2 = Game.player.get_global_transform_with_canvas().origin
	
	Game.player.hide()
	
	# Change camera
	ui.camera_2d.make_current()
	
	# Create lead party member (Kris)
	var party_member_lead: EncounterPartyMember = ENCOUNTER_PARTY_MEMBER.instantiate()
	party_member_lead.index = 0
	ui.add_child(party_member_lead)
	party_member_lead.global_position = player_position
	party_member_lead.play_intro_animation()
	await party_member_lead.intro_animation_ended
	
	# Create other Party Members
	for i: int in range(2):
		var party_member: EncounterPartyMember = ENCOUNTER_PARTY_MEMBER.instantiate()
		party_member.index = i + 1
		ui.add_child(party_member)
		party_member.reposition()
	
	started.emit(tile)

func end() -> void:
	# Setup variables
	Game.mode = Game.Mode.DarkWorld
	in_encounter = false
	
	# Setup tiles
	for t: Tile in Game.tiles.get_all():
		t.process_mode = Node.PROCESS_MODE_INHERIT
		t.show()
	Game.player.process_mode = Node.PROCESS_MODE_INHERIT
	Game.player.show()
	
	# Delete all children
	for child: Node in get_children():
		child.queue_free()
	
	ended.emit(encounter_tile)
	encounter_tile = null
