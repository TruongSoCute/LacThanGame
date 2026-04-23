extends BasicEnemy

@export var chase_speed = 200.0
@export var attack_range: float = 300.0
@export var attack_cooldown: float = 2.0
@export var projectile_speed: float = 400.0

@onready var attack_timer = $AttackTimer
@onready var shoot_point = $ShootPoint

var projectile_scene = preload("res://src/entities/enemies/projectile/projectile.tscn")

enum State { PATROL, CHASE, ATTACK }
var current_state = State.PATROL
var patrol_direction = 1
var target_player: CharacterBody2D = null
var can_attack: bool = true
var flip_cooldown: float = 0.0

func _setup_enemy():
	health = 5
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

func _state_logic(delta: float):
	if flip_cooldown > 0: flip_cooldown -= delta
	
	match current_state:
		State.PATROL:
			_patrol_logic(delta)
		State.CHASE:
			_chase_logic()
		State.ATTACK:
			_attack_logic()

func _patrol_logic(delta: float):
	velocity.x = patrol_direction * speed
	if anim: anim.play("move")

	if flip_cooldown <= 0:
		var wall_detected = (patrol_direction == 1 and $right_raycast.is_colliding()) or (patrol_direction == -1 and $left_raycast.is_colliding())
		var edge_detected = (patrol_direction == 1 and not $floor_ray_right.is_colliding()) or (patrol_direction == -1 and not $floor_ray_left.is_colliding())

		if wall_detected or edge_detected:
			patrol_direction *= -1
			sprite.flip_h = patrol_direction < 0
			flip_cooldown = 0.3

func _chase_logic():
	if not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(target_player.global_position)
	var dir_to_player = sign(target_player.global_position.x - global_position.x)
	velocity.x = dir_to_player * chase_speed
	sprite.flip_h = dir_to_player < 0
	if anim: anim.play("move")

	if dist <= attack_range and can_attack:
		current_state = State.ATTACK
	elif dist > 600:
		target_player = null
		current_state = State.PATROL

func _attack_logic():
	velocity.x = 0
	if anim: anim.play("attack")

	if can_attack:
		_shoot_projectile()
		can_attack = false
		attack_timer.start()

func _shoot_projectile():
	if not is_instance_valid(target_player): return
	var proj = projectile_scene.instantiate()
	proj.global_position = shoot_point.global_position
	var dir_to_player = (target_player.global_position - shoot_point.global_position).normalized()
	proj.direction = dir_to_player
	proj.speed = projectile_speed
	get_tree().current_scene.add_child(proj)

func _on_attack_timer_timeout():
	can_attack = true
	if is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= attack_range:
		current_state = State.ATTACK
	elif is_instance_valid(target_player):
		current_state = State.CHASE
	else:
		current_state = State.PATROL

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body
		current_state = State.CHASE

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		current_state = State.PATROL
