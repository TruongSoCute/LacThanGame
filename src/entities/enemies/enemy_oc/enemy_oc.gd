extends BasicEnemy

@onready var ray_left = $left_raycast
@onready var ray_right = $right_raycast
@onready var floor_ray_left = $floor_ray_left
@onready var floor_ray_right = $floor_ray_right

var direction = -1
var flip_cooldown: float = 0.0

func _setup_enemy():
	health = 5
	speed = 40.0
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health

func _state_logic(delta: float):
	velocity.x = direction * speed
	sprite.play("move")

	if flip_cooldown > 0:
		flip_cooldown -= delta
		return

	var wall_hit = (direction == 1 and ray_right.is_colliding()) or \
				   (direction == -1 and ray_left.is_colliding())
	var edge_hit = (direction == 1 and not floor_ray_right.is_colliding()) or \
				   (direction == -1 and not floor_ray_left.is_colliding())

	if wall_hit or edge_hit:
		direction *= -1
		sprite.flip_h = direction > 0
		flip_cooldown = 0.4
