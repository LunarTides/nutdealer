extends WorldPartyMember
class_name Player

@export_category("Nodes")
@export var collision_shape_2d: CollisionShape2D
@export var camera: Camera2D

var running: bool = false
var noclip: bool = false:
	set(value):
		noclip = value
		collision_shape_2d.disabled = noclip

func _ready() -> void:
	super()

func _process(delta: float) -> void:
	super(delta)

func _physics_process(delta: float) -> void:
	var actual_speed: float = speed
	if Input.is_action_pressed(&"run"):
		running = true
		actual_speed *= 2
		animated_sprite_2d.speed_scale = 2
	else:
		running = false
		animated_sprite_2d.speed_scale = 1
	
	# Get the input vector and handle the movement.
	var vector: Vector2 = Input.get_vector(&"walk_left", &"walk_right", &"walk_up", &"walk_down")
	if vector:
		velocity = vector * actual_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	super(delta)

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


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.get_parent() is not Tile:
		return
	
	var tile: Tile = body.get_parent()
	tile.touch()
