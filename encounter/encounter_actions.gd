extends VBoxContainer

@export var party_member_index: int = 0

@export_category("UI Nodes")
@export var buttons_container: HBoxContainer
@export var labels_container: HBoxContainer
@export var sfx_player: AudioStreamPlayer

# TODO: Only have as many sets of actions as there are party members in this encounter.
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
	Encounter.turn_changed.connect(func(old: int, new: int) -> void:
		var from_behind: bool = (
			new > old and new == party_member_index or
			# Going from enemy to first party member.
			party_member_index == 0 and new == 0 and old > PartyMembers.party_members.size() - 1
		)
		if from_behind:
			button_index = 0
		
		reset_ui()
		
		if not from_behind:
			# Do setter side-effects.
			button_index = button_index
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed(&"walk_right"):
		button_index += 1
		sfx_player.stream = preload("res://assets/audio/ui/menumove.wav")
		sfx_player.play()
	elif event.is_action_pressed(&"walk_left"):
		button_index -= 1
		sfx_player.stream = preload("res://assets/audio/ui/menumove.wav")
		sfx_player.play()
	elif event.is_action_pressed(&"interact"):
		handle_action()
		sfx_player.stream = preload("res://assets/audio/ui/select.wav")
		sfx_player.play()

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
	var intention: Encounter.Intention = button_index as Encounter.Intention
	Encounter.set_intention(intention)
