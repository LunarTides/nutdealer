extends Node

var in_dialogue: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_dialogue_loop()
	
	Game.play_start.connect(func() -> void:
		process_mode = Node.PROCESS_MODE_DISABLED
	)
	Game.play_end.connect(func() -> void:
		process_mode = Node.PROCESS_MODE_INHERIT
	)

func create_dialogue_loop() -> void:
	while true:
		await get_tree().create_timer(randf_range(1, 30)).timeout
		
		if not in_dialogue and process_mode != Node.PROCESS_MODE_DISABLED:
			do_random_dialogue()

func say(text: String, speaker: String) -> void:
	for party_member: CreatorPartyMember in get_children():
		if party_member.name.to_lower() == speaker.to_lower():
			party_member.say(text)

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
			say(text, effect)
	
	in_dialogue = false

func do_random_dialogue() -> void:
	var rand: int = randi_range(0, 2)
	var dialogue: PackedStringArray
	
	if rand == 0:
		# Nothing
		return
	elif rand == 1:
		dialogue = [
			"[ralsei]I wonder if this is grid is infinite...",
			"[wait=3000]",
			"[susie]Dude, what are you talking about?",
		]
	elif rand == 2:
		dialogue = [
			# let me have fun, okay >:(
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
	
	handle_dialogue_string(dialogue)
