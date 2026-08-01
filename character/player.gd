extends CharacterBody2D
class_name Player

@export var speed: float = 300.0

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D
@export var collision_shape_2d: CollisionShape2D
@export var camera: Camera2D

var direction: Vector2 = Vector2.ZERO
var noclip: bool = false:
	set(value):
		noclip = value
		collision_shape_2d.disabled = noclip
var default_speed: float

func _ready() -> void:
	default_speed = speed

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var actual_speed: float = speed
	if Input.is_action_pressed(&"run"):
		actual_speed *= 2
		animated_sprite_2d.speed_scale = 2
	else:
		animated_sprite_2d.speed_scale = 1
	
	# Get the input vector and handle the movement.
	var vector: Vector2 = Input.get_vector(&"walk_left", &"walk_right", &"walk_up", &"walk_down")
	if vector:
		velocity = vector * actual_speed
	else:
		velocity = Vector2.ZERO
	
	set_correct_direction()
	set_correct_sprite()
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	# Handle interacting with tiles.
	if event.is_action_pressed(&"interact"):
		var pos: Vector2 = global_position + (direction * 16)
		if direction == Vector2(0, 1):
			pos += direction * 32
		elif direction != Vector2(0, -1):
			pos += direction * 8
		
		var coords: Vector2i = Global.position_to_coords(pos)
		var tile: Tile = Game.tiles.get_tile_on(coords)
		
		if is_instance_valid(tile):
			tile.interact()

func set_correct_sprite() -> void:
	animated_sprite_2d.play()
	
	if velocity.x > 0:
		animated_sprite_2d.animation = &"walk_right"
	elif velocity.x < 0:
		animated_sprite_2d.animation = &"walk_left"
	elif velocity.y > 0:
		animated_sprite_2d.animation = &"walk_down"
	elif velocity.y < 0:
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


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.get_parent() is not Tile:
		return
	
	var tile: Tile = body.get_parent()
	tile.touch()
