class_name Player
extends CharacterBody2D

@export_category("Movement Variable")
@export var move_speed: float = 120.0
@export var deceleration: float = 0.1
@export var gravity: float = 500.0
var movement = Vector2()

@export_category("Jump Variable")
@export var jump_force: float = 300.0
@export var double_jump_force: float = 280.0
@export var jump_max_amount: int = 2
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15
@export var fall_gravity_multiplier: float = 1.8
@export var jump_cut_multiplier: float = 2.5

var jump_amount: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@export_category("Wall Jump Variable")
@export var wall_slide: float = 20.0
@onready var left_ray: RayCast2D = $raycast/left_ray
@onready var right_ray: RayCast2D = $raycast/right_ray
@export var wall_x_force: float = 200.0
@export var wall_y_force: float = -220.0
var is_wall_jumping = false

@export_category("Dash Variable")
@export var dash_speed: float = 400.0
@export var facing_right: bool = true
@export var dash_gravity: float = 0.0
@export var dash_number: int = 1
var dash_key_pressed = 0
var is_dasing = false
var dash_timer = Timer

@export_category("Melee Variable")
@export var is_attacking: bool = false

##Health Variable
var hold_time = 1.0
var hold_timer = 0.0
var is_holding = false
var health_at_heal_start: float = 0.0

var is_dead = false

func _ready() -> void:
	$sword/CollisionShape2D.disabled = true

func _physics_process(delta: float) -> void:
	#Add Gravity
	# Gravity logic
	if Globals.health <= 0 or is_dead:
		if not is_dead:
			dead()
		return
	
	if not is_dasing:
		var current_gravity = gravity
		if velocity.y > 0: # Falling
			current_gravity *= fall_gravity_multiplier
		elif velocity.y < 0 and not Input.is_action_pressed("jump"): # Short jump
			current_gravity *= jump_cut_multiplier
		
		velocity.y += current_gravity * delta
	else:
		velocity.y = dash_gravity
	
	horizontal_movement()
	jump_logic()
	wall_logic()
	
	set_animation()
	flip()
	healing(delta)
	move_and_slide()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("melee_attack") and not is_attacking and not is_holding:
		is_attacking = true
		$anim.play("Attack")

func horizontal_movement():
	if is_wall_jumping == false and is_dasing == false and is_holding == false: 
		movement = Input.get_axis("move_left", "move_right")
		
		if movement:
			velocity.x = movement * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed * deceleration)
	if Input.is_action_just_pressed("dash") and dash_key_pressed == 0 and dash_number >= 1:
		dash_number -= 1
		dash_key_pressed = 1
		dash()

# Chạy với Animation cũ
func set_animation():
	if is_attacking: 
		return # Để AnimationPlayer tự chạy hết đòn đánh
	
	if is_on_floor():
		if velocity.x != 0:
			$anim.play("Move")
		else:
			$anim.play("Idle")
	else:
		if velocity.y < 0:
			$anim.play("Jump")
		else:
			$anim.play("Fall")
			
	if is_on_wall_only():
		$anim.play("Wall")

	# Đảm bảo dùng Sprite2D (của AnimationPlayer)
	$Sprite2D.visible = true
	$AnimatedSprite2D.visible = false
		

#Filp Srpite base on transform scale 
func flip():
	if velocity.x > 0.0:
		facing_right = true
		scale.x = scale.y * 1
		wall_x_force = 200.0
	if velocity.x < 0.0:
		facing_right = false
		scale.x = scale.y * -1
		wall_x_force = -200.0

# Jump & Double Jump Function
func jump_logic():
	if is_holding: return
	var delta = get_physics_process_delta_time()
	
	# Coyote Time Timer
	if is_on_floor():
		coyote_timer = coyote_time
		jump_amount = jump_max_amount
		dash_number = 1
	else:
		coyote_timer -= delta
		
	# Jump Buffer Timer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
		
	# Perform Jump
	if jump_buffer_timer > 0:
		# Ground Jump (including Coyote Time)
		if coyote_timer > 0:
			perform_jump(jump_force)
			coyote_timer = 0 # Consume coyote time
		# Double Jump
		elif jump_amount > 0:
			perform_jump(double_jump_force)

func perform_jump(force: float):
	velocity.y = -force
	jump_amount -= 1
	jump_buffer_timer = 0 # Consume buffer
		
func wall_logic():
#Wall Slide
	if is_on_wall_only():
		velocity.y = wall_slide
		if jump_buffer_timer > 0:
			var wall_normal = get_wall_normal()
			# Wall jump pushes away from the wall
			velocity.x = wall_normal.x * abs(wall_x_force)
			velocity.y = wall_y_force
			jump_amount = jump_max_amount - 1
			jump_buffer_timer = 0
			wall_jump()

func wall_jump():
	is_wall_jumping = true
	await get_tree().create_timer(0.12).timeout
	is_wall_jumping = false
	
func dash():
	if dash_key_pressed == 1:
		is_dasing = true
	else:
		is_dasing = false
		
	if facing_right == true:
		velocity.x = dash_speed
		dash_started()
	if facing_right == false:
		velocity.x = -dash_speed
		dash_started()
	
func dash_started():
	if is_dasing == true:
		dash_key_pressed = 1
		await get_tree().create_timer(0.16).timeout
		is_dasing = false
		dash_key_pressed = 0
	else:
		return	
		
func reset_states():
	is_attacking = false
	
func dead():
	is_dead = true
	Globals.player_died.emit()

##Ham chuc nang hoi phuc
func healing(delta: float):
	if Input.is_action_just_pressed("healing") and is_on_floor() and Globals.soul >= 0.5 and Globals.health < 4.0:
		is_holding = true
		hold_timer = 0.0
		health_at_heal_start = Globals.health
		$HealParticles.emitting = true
		$HealSFX.play()
	
	if is_holding:
		if not is_on_floor() or Globals.health < health_at_heal_start:
			is_holding = false
			hold_timer = 0.0
			$HealParticles.emitting = false
			$HealSFX.stop()
			return
			
		velocity.x = 0
		if not is_attacking:
			$anim.play("Idle")
			
		if Input.is_action_pressed("healing"):
			hold_timer += delta		
			if hold_timer >= hold_time:
				can_healing()
				is_holding = false
				hold_timer = 0.0
				$HealParticles.emitting = false
				$HealSFX.stop()
		else:
			is_holding = false
			hold_timer = 0.0
			$HealParticles.emitting = false
			$HealSFX.stop()

func can_healing():
	if Globals.soul >= 0.5:
		Globals.health += 1
		Globals.soul -= 0.5
