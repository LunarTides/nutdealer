extends WorldPartyMember
class_name FollowPlayer

@export var collision_shape_2d: CollisionShape2D

func _ready() -> void:
	super()
	
	# Wait a frame for the player to be positioned.
	await get_tree().process_frame
	global_position = Game.player.global_position
	
	Game.room_changed.connect(func(old: int, new: int) -> void:
		# Wait a frame for the player to be positioned.
		await get_tree().process_frame
		global_position = Game.player.global_position
	)

func _process(delta: float) -> void:
	super(delta)

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	# TODO: Allow shuffling
	var actual_speed: float = speed
	if Game.player.running:
		actual_speed = speed * 2
		animated_sprite_2d.speed_scale = 2
	else:
		animated_sprite_2d.speed_scale = 1
	
	if global_position.distance_to(Game.player.global_position) > 64 * party_member_index:
		# Far from player.
		velocity = (Game.player.global_position - global_position).normalized() * actual_speed
	
	collision_shape_2d.disabled = not velocity.is_zero_approx()
	
	move_and_slide()
	super(delta)
