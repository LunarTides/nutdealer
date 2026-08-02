extends Node2D
class_name EncounterPartyMember

signal start_animation_ended
signal end_animation_ended

# TODO: Load PartyMember data directly instead.
@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		animated_sprite_2d.sprite_frames = sprite_frames

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D

var index: int
var data: PartyMember:
	get:
		return PartyMembers.party_members[index]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Encounter.intention_set.connect(func(intention: Encounter.Intention, party_member: PartyMember) -> void:
		if party_member != data:
			return
		
		if intention == Encounter.Intention.Fight:
			play_fight_intention_animation()
		elif intention == Encounter.Intention.Defend:
			play_defend_animation()
	)
	Encounter.enemy_turn_started.connect(func() -> void:
		if data.encounter_intention == Encounter.Intention.Fight:
			play_attack_animation()
			
			# TODO: Actually deal the intended amount.
			Encounter.deal_damage_to_enemy(0, 50)
	)
	
	# Play idle animation when it becomes this party member's turn.
	Encounter.turn_changed.connect(func(old: int, new: int) -> void:
		if new == index:
			animated_sprite_2d.play(&"battle_idle")
	)
	
	# Reset to idle animation when enemy turn ends.
	Encounter.enemy_turn_ended.connect(func() -> void:
		play_idle_animation()
	)
	
	Encounter.ending.connect(func(tile: Tile, won: bool) -> void:
		if won:
			# TODO: Align with dark world camera's transform.
			play_victory_animation(Game.party_members_with_player[index].global_position)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_encounter_start_animation() -> void:
	# TODO: Actually figure out what deltarune does here.
	animated_sprite_2d.play(&"walk_right")
	animated_sprite_2d.pause()
	
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, ^"position", Vector2(150, 150 * (index + 1)), 0.5)
	tween.tween_callback(start_animation_ended.emit)

func play_victory_animation(end_position: Vector2) -> void:
	animated_sprite_2d.play(&"battle_victory")
	await animated_sprite_2d.animation_finished
	
	# TODO: Wait until all party members are done with their encounters.
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, ^"position", end_position, 0.5)
	tween.tween_callback(end_animation_ended.emit)

func play_idle_animation() -> void:
	animated_sprite_2d.play(&"battle_idle")

func play_intro_animation() -> void:
	animated_sprite_2d.play(&"battle_intro")
	await animated_sprite_2d.animation_finished
	play_idle_animation()

func play_fight_intention_animation() -> void:
	animated_sprite_2d.play(&"battle_attack_ready")

func play_attack_animation() -> void:
	animated_sprite_2d.play(&"battle_attack")

func play_defend_animation() -> void:
	animated_sprite_2d.play(&"battle_defend")

func reposition() -> void:
	position = Vector2(150, 150 * (index + 1))
