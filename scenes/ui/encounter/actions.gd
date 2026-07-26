extends VBoxContainer

@export var party_member_index: int = 0

@export_category("UI Nodes")
@export var buttons_container: HBoxContainer
@export var labels_container: HBoxContainer

var buttons: Array[TextureRect]:
	get:
		return buttons_container.get_children() as Array[TextureRect]
var labels: Array[Label]:
	get:
		return labels_container.get_children() as Array[Label]
var button_index: int = 0:
	set(value):
		var old_button: TextureRect = buttons[button_index]
		var old_label: Label = labels[button_index]
		old_button.modulate = Color.WHITE.darkened(0.2)
		old_label.modulate.a = 0.0
		
		button_index = value
		if button_index >= buttons.size():
			button_index = 0
		if button_index == -1:
			button_index = buttons.size() - 1
		
		var button: TextureRect = buttons[button_index]
		var label: Label = labels[button_index]
		
		button.modulate = Color.WHITE
		label.modulate.a = 1.0
var active: bool:
	get:
		return Encounter.turn == party_member_index

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_ui()
	Encounter.turn_ended.connect(func(turn: int) -> void:
		button_index = 0
		reset_ui()
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed(&"walk_right"):
		button_index += 1
	elif event.is_action_pressed(&"walk_left"):
		button_index -= 1
	elif event.is_action_pressed(&"interact"):
		handle_action()

func reset_ui() -> void:
	labels_container.visible = active
	modulate = Color.WHITE if active else Color.WHITE.darkened(0.2)
	
	offset_transform_position = Vector2.ZERO if active else Vector2(0, 16) 
	
	for i: int in range(labels.size()):
		if i == 0:
			continue
		
		# Darken all buttons other than the first one.
		var button: TextureRect = buttons[i]
		button.modulate = Color.WHITE.darkened(0.2)
		
		# Hide all labels other than the first one.
		var label: Label = labels[i]
		label.modulate.a = 0.0

func handle_action() -> void:
	# Fight
	if button_index == 0:
		# TODO: Choose an enemy.
		# TODO: Do the attack timing thing to vary attack damage.
		Encounter.deal_damage_to_enemy(0, 50)
		Encounter.end_turn()
	# Act
	elif button_index == 1:
		pass
	# Items
	elif button_index == 2:
		pass
	# Spare
	elif button_index == 3:
		pass
	# Defend
	elif button_index == 4:
		Encounter.defend_this_turn()
		Encounter.end_turn()
