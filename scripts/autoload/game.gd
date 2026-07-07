extends Node

signal play_start
signal play_end

var playing: bool = false:
	set(value):
		playing = value
		
		if playing:
			play_start.emit()
		else:
			play_end.emit()
var controlling_character: ControllingCharacter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
