class_name BasicEnemy extends CharacterBody2D

@export var health: int = 3
@export var damage: float = 1.0
@export var speed: float = 100.0
@export var gravity: float = 600.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar = get_node_or_null("HealthBar")

var is_dead: bool = false
var knockback_timer: float = 0.0

func _get_death_key() -> String:
	return scene_file_path + "::" + str(get_path())

func _ready():
	if Globals.is_enemy_dead(_get_death_key()):
		queue_free()
		return
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
		health_bar.z_index = 100
	_setup_enemy()

func _setup_enemy():
	pass

func _physics_process(delta: float) -> void:
	if health <= 0 or is_dead:
		if not is_dead:
			_die()
		return
	_normal_logic(delta)

func _normal_logic(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	if knockback_timer > 0:
		knockback_timer -= delta
	else:
		_state_logic(delta)
	move_and_slide()

func _state_logic(_delta: float):
	pass

func take_damage(amount: int = 1):
	health -= amount
	if health_bar:
		health_bar.value = health
	_flash_hit()
	_apply_knockback()

func _apply_knockback():
	var player_node = get_tree().get_first_node_in_group("player")
	if not player_node: return

	var knock_dir = sign(global_position.x - player_node.global_position.x)
	if knock_dir == 0: knock_dir = 1

	velocity.x = knock_dir * 250.0
	velocity.y = -150.0
	knockback_timer = 0.3
	move_and_slide()

func _flash_hit():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)

func _die():
	is_dead = true
	Globals.mark_enemy_dead(_get_death_key())
	collision_layer = 0
	collision_mask = 0

	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)

	if health_bar:
		health_bar.visible = false

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		await sprite.animation_finished
	queue_free()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack"):
		take_damage(1)
		if Globals.soul < 1.0:
			Globals.soul += 0.125

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not body.is_in_group("Enemy"):
		body.take_damage(damage)
