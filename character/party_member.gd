extends CharacterBody2D
class_name WorldPartyMember

const EPSILON: float = 25

@export var party_member: PartyMember:
	set(value):
		if party_member != value:
			party_member = value
			initialize_party_member()
@export var speed: float = 300.0

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var default_speed: float
var party_member_index: int:
	get:
		return party_member.index

func _ready() -> void:
	default_speed = speed
	# TODO: This looks weird no matter what i do. Fix this?
	z_index = (PartyMembers.party_members.size() - party_member_index) + 10
	#z_index = party_member_index + 10
	
	if is_instance_valid(party_member):
		initialize_party_member()
	else:
		assert(false, "No party member assigned to world party member.")

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	set_correct_direction()
	_set_correct_sprite()


func _set_correct_sprite() -> void:
	animated_sprite_2d.play()
	
	if velocity.x - EPSILON > 0:
		animated_sprite_2d.animation = &"walk_right"
	elif velocity.x + EPSILON < 0:
		animated_sprite_2d.animation = &"walk_left"
	elif velocity.y - EPSILON > 0:
		animated_sprite_2d.animation = &"walk_down"
	elif velocity.y + EPSILON < 0:
		animated_sprite_2d.animation = &"walk_up"
	else:
		if animated_sprite_2d.sprite_frames.has_animation(&"idle"):
			animated_sprite_2d.animation = &"idle"
		else:
			animated_sprite_2d.stop()

func set_correct_direction() -> void:
	if velocity.x > 0:
		direction = Vector2(1, 0)
	elif velocity.x < 0:
		direction = Vector2(-1, 0)
	elif velocity.y > 0:
		direction = Vector2(0, 1)
	elif velocity.y < 0:
		direction = Vector2(0, -1)

func initialize_party_member() -> void:
	animated_sprite_2d.sprite_frames = party_member.sprite_frames
