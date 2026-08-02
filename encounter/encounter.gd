extends Node

const ENCOUNTER_UI: PackedScene = preload("uid://dhefrdnkspjje")
const ENCOUNTER_PARTY_MEMBER: PackedScene = preload("uid://db1npunkjreud")
const PROJECTILE: PackedScene = preload("uid://ddbwwx6oq47q6")

signal started(tile: Tile)
signal ending(tile: Tile, won: bool)
signal ended(tile: Tile, won: bool)
signal turn_ended(turn: int)
signal turn_changed(old: int, new: int)
signal state_changed(old: State, new: State)
signal enemy_turn_started
signal enemy_turn_ended
signal intention_set(intention: Intention, party_member: PartyMember)
signal tp_changed(old: int, new: int)

enum Intention {
	Fight,
	Act,
	Item,
	Spare,
	Defend,
}

enum State {
	PartyMembers,
	Enemy,
}

var in_encounter: bool = false
var encounter_tile: Tile
var enemies: Array[EncounterEnemy]
var party_members: Array[PartyMember]:
	get:
		return PartyMembers.party_members
var party_member: PartyMember:
	get:
		return party_members.get(turn)
var state: State = State.PartyMembers:
	set(value):
		if state != value:
			var old: State = state
			state = value
			state_changed.emit(old, state)
			
			if state == State.Enemy:
				enemy_turn_started.emit()
				handle_enemy_turn()
			elif old == State.Enemy:
				enemy_turn_ended.emit()
var running: bool = false
var turn: int:
	set(value):
		if turn != value:
			var old: int = turn
			turn = value
			turn_changed.emit(old, turn)
var is_enemy_turn: bool:
	get:
		return turn > party_members.size() - 1
var tp: int = 0:
	set(value):
		if tp != value:
			var old: int = tp
			tp = value
			tp_changed.emit(old, tp)
var tp_earned_for_defending: int = 16
var ui: EncounterUI
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	# The music shouldn't deafen sfx.
	music_player.bus = &"Music"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	Game.play_ended.connect(func() -> void:
		if in_encounter:
			end(true, true)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not in_encounter:
		return
	
	if Creator.enabled and event.is_action_pressed(&"debug_end_encounter"):
		end(true, true)
	
	# Go back
	if turn > 0 and not is_enemy_turn and event.is_action_pressed(&"encounter_back"):
		turn -= 1
		
		if party_member.encounter_intention == Intention.Defend:
			# Get rid of earned TP.
			tp -= tp_earned_for_defending


func deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
	var enemy: EncounterEnemy = enemies.get(enemy_index)
	if not enemy:
		return
	
	print_debug("[Encounter] Dealt %d damage to Enemy %d (%s). Health %d -> %d" % [amount, enemy_index + 1, enemy.name, enemy.health, enemy.health - amount])
	enemy.health -= amount
	
	# TODO: This should only happen once ALL enemies are dead.
	if enemy.health <= 0:
		win_by_damage()

func deal_damage_to_party_targets(amount: int) -> void:
	# TODO: Deal damage to attack targets.
	print_debug("[Encounter] Dealt %d damage to %s. Health %d -> %d" % [amount, party_members[0].name, party_members[0].health, party_members[0].health - amount])
	party_members[0].health -= amount

func heal_party_targets(amount: int) -> void:
	# TODO: Heal attack targets.
	# TODO: Clamp to max health.
	print_debug("[Encounter] Healed %d damage to %s. Health %d -> %d" % [amount, party_members[0].name, party_members[0].health, party_members[0].health + amount])
	party_members[0].health += amount

func set_intention(intention: Intention) -> void:
	print_debug("[Encounter] %s will %s this turn." % [party_member.name, Intention.keys()[intention]])
	if intention == Intention.Defend:
		tp += tp_earned_for_defending
	
	party_member.encounter_intention = intention
	intention_set.emit(intention, party_member)
	end_turn()

func end_turn() -> void:
	if not running:
		return
	
	if state == State.Enemy:
		var old_turn: int = turn
		turn = 0
		turn_ended.emit(old_turn)
		
		state = State.PartyMembers
		
		print_debug("[Encounter] Enemy turn ended.")
		return
	
	# Party member turn ended
	turn += 1
	print_debug("[Encounter] Turn counter incremented.")
	
	turn_ended.emit(turn - 1)
	
	if turn >= party_members.size():
		state = State.Enemy

func handle_enemy_turn() -> void:
	if not running:
		return
	
	# TODO: Do
	var projectile_1: Projectile = PROJECTILE.instantiate()
	projectile_1.sprite = preload("res://tile/assets/sprites/debug/red.svg")
	projectile_1.start_position = Vector2(339, 57)
	ui.soul_container.add_child(projectile_1)
	
	var projectile_2: Projectile = PROJECTILE.instantiate()
	projectile_2.sprite = preload("res://tile/assets/sprites/debug/green.svg")
	projectile_2.type = Projectile.ProjectileType.Heal
	projectile_2.start_position = Vector2(339, 200)
	ui.soul_container.add_child(projectile_2)
	
	print_debug("[Encounter] Enemy turn. Spawn 2 projectiles, wait for 2 seconds.")
	await get_tree().create_timer(3.0).timeout
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
	tp = 0
	running = true
	in_encounter = true
	encounter_tile = tile
	enemies = encounter_tile.encounter.enemies.duplicate_deep()
	
	# Setup tiles
	for t: Tile in Game.tiles.get_all():
		t.disable()
	Game.pause_music()
	
	for party_member: WorldPartyMember in Game.party_members_with_player:
		party_member.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Play tension sfx
	sfx_player.stream = preload("res://assets/audio/battle/tensionhorn.wav")
	sfx_player.pitch_scale = 1.0
	sfx_player.play()
	await get_tree().create_timer(0.3).timeout
	sfx_player.pitch_scale = 1.1
	sfx_player.play()
	
	# Create UI
	ui = ENCOUNTER_UI.instantiate()
	add_child(ui)
	
	for party_member: WorldPartyMember in Game.party_members_with_player:
		party_member.hide()
	
	# Create Party Members
	var last_member: EncounterPartyMember
	for i: int in range(party_members.size()):
		# Check if the party member is included in this encounter.
		if not tile.encounter.party_member_names.has(party_members[i].name):
			i -= 1
			continue
		
		var world_member: WorldPartyMember = Game.party_members_with_player[i]
		var member_position: Vector2 = world_member.get_global_transform_with_canvas().origin
		
		var party_member: EncounterPartyMember = ENCOUNTER_PARTY_MEMBER.instantiate()
		party_member.index = i
		party_member.sprite_frames = load("res://character/sprite_frames/%s.tres" % party_members[i].name.to_snake_case())
		ui.add_child(party_member)
		party_member.global_position = member_position
		party_member.play_encounter_start_animation()
		
		last_member = party_member
	
	# Change camera
	ui.camera_2d.make_current()
	
	# Stopping playing while intro animation was playing.
	await last_member.start_animation_ended
	if not Game.playing or not in_encounter:
		return
	
	# Play intro animation.
	for child: Node in ui.get_children():
		if child is not EncounterPartyMember:
			continue
		
		child.play_intro_animation()
	
	sfx_player.pitch_scale = 1.0
	sfx_player.stream = preload("res://assets/audio/battle/weaponpull.wav")
	sfx_player.play()
	
	# Preemptively load music while waiting for sfx to finish playing. 
	music_player.stream = preload("res://assets/audio/music/battle.ogg")
	await sfx_player.finished
	
	# Stopping playing while sfx was playing.
	if not Game.playing or not in_encounter:
		return
	
	music_player.play()
	
	started.emit(tile)

func end(won: bool, skip_anim: bool = false) -> void:
	if not in_encounter:
		return
	
	print_debug("[Encounter] Encounter ended with %d tp." % tp)
	ending.emit(encounter_tile, won)
	
	# Wait for victory animation.
	var encounter_party_member: EncounterPartyMember
	for child: Node in ui.get_children():
		if child is not EncounterPartyMember:
			continue
		
		encounter_party_member = child
	
	if not skip_anim:
		# Give time for animations and stuff.
		# TODO: This won't work if the animation lengths are different.
		await encounter_party_member.end_animation_ended
	
	# Setup variables
	Game.mode = Game.Mode.DarkWorld
	in_encounter = false
	running = false
	
	# Setup tiles
	for t: Tile in Game.tiles.get_all():
		t.enable()
	
	# If the encounter ends to to pressing the "Stop Preview" button,
	# the player doesn't exist.
	for party_member: WorldPartyMember in Game.party_members_with_player:
		party_member.show()
		party_member.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Delete all children
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			continue
		
		child.queue_free()
	
	music_player.stop()
	Game.play_music()
	
	ended.emit(encounter_tile, won)
	encounter_tile = null

func win_by_damage() -> void:
	running = false
	
	# TODO: Animation
	print_debug("[Encounter] Won by damage. Playing win animation.")
	await get_tree().create_timer(1.0).timeout
	
	end(true)
