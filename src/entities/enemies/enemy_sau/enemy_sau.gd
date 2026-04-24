extends BasicEnemy

@onready var ray_left = $left_raycast
@onready var ray_right = $right_raycast
@onready var floor_ray_left = $floor_ray_left
@onready var floor_ray_right = $floor_ray_right

var direction = -1
var flip_cooldown: float = 0.0

func _setup_enemy():
	health = 3
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health

func _state_logic(delta: float):
	velocity.x = direction * speed
	sprite.play("running")

	if flip_cooldown > 0:
		flip_cooldown -= delta
	else:
		var wall_detected = false
		if direction == 1 and ray_right.is_colliding():
			var collider = ray_right.get_collider()
			if not (collider is CharacterBody2D and collider.is_in_group("player")):
				print("Colider Right")
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
			sprite.flip_h = direction > 0
			flip_cooldown = 0.3
