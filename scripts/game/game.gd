extends Node

signal play_start
signal play_end

const TILES: PackedScene = preload("uid://c810cm35ke6y5")

var playing: bool = false:
	set(value):
		playing = value
		
		if playing:
			play_start.emit()
		else:
			play_end.emit()
var player: Player
var tiles: Tiles
var current_room: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_tiles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_tiles() -> void:
	tiles = TILES.instantiate()
	add_child(tiles)
