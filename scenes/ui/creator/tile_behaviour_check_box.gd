extends CheckBox
class_name TileBehaviourCheckBox

@export var tile_property: StringName

var tile: Tile:
	set(value):
		tile = value
		
		if not is_instance_valid(tile):
			Game.feedback("Invalid tile.", Game.FeedbackType.Error)
			return
		
		button_pressed = tile.get(tile_property)
		toggled.connect(func(toggled_on: bool) -> void:
			tile.set(tile_property, toggled_on)
		)
