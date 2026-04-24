extends BasicEnemy

@export var chase_speed = 200.0
@export var attack_range: float = 300.0
@export var attack_cooldown: float = 2.0
@export var projectile_speed: float = 400.0
@export var fly_range: float = 150.0

@onready var attack_timer = $AttackTimer
@onready var shoot_point = $ShootPoint
@onready var ceiling_ray = $CeilingRay
@onready var string_line = $String

var projectile_scene = preload("res://src/entities/enemies/projectile/projectile.tscn")

enum State { PATROL, CHASE, ATTACK }
var current_state = State.PATROL
var target_player: CharacterBody2D = null
var can_attack: bool = true
var _is_warning: bool = false

var _spawn_position: Vector2
var _fly_target: Vector2
var _fly_timer: float = 0.0
var _hover_time: float = 0.0

func _ready():
	super._ready()
	_spawn_position = global_position
	_fly_target = global_position

func _setup_enemy():
	health = 3
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

func _process(_delta):
	var end := Vector2(0, -2000)
	if ceiling_ray.is_colliding():
		end = to_local(ceiling_ray.get_collision_point())
	string_line.set_point_position(0, Vector2.ZERO)
	string_line.set_point_position(1, end)

func _normal_logic(delta: float):
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
	else:
		_state_logic(delta)
	move_and_slide()

func _state_logic(delta: float):
	match current_state:
		State.PATROL:
			_patrol_logic(delta)
		State.CHASE:
			_chase_logic(delta)
		State.ATTACK:
			_attack_logic(delta)

func _patrol_logic(delta: float):
	_fly_timer -= delta
	if _fly_timer <= 0.0 or global_position.distance_to(_fly_target) < 15.0:
		_pick_new_fly_target()
		_fly_timer = randf_range(1.5, 3.0)

	var dir = (_fly_target - global_position).normalized()
	velocity = dir * speed
	sprite.flip_h = velocity.x < 0
	sprite.play("move")

func _pick_new_fly_target():
	_fly_target = _spawn_position + Vector2(
		randf_range(-fly_range, fly_range),
		randf_range(-fly_range, fly_range)
	)

func _chase_logic(delta: float):
	if not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(target_player.global_position)
	var dir = (target_player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	sprite.flip_h = velocity.x < 0
	sprite.play("move")

	if dist <= attack_range and can_attack:
		current_state = State.ATTACK
	elif dist > 600.0:
		target_player = null
		current_state = State.PATROL

func _attack_logic(delta: float):
	_hover_time += delta
	velocity.x = 0.0
	velocity.y = sin(_hover_time * 3.0) * 30.0
	sprite.play("attack")

	if can_attack and not _is_warning:
		can_attack = false
		_is_warning = true
		_show_attack_warning()

func _show_attack_warning():
	var tween = create_tween()
	for i in 3:
		tween.tween_property(sprite, "modulate", Color(1.0, 0.45, 0.0), 0.12)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.12)
	tween.tween_callback(func():
		_is_warning = false
		sprite.modulate = Color(1, 1, 1)
		if current_state == State.ATTACK and is_instance_valid(target_player):
			_shoot_projectile()
		attack_timer.start()
	)

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
