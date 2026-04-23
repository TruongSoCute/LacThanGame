class_name Basic_Enemy extends CharacterBody2D

@export var speed = 100.0
@export var chase_speed = 250.0
@export var gravity = 600.0

@onready var ray_left = $left_raycast
@onready var ray_right = $right_raycast
@onready var sprite = $Sprite2D

enum State { PATROL, CHASE }
var current_state = State.PATROL
var direction = 1 # 1: Phải, -1: Trái
var player: CharacterBody2D = null

	
func _physics_process(delta):
	# Áp dụng trọng lực
	if not is_on_floor():
		velocity.y += gravity * delta

	match current_state:
		State.PATROL:
			_patrol_logic()
		State.CHASE:
			_chase_logic()
	$anim.play("move")
	move_and_slide()
	_check_for_player()

func _patrol_logic():
	velocity.x = direction * speed
	
	# Kiểm tra tường hoặc hố (nếu raycast đặt chéo xuống)
	if (direction == 1 and ray_right.is_colliding()) or (direction == -1 and ray_left.is_colliding()):
		var collider = ray_right.get_collider() if direction == 1 else ray_left.get_collider()
		# Nếu va chạm không phải người chơi thì coi là tường và quay đầu
		if collider != player:
			direction *= -1
			sprite.flip_h = direction < 0

func _chase_logic():
	if player:
		var dir_to_player = sign(player.global_position.x - global_position.x)
		velocity.x = dir_to_player * chase_speed
		sprite.flip_h = dir_to_player < 0
		
		# Thoát trạng thái Chase nếu người chơi quá xa (tùy chọn)
		if global_position.distance_to(player.global_position) > 400:
			current_state = State.PATROL

func _check_for_player():
	# Kiểm tra tia quét bên phải
	if ray_right.is_colliding():
		var obj = ray_right.get_collider()
		if obj is CharacterBody2D and obj.is_in_group("player"):
			player = obj
			current_state = State.CHASE
			
	# Kiểm tra tia quét bên trái
	if ray_left.is_colliding():
		var obj = ray_left.get_collider()
		if obj is CharacterBody2D and obj.is_in_group("player"):
			player = obj
			current_state = State.CHASE
