extends HBoxContainer

const ACTIONS: PackedScene = preload("uid://ca03oun6n6xh4")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for node: Control in get_children():
		node.queue_free()
	
	for i: int in range(Encounter.party_members.size()):
		var actions: Control = ACTIONS.instantiate()
		actions.party_member_index = i
		add_child(actions)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
