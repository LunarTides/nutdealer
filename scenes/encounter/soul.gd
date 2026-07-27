extends CharacterBody2D

enum SoulColor {
	Red,
	Blue,
	Yellow,
	Purple,
	Orange,
}

@export var speed: float = 300.0
@export var color: SoulColor = SoulColor.Red

func _ready() -> void:
	Encounter.enemy_turn_started.connect(func() -> void:
		reposition()
	)

func _physics_process(delta: float) -> void:
	# TODO: Maybe don't normalize this vector?
	var direction: Vector2 = Input.get_vector(&"walk_left", &"walk_right", &"walk_up", &"walk_down")
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func reposition() -> void:
	global_position = Global.screen_size / 2


func _on_hitbox_area_entered(area: Area2D) -> void:
	var projectile: Projectile = area.get_parent()
	if projectile is Projectile:
		if projectile.type == Projectile.ProjectileType.Damage:
			# TODO: Do invincibility frames.
			Encounter.deal_damage_to_party_targets(projectile.damage)
		elif projectile.type == Projectile.ProjectileType.Heal:
			Encounter.heal_party_targets(projectile.damage)
		
		projectile.queue_free()
