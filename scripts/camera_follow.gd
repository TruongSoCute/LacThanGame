extends Camera2D

@onready var ground: TileMapLayer =$"../ground"
@onready var player: CharacterBody2D = $"../Player"

@export var horizontal_dead_zone: float = 30.0
@export var vertical_dead_zone: float = 30.0
@export var follow_speed: float = 120.0

func _ready() -> void:
	setup_camera_limits()
	# optional: ensure this camera is active
	# current = true

func _physics_process(delta: float) -> void:
	update_camera_position(delta)

func setup_camera_limits():
	global_position = player.global_position
	var used_rect = ground.get_used_rect()
	var cell_size = ground.tile_set.tile_size
	var map_width = used_rect.size.x * cell_size.x
	var map_height = used_rect.size.y * cell_size.y

	limit_left = used_rect.position.x * cell_size.x
	limit_right = limit_left + map_width
	limit_top = used_rect.position.y * cell_size.y
	limit_bottom = limit_top + map_height

func update_camera_position(delta: float) -> void:
	if not player:
		return

	var player_pos: Vector2 = player.global_position
	var cam_pos: Vector2 = global_position
	var target_pos: Vector2 = cam_pos

	# Horizontal: handle both right and left dead-zones
	if (player_pos.x - cam_pos.x) > horizontal_dead_zone:
		target_pos.x = player_pos.x
	elif (cam_pos.x - player_pos.x) > horizontal_dead_zone:
		target_pos.x = player_pos.x

	# Vertical: same behavior as your original logic
	if player_pos.y < cam_pos.y - vertical_dead_zone:
		target_pos.y = player_pos.y
	elif player_pos.y > cam_pos.y + vertical_dead_zone:
		target_pos.y = player_pos.y

	# Smoothly move camera using global_position
	global_position.x = move_toward(global_position.x, target_pos.x, follow_speed * delta)

	# For vertical movement you had special handling while falling — keep that
	if player_pos.y > cam_pos.y and "velocity" in player:
		var fall_speed = abs(player.velocity.y)  # prefer positive speed
		# ensure fall_speed isn't zero so camera still moves smoothly:
		global_position.y = move_toward(global_position.y, target_pos.y, max(fall_speed, 1.0) * delta)
	else:
		global_position.y = move_toward(global_position.y, target_pos.y, follow_speed * delta)
