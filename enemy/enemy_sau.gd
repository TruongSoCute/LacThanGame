class_name Basic_Enemy extends CharacterBody2D

@export var speed = 100.0
@export var gravity = 600.0
@export var health: int = 3
@export var damage: float = 1.0

@onready var ray_left = $left_raycast
@onready var ray_right = $right_raycast
@onready var sprite = $Sprite2D
@onready var floor_ray_left = $floor_ray_left
@onready var floor_ray_right = $floor_ray_right
@onready var health_bar = $HealthBar

enum State { PATROL }
var current_state = State.PATROL
var direction = -1
var flip_cooldown: float = 0.0

var is_on_path = false
var last_pos: Vector2

func _ready():
	is_on_path = get_parent() is PathFollow2D
	last_pos = global_position
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health

func _physics_process(delta: float) -> void:
	if health <= 0:
		_die()
		return

	if is_on_path:
		var pf = get_parent()
		if pf is PathFollow2D and "is_waiting" in pf and pf.is_waiting:
			$anim.play("RESET")
		else:
			$anim.play("move")
		# Tự động quay mặt theo hướng di chuyển trên Path
		if global_position.x > last_pos.x:
			sprite.flip_h = true # Đã đổi từ false sang true
		elif global_position.x < last_pos.x:
			sprite.flip_h = false # Đã đổi từ true sang false
		last_pos = global_position
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if flip_cooldown > 0:
		flip_cooldown -= delta

	match current_state:
		State.PATROL:
			_patrol_logic()

	$anim.play("move")
	move_and_slide()

func _patrol_logic():
	velocity.x = direction * speed

	if flip_cooldown > 0:
		return

	# Phát hiện tường bằng RayCast ngang
	var wall_detected = false
	if direction == 1 and ray_right.is_colliding():
		var collider = ray_right.get_collider()
		if not (collider is CharacterBody2D and collider.is_in_group("player")):
			wall_detected = true
	elif direction == -1 and ray_left.is_colliding():
		var collider = ray_left.get_collider()
		if not (collider is CharacterBody2D and collider.is_in_group("player")):
			wall_detected = true

	# Phát hiện mép vực bằng RayCast xuống
	var edge_detected = false
	if direction == 1 and not floor_ray_right.is_colliding():
		edge_detected = true
	elif direction == -1 and not floor_ray_left.is_colliding():
		edge_detected = true

	if wall_detected or edge_detected:
		direction *= -1
		sprite.flip_h = direction < 0
		flip_cooldown = 0.3

func take_damage(amount: int = 1):
	health -= amount
	if health_bar:
		health_bar.value = health
	_flash_hit()
	_apply_knockback()

func _apply_knockback():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var knock_dir = sign(global_position.x - player.global_position.x)
	if knock_dir == 0: knock_dir = 1
	
	if is_on_path:
		var pf = get_parent() as PathFollow2D
		if pf:
			var tween = create_tween()
			tween.tween_property(pf, "progress", pf.progress + (knock_dir * 40.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		velocity.x = knock_dir * 250.0
		velocity.y = -150.0
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
