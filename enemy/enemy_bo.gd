class_name BeetleEnemy extends CharacterBody2D

@export var speed = 80.0
@export var chase_speed = 200.0
@export var gravity = 600.0
@export var health: int = 5
@export var damage: float = 1.0
@export var attack_range: float = 300.0
@export var attack_cooldown: float = 2.0
@export var projectile_speed: float = 400.0

@onready var sprite = $Sprite2D
@onready var ray_left = $left_raycast
@onready var ray_right = $right_raycast
@onready var floor_ray_left = $floor_ray_left
@onready var floor_ray_right = $floor_ray_right
@onready var attack_timer = $AttackTimer
@onready var shoot_point = $ShootPoint
@onready var anim = $anim
@onready var health_bar = $HealthBar

var projectile_scene = preload("res://enemy/projectile.tscn")

enum State { PATROL, CHASE, ATTACK }
var current_state = State.PATROL
var direction = 1
var player: CharacterBody2D = null
var can_attack: bool = true
var flip_cooldown: float = 0.0

var is_on_path = false
var last_pos: Vector2

func _ready():
	is_on_path = get_parent() is PathFollow2D
	last_pos = global_position
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
		# Force position and size for clarity
		health_bar.position = Vector2(0, -100)
		health_bar.custom_minimum_size = Vector2(60, 3)
		health_bar.z_index = 100
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true

func _physics_process(delta: float) -> void:
	if health <= 0:
		_die()
		return

	if is_on_path:
		var pf = get_parent()
		if pf is PathFollow2D and "is_waiting" in pf and pf.is_waiting:
			anim.play("RESET")
		else:
			anim.play("move")
		# Tự động quay mặt theo hướng di chuyển trên Path
		if global_position.x > last_pos.x:
			sprite.flip_h = true # Inverted
		elif global_position.x < last_pos.x:
			sprite.flip_h = false # Inverted
		last_pos = global_position
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Giảm flip cooldown
	if flip_cooldown > 0:
		flip_cooldown -= delta

	match current_state:
		State.PATROL:
			_patrol_logic()
		State.CHASE:
			_chase_logic()
		State.ATTACK:
			_attack_logic()

	move_and_slide()

func _patrol_logic():
	velocity.x = direction * speed
	anim.play("move")

	if flip_cooldown > 0:
		return  # Chưa hết cooldown, không kiểm tra flip

	var wall_detected = false
	if direction == 1 and ray_right.is_colliding():
		var collider = ray_right.get_collider()
		if not (collider is CharacterBody2D and collider.is_in_group("player")):
			wall_detected = true
	elif direction == -1 and ray_left.is_colliding():
		var collider = ray_left.get_collider()
		if not (collider is CharacterBody2D and collider.is_in_group("player")):
			wall_detected = true

	var edge_detected = false
	if direction == 1 and not floor_ray_right.is_colliding():
		edge_detected = true
	elif direction == -1 and not floor_ray_left.is_colliding():
		edge_detected = true

	if wall_detected or edge_detected:
		direction *= -1
		sprite.flip_h = direction < 0
		flip_cooldown = 0.3  # Chờ 0.3 giây trước khi flip lại

func _chase_logic():
	if not is_instance_valid(player):
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(player.global_position)
	var dir_to_player = sign(player.global_position.x - global_position.x)
	velocity.x = dir_to_player * chase_speed
	sprite.flip_h = dir_to_player < 0
	anim.play("move")

	if dist <= attack_range and can_attack:
		current_state = State.ATTACK
	elif dist > 500:
		player = null
		current_state = State.PATROL

func _attack_logic():
	velocity.x = 0
	anim.play("attack")

	if can_attack:
		_shoot_projectile()
		can_attack = false
		attack_timer.start()

func _shoot_projectile():
	if not is_instance_valid(player):
		return
	var proj = projectile_scene.instantiate()
	proj.global_position = shoot_point.global_position
	var dir_to_player = (player.global_position - shoot_point.global_position).normalized()
	proj.direction = dir_to_player
	proj.speed = projectile_speed
	get_tree().current_scene.add_child(proj)

func _on_attack_timer_timeout():
	can_attack = true
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range:
		current_state = State.ATTACK
	elif is_instance_valid(player):
		current_state = State.CHASE
	else:
		current_state = State.PATROL

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		current_state = State.PATROL

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
	
	if is_on_path:
		var pf = get_parent() as PathFollow2D
		if pf:
			var tween = create_tween()
			tween.tween_property(pf, "progress", pf.progress + (knock_dir * 40.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		velocity.x = knock_dir * 300.0
		velocity.y = -200.0
		move_and_slide()

func _flash_hit():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)

func _die():
	queue_free()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack"):
		take_damage(1)
		if Globals.soul < 1.0:
			Globals.soul += 0.125

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
