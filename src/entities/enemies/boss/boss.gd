extends BasicEnemy

@export var chase_speed: float = 160.0
@export var attack_range: float = 600.0
@export var attack_cooldown: float = 2.0
@export var tornado_speed: float = 380.0

@onready var attack_timer: Timer = $AttackTimer
@onready var shoot_point: Marker2D = $ShootPoint
@onready var ground_ray: RayCast2D = $GroundRay

var tornado_scene = preload("res://src/entities/enemies/boss/tornado.tscn")

enum BossState { PATROL, CHASE, ATTACK, LAND }
var current_state: BossState = BossState.PATROL
var target_player = null
var can_attack: bool = true
var _is_warning: bool = false
var _hover_time: float = 0.0
var _fly_target: Vector2
var _fly_timer: float = 0.0

const LAND_INTERVAL_MIN = 8.0
const LAND_INTERVAL_MAX = 12.0
const LAND_HOVER_HEIGHT = 90.0
var _land_countdown: float = 0.0
var _land_duration: float = 0.0
var _has_landed: bool = false

func _setup_enemy() -> void:
	health = 15
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
		# Center the health bar: each segment = 20px wide
		var bar_width = health * 20.0
		health_bar.offset_left = -bar_width / 2.0
		health_bar.offset_right = bar_width / 2.0
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	_fly_target = global_position
	_land_countdown = randf_range(LAND_INTERVAL_MIN, LAND_INTERVAL_MAX)

# Flying boss — no gravity
func _normal_logic(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity *= 0.9
	else:
		_state_logic(delta)
	move_and_slide()

func _state_logic(delta: float) -> void:
	# Tick land countdown in non-attack, non-land states
	if current_state == BossState.PATROL or current_state == BossState.CHASE:
		_land_countdown -= delta
		if _land_countdown <= 0.0:
			_enter_land_state()
			return

	match current_state:
		BossState.PATROL:
			_patrol_logic(delta)
		BossState.CHASE:
			_chase_logic(delta)
		BossState.ATTACK:
			_attack_logic(delta)
		BossState.LAND:
			_land_logic(delta)

func _patrol_logic(delta: float) -> void:
	_fly_timer -= delta
	if _fly_timer <= 0.0 or global_position.distance_to(_fly_target) < 20.0:
		_fly_target = global_position + Vector2(randf_range(-250, 250), randf_range(-120, 80))
		_fly_timer = randf_range(1.5, 3.0)
	var dir = (_fly_target - global_position).normalized()
	velocity = velocity.lerp(dir * speed, 0.06)
	sprite.flip_h = velocity.x < 0
	if sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")

func _chase_logic(delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = BossState.PATROL
		return
	var dist = global_position.distance_to(target_player.global_position)
	if dist <= attack_range and can_attack:
		current_state = BossState.ATTACK
		return
	if dist > 1400.0:
		target_player = null
		current_state = BossState.PATROL
		return
	var dir = (target_player.global_position - global_position).normalized()
	velocity = velocity.lerp(dir * chase_speed, 0.08)
	sprite.flip_h = velocity.x < 0
	if sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")

func _attack_logic(delta: float) -> void:
	_hover_time += delta
	velocity.x = lerp(velocity.x, 0.0, 0.12)
	velocity.y = sin(_hover_time * 2.5) * 28.0
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	if can_attack and not _is_warning:
		can_attack = false
		_is_warning = true
		_show_attack_warning()

func _enter_land_state() -> void:
	_land_countdown = randf_range(LAND_INTERVAL_MIN, LAND_INTERVAL_MAX)
	_land_duration = randf_range(2.5, 4.5)
	_has_landed = false
	# force_raycast_update gets a fresh result this frame, not last frame's
	ground_ray.force_raycast_update()
	if ground_ray.is_colliding():
		var hit_y = ground_ray.get_collision_point().y
		_fly_target = Vector2(global_position.x, hit_y - LAND_HOVER_HEIGHT)
	else:
		# No ground found — aim far down, will slide along floor when hit
		_fly_target = global_position + Vector2(0.0, 2000.0)
	current_state = BossState.LAND

func _land_logic(delta: float) -> void:
	var to_target = _fly_target - global_position

	if not _has_landed:
		# Phase 1: descend fast toward ground
		if to_target.length() > 22.0:
			velocity = velocity.lerp(to_target.normalized() * chase_speed * 1.8, 0.12)
		else:
			_has_landed = true
			velocity = Vector2.ZERO
		sprite.flip_h = velocity.x < 0
		if sprite.sprite_frames.has_animation("fly"):
			sprite.play("fly")
		return

	# Phase 2: hover at ground level, count down stay duration
	_land_duration -= delta
	velocity = velocity.lerp(Vector2.ZERO, 0.2)
	if _land_duration <= 0.0:
		_fly_target = global_position + Vector2(randf_range(-200.0, 200.0), -250.0)
		_fly_timer = randf_range(1.5, 3.0)
		if is_instance_valid(target_player):
			current_state = BossState.CHASE
		else:
			current_state = BossState.PATROL

func _show_attack_warning() -> void:
	var tween = create_tween()
	for i in 6:
		tween.tween_property(sprite, "modulate", Color(0.2, 0.8, 1.0), 0.20)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.20)
	tween.tween_callback(func():
		_is_warning = false
		sprite.modulate = Color(1.0, 1.0, 1.0)
		if is_instance_valid(self) and current_state == BossState.ATTACK:
			_shoot_tornado_burst()
		attack_timer.start()
	)

func _shoot_tornado_burst() -> void:
	if not is_instance_valid(target_player):
		return
	var base_dir = (target_player.global_position - shoot_point.global_position).normalized()
	var angles = [-0.38, 0.0, 0.38]  # ~22 degrees spread
	for angle_offset in angles:
		var proj = tornado_scene.instantiate()
		proj.global_position = shoot_point.global_position
		proj.direction = base_dir.rotated(angle_offset)
		proj.speed = tornado_speed
		get_tree().current_scene.add_child(proj)

func _on_attack_timer_timeout() -> void:
	can_attack = true
	_hover_time = 0.0
	if is_instance_valid(target_player):
		current_state = BossState.CHASE
	else:
		current_state = BossState.PATROL

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body
		current_state = BossState.CHASE

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		current_state = BossState.PATROL
