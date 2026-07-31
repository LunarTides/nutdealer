extends Resource
class_name TileRoomTransition

enum Trigger {
	Touch,
	Interact,
	Manual,
}

@export var index: int = -1:
	set(value):
		if index != value:
			index = value
			emit_changed()
@export var coords: Vector2i:
	set(value):
		if coords != value:
			coords = value
			emit_changed()
@export var trigger: Trigger = Trigger.Touch:
	set(value):
		if trigger != value:
			trigger = value
			emit_changed()
