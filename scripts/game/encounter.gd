extends Node

const ENCOUNTER_UI: PackedScene = preload("uid://dhefrdnkspjje")
const ENCOUNTER_PARTY_MEMBER: PackedScene = preload("uid://db1npunkjreud")

signal started(tile: Tile)
signal ended(tile: Tile)
signal turn_ended(turn: int)
signal state_changed(old: State, new: State)

enum State {
	PartyMembers,
	Enemy,
}

var in_encounter: bool = false
var encounter_tile: Tile
var encounter_datas: Array[EncounterData]
var state: State = State.PartyMembers:
	set(value):
		if state != value:
			var old: State = state
			state = value
			state_changed.emit(old, state)
			
			if state == State.Enemy:
				handle_enemy_turn()
var running: bool = false
var party_members: Array[PartyMemberData]
var turn: int
var ui: EncounterUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.play_end.connect(func() -> void:
		if Encounter.in_encounter:
			Encounter.end()
	)
	
	set_default_party_members()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if in_encounter and Creator.enabled and event.is_action_pressed(&"debug_end_encounter"):
		end()

func set_default_party_members() -> void:
	var kris: PartyMemberData = PartyMemberData.new()
	kris.name = "Kris"
	kris.health = 100
	party_members.append(kris)
	
	var susie: PartyMemberData = PartyMemberData.new()
	susie.name = "Susie"
	susie.health = 100
	party_members.append(susie)
	
	var ralsei: PartyMemberData = PartyMemberData.new()
	ralsei.name = "Ralsei"
	ralsei.health = 100
	party_members.append(ralsei)

func deal_damage(enemy_index: int, amount: int) -> void:
	var encounter_data: EncounterData = encounter_datas.get(enemy_index)
	if not encounter_data:
		return
	
	print_debug("[Encounter] Dealt %d damage to Enemy %d (%s). Health %d -> %d" % [amount, enemy_index + 1, encounter_data.name, encounter_data.health, encounter_data.health - amount])
	encounter_data.health -= amount
	
	if encounter_data.health <= 0:
		win_by_damage()

func defend_this_turn() -> void:
	# TODO: Implement
	print_debug("[Encounter] %s will defend this turn." % party_members[turn].name)

func end_turn() -> void:
	if not running:
		return
	
	if state == State.Enemy:
		state = State.PartyMembers
		
		var old_turn: int = turn
		turn = 0
		turn_ended.emit(old_turn)
		
		print_debug("[Encounter] Enemy turn ended.")
		return
	
	# Party member turn ended
	turn += 1
	print_debug("[Encounter] Turn counter incremented.")
	
	if turn >= party_members.size():
		state = State.Enemy
	
	turn_ended.emit(turn - 1)

func handle_enemy_turn() -> void:
	if not running:
		return
	
	# TODO: Do
	print_debug("[Encounter] Enemy turn. Enemy will do nothing for 1 second.")
	await get_tree().create_timer(1.0).timeout
	end_turn()

func start(tile: Tile) -> void:
	if in_encounter:
		Game.feedback("Already in an encounter.", Game.FeedbackType.Error)
		return
	
	print_debug("[Encounter] Encounter started.")
	
	# Setup variables
	Game.mode = Game.Mode.Encounter
	state = State.PartyMembers
	turn = 0
	running = true
	in_encounter = true
	encounter_tile = tile
	encounter_datas = encounter_tile.encounter_datas.duplicate_deep()
	
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
	if not in_encounter:
		return
	
	print_debug("[Encounter] Encounter ended.")
	
	# Setup variables
	Game.mode = Game.Mode.DarkWorld
	in_encounter = false
	running = false
	
	# Setup tiles
	for t: Tile in Game.tiles.get_all():
		t.process_mode = Node.PROCESS_MODE_INHERIT
		t.show()
	Game.player.show()
	Game.player.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Delete all children
	for child: Node in get_children():
		child.queue_free()
	
	ended.emit(encounter_tile)
	encounter_tile = null

func win_by_damage() -> void:
	running = false
	
	# TODO: Animation
	print_debug("[Encounter] Won by damage. Playing win animation.")
	await get_tree().create_timer(1.0).timeout
	
	end()
