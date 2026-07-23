extends CharacterBody2D
class_name CreatorPartyMember

enum CharacterName {
	Kris,
	Susie,
	Ralsei,
}

enum State {
	Moving,
}

signal target_reached

@export var character_name: CharacterName = CharacterName.Kris

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D

var speed: float = 75
var state: State = State.Moving
var target: Vector2
var in_dialogue: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.y = Global.screen_size.y - 32 - 6
	position.x = randf_range(32, Global.screen_size.x - 32)
	create_state_loop()
	create_dialogue_loop()


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	if target:
		var vector: Vector2 = (target - position).normalized()
		velocity = vector * speed
		
		if position.distance_to(target) <= 4:
			target_reached.emit()
			target = Vector2.ZERO
	
		if vector.y > 0:
			animated_sprite_2d.play(&"move_down")
		elif vector.y < 0:
			animated_sprite_2d.play(&"move_up")
		elif vector.x > 0:
			animated_sprite_2d.play(&"move_right")
		elif vector.x < 0:
			animated_sprite_2d.play(&"move_left")
	else:
		animated_sprite_2d.stop()
	
	move_and_slide()

func create_state_loop() -> void:
	while true:
		while state == State.Moving:
			pick_spot_to_move()
			await target_reached
			await get_tree().create_timer(randf_range(1, 20)).timeout

func create_dialogue_loop() -> void:
	while true:
		while state == State.Moving:
			await get_tree().create_timer(randf_range(1, 30)).timeout
			
			if not in_dialogue:
				do_random_dialogue()

func pick_spot_to_move() -> void:
	target = Vector2(randf_range(32, Global.screen_size.x - 32), position.y)

func say(text: String, speaker: CharacterName = character_name) -> void:
	# TODO: Show dialogue boxes instead of printing to console.
	if speaker == CharacterName.Kris:
		print_rich("[color=red]%s[/color]" % text)
	elif speaker == CharacterName.Susie:
		print_rich("[color=purple]%s[/color]" % text)
	elif speaker == CharacterName.Ralsei:
		print_rich("[color=green]%s[/color]" % text)

func click() -> void:
	if character_name == CharacterName.Kris:
		say("...")
	elif character_name == CharacterName.Susie:
		say("What the hell?! Show yourself!")
	elif character_name == CharacterName.Ralsei:
		say("Did... did you just click me?")

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# TODO: Add dragging around.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				click()

func handle_dialogue_string(dialogue: PackedStringArray) -> void:
	# Empty line.
	print()
	in_dialogue = true
	
	for line: String in dialogue:
		var effect: String = line.split("]")[0].lstrip("[")
		var effect_args: String
		
		var equal_split: PackedStringArray = effect.split("=")
		if equal_split.size() >= 2:
			effect_args = equal_split[1]
			effect = equal_split[0]
		
		var text: String = line.split("]")[1]
		
		if effect == "wait":
			var milli: float = effect_args.to_float()
			await get_tree().create_timer(milli / 1000).timeout
			continue
		
		if text:
			if effect.to_lower() == "kris":
				say(text, CharacterName.Kris)
			elif effect.to_lower() == "susie":
				say(text, CharacterName.Susie)
			elif effect.to_lower() == "ralsei":
				say(text, CharacterName.Ralsei)
	
	in_dialogue = false

func do_random_dialogue() -> void:
	var rand: int = randi_range(0, 1)
	var dialogue: Dictionary[CharacterName, PackedStringArray]
	
	if rand == 0:
		# Nothing
		return
	elif rand == 1:
		dialogue = {
			# let me have fun, okay >:(
			CharacterName.Ralsei: [
				"[ralsei]I wonder if this is grid is infinite...",
				"[wait=3000]",
				"[susie]Dude, what are you talking about?",
			],
			CharacterName.Susie: [
				"[susie]So, whose nuts do you think they're dealing?",
				"[wait=2000]",
				"[ralsei]I think the nuts are supposed to be dark worlds?",
				"[wait=2000]",
				"[susie]Wait, they're creating dark worlds?",
				"[kris]*perks up*",
				"[wait=1000]",
				"[susie]Isn't that, y'know, bad?",
				"[wait=2000]",
				"[ralsei]Um, well, yes.",
				"[wait=3000]",
				"[susie]Damn...",
			]
		}
	
	if not dialogue.has(character_name):
		return
	
	handle_dialogue_string(dialogue[character_name])
