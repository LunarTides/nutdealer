extends VBoxContainer

const ENEMY: PackedScene = preload("uid://du043hf2x26vo")

@export var encounter_ui: Control:
	set(value):
		encounter_ui = value
		
		encounter_ui.visibility_changed.connect(func() -> void:
			if not encounter_ui.visible:
				return
			
			# When the encounter ui becomes visible, refresh the enemies.
			for child: Control in get_children():
				child.queue_free()
			
			for i: int in range(tile.encounter.enemies.size()):
				var _enemy: EncounterEnemy = tile.encounter.enemies[i]
				
				var enemy_node: Button = ENEMY.instantiate()
				enemy_node.enemy_index = i
				#enemy_node.sprite_frames = enemy.sprite_frames
				setup_enemy_node(enemy_node)
				add_child(enemy_node)
		)
@export var party_member_customizer: PanelContainer
@export var enemy_customizer: PanelContainer

var tile: Tile

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child: Control in get_children():
		child.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_add_button_pressed() -> void:
	var enemy: EncounterEnemy = EncounterEnemy.new()
	tile.encounter.enemies.append(enemy)
	
	var new_index: int = get_child_count()
	
	var enemy_node: Button = ENEMY.instantiate()
	enemy_node.enemy_index = new_index
	setup_enemy_node(enemy_node)
	add_child(enemy_node)
	
	# Show enemy info
	party_member_customizer.hide()
	enemy_customizer.enemy_index = new_index
	enemy_customizer.show()

func setup_enemy_node(node: Button) -> void:
	node.pressed.connect(func() -> void:
		party_member_customizer.hide()
		enemy_customizer.enemy_index = node.enemy_index
		enemy_customizer.show()
	)
	node.deleted.connect(func() -> void:
		tile.encounter.enemies.pop_at(node.enemy_index)
		for child: Button in get_children():
			child.enemy_index -= 1
	)
