extends Node2D
class_name Tile

const CREATOR_TILE_BEHAVIOUR_UI: PackedScene = preload("uid://b7xjlu3flg8wu")
const HOVER_SFX: AudioStream = preload("res://assets/audio/text/queen.wav")
const EXPLOSION_SFX: AudioStream = preload("res://assets/audio/sfx/badexplosion.wav")

signal id_changed

@export var texture: Texture2D:
	set(value):
		texture = value
		
		if is_inside_tree():
			sprite_2d.texture = texture
			regenerate_id()
@export var custom_texture_path: String:
	set(value):
		custom_texture_path = value
		load_custom_texture(custom_texture_path)
@export var is_solid: bool = false:
	set(value):
		is_solid = value
		
		if is_inside_tree():
			if is_solid:
				static_body_2d.collision_layer |= 1
			elif static_body_2d.collision_layer & 1 == 1:
				static_body_2d.collision_layer ^= 1
			
			regenerate_id()
@export var should_hide_during_play: bool = false:
	set(value):
		should_hide_during_play = value
		
		if is_inside_tree():
			regenerate_id()
@export var is_room_start_position: bool = false:
	set(value):
		is_room_start_position = value
		
		if is_inside_tree():
			regenerate_id()
# TODO: Remove this and replace it with more generic `encounter` property with different options.
@export var encounter_on_interact: bool = false:
	set(value):
		encounter_on_interact = value
		
		if is_inside_tree():
			regenerate_id()
			
			if encounter_on_interact:
				load_encounter_party_members()
@export var enabled: bool = true
@export_storage var logic_script_path: String
# TODO: Replace with a path for reusing encounters.
# TODO: Also, don't initialize this here, otherwise ALL tiles will have this in the world save.
@export_storage var encounter_enemies: Array[EncounterEnemy] = [EncounterEnemy.new()]
@export_storage var encounter_party_members: Array[PartyMember]

var id: String = "null":
	set(value):
		id = value
		id_changed.emit()
var coords: Vector2i:
	get:
		return Global.position_to_coords(global_position)
	set(value):
		global_position = Global.coords_to_position(value)
var room_index: int:
	get:
		return Room.position_to_room_index(global_position)
var logic_script: GDScript:
	set(value):
		logic_script = value
		
		if is_inside_tree():
			if is_instance_valid(logic_script):
				logic.set_script(logic_script)
			
			regenerate_id()
var logic_script_name: String:
	get:
		return logic_script_path.split("/")[-1].replace(".gd", "")
var logic_script_dirty: bool = false
var is_encounter: bool:
	get:
		return encounter_on_interact

@onready var static_body_2d: StaticBody2D = $StaticBody2D
@onready var sprite_2d: Sprite2D = $StaticBody2D/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var explosion_animated_sprite: AnimatedSprite2D = $Explosion
@onready var creator_sfx_player: AudioStreamPlayer = $CreatorSFXPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var actions: PanelContainer = $Actions
# TODO: Call _room_enter and _room_exit when entering / exiting room.
@onready var logic: TileLogic = $Logic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_custom_texture(custom_texture_path)
	
	sprite_2d.texture = texture
	if is_solid:
		static_body_2d.collision_layer |= 1
	elif static_body_2d.collision_layer & 1 == 1:
		static_body_2d.collision_layer ^= 1
	
	static_body_2d.mouse_entered.connect(_on_mouse_entered)
	static_body_2d.mouse_exited.connect(_on_mouse_exited)
	
	explosion_animated_sprite.hide()
	
	if id == "null":
		regenerate_id()
	
	logic.process_mode = Node.PROCESS_MODE_DISABLED
	Game.play_start.connect(func() -> void:
		if should_hide_during_play:
			hide()
		
		logic.process_mode = Node.PROCESS_MODE_PAUSABLE
	)
	Game.play_end.connect(func() -> void:
		if should_hide_during_play and not visible:
			show()
		
		logic.process_mode = Node.PROCESS_MODE_DISABLED
	)
	
	# Load script.
	if logic_script_path:
		var script: GDScript = load(logic_script_path)
		set_logic_script_to(script)
	
	# Change script path to reflect new world folder location.
	WorldSave.first_save_begun.connect(func() -> void:
		if not logic_script_path:
			return
		
		var relative_path: String = logic_script_path.split("/temp")[1]
		logic_script_path = CreatorResourceSaver.get_full_path(relative_path)
		logic_script.resource_path = logic_script_path
		logic.script.resource_path = logic_script_path
	)
	
	# Keep invisible if it should hide during play.
	visibility_changed.connect(func() -> void:
		if Game.playing and should_hide_during_play:
			hide()
	)
	
	# Call the `_ready` function on the tile if we're actually playing. (Not creating.)
	if not Creator.enabled:
		creator_sfx_player.queue_free()
		logic._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact() -> void:
	logic._interact()
	
	if encounter_on_interact:
		Encounter.start(self)

func disable() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	enabled = false

func enable() -> void:
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true

func clone(new_id: bool = false) -> Tile:
	var new_tile: Tile = duplicate(DUPLICATE_DEFAULT | DUPLICATE_INTERNAL_STATE)
	if new_id:
		new_tile.regenerate_id()
	return new_tile

func delete_with_explosion() -> void:
	if not enabled:
		# Already being deleted.
		return
	
	logic.process_mode = Node.PROCESS_MODE_DISABLED
	enabled = false
	sprite_2d.hide()
	
	for tile: Tile in Game.tiles.get_all():
		if not tile.enabled and tile != self:
			# Prioritize this tile's explosion sfx over any other.
			tile.creator_sfx_player.stop()
	
	creator_sfx_player.stream = EXPLOSION_SFX
	creator_sfx_player.play()
	
	explosion_animated_sprite.show()
	explosion_animated_sprite.play()
	await explosion_animated_sprite.animation_finished
	queue_free()

func load_custom_texture(texture_path: String) -> void:
	if not texture_path:
		return
	
	texture_path = CreatorResourceSaver.get_full_path(texture_path)
	
	for custom_texture: ImageTexture in GameData.custom_tile_textures:
		if custom_texture.resource_path == texture_path:
			texture = custom_texture

func create_logic_script(text: String, path: String) -> void:
	# New script.
	var script: GDScript = GDScript.new()
	script.source_code = text
	
	CreatorResourceSaver.save(script, path)
	# For some reason, we have to reload the script in order for it to work.
	script.reload()
	logic_script = script
	if not logic_script_path:
		logic_script_path = script.resource_path

func update_logic_script(text: String) -> void:
	# Update script.
	if not is_instance_valid(logic_script):
		Game.feedback("No logic script to update. Please call create_logic_script first.", Game.FeedbackType.Error)
		return
	
	logic_script.source_code = text
	CreatorResourceSaver.save(logic_script)
	logic_script.reload(true)
	logic.script = logic_script

func set_logic_script_to(script: GDScript) -> void:
	script.reload()
	logic_script = script
	if not logic_script_path and script.resource_path:
		logic_script_path = script.resource_path

func _on_mouse_entered() -> void:
	if Creator.enabled and Creator.mode == Creator.Mode.None and enabled and not actions.visible:
		sprite_2d.self_modulate *= 1.25
		creator_sfx_player.stream = HOVER_SFX
		creator_sfx_player.play()

func _on_mouse_exited() -> void:
	if Creator.enabled:
		sprite_2d.self_modulate = Color.WHITE

func regenerate_id() -> void:
	var chars: String = "abcdefghijklmnopqrstuvwxyz"
	
	var new_id: String = ""
	for _i: int in range(8):
		new_id += chars[randi_range(0, chars.length() - 1)]
	id = new_id
	
	# Anything that causes the id to be regenerated is a dirty operation.
	Creator.make_dirty()

func load_encounter_party_members() -> void:
	var kris: PartyMember = PartyMember.new()
	kris.name = "Kris"
	kris.health = 100
	kris.sprite_frames = load("res://resources/sprite_frames/kris.tres")
	encounter_party_members.append(kris)
	
	var susie: PartyMember = PartyMember.new()
	susie.name = "Susie"
	susie.health = 100
	susie.sprite_frames = load("res://resources/sprite_frames/susie.tres")
	encounter_party_members.append(susie)
	
	var ralsei: PartyMember = PartyMember.new()
	ralsei.name = "Ralsei"
	ralsei.health = 100
	ralsei.sprite_frames = load("res://resources/sprite_frames/ralsei.tres")
	encounter_party_members.append(ralsei)
