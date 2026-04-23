class_name Player
extends CharacterBody2D

@export_category("Movement Variable")
@export var move_speed: float = 120.0
@export var deceleration: float = 0.1
@export var gravity: float = 500.0
var movement = Vector2()

@export_category("Jump Variable")
@export var jump_force: float = 250.0
@export var acceleration: float = 290.0
@export var jump_amount: int = 2

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
var hold_time = 1.5
var hold_timer = 0.0
var is_holding = false


func _ready() -> void:
	$sword/CollisionShape2D.disabled = true

func _physics_process(delta: float) -> void:
	#Add Gravity
	if Globals.health <= 0:
		dead()
	else:
		if is_dasing == false:
			velocity.y += gravity * delta
		elif is_dasing == true:
			velocity.y = dash_gravity
	
	horizontal_movement()
	jump_logic()
	wall_logic()
	
	set_animation()
	flip()
	healing(delta)
	move_and_slide()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("melee_attack"):
		is_attacking = true

func horizontal_movement():
	if is_wall_jumping == false and is_dasing == false: 
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
	var anima: AnimatedSprite2D = $AnimatedSprite2D
	if not is_attacking:
		if velocity.x != 0: 
			anima.play("run")
		if velocity.x == 0:
			anima.play("idle")
		if velocity.y < 0:
			anima.play("jump")
		if velocity.y > 10:
			anima.play("fall")
		if is_on_wall_only():
			anima.play("wall")
	if is_attacking:
		anima.play("attack")
		

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

#Jump & Double Jump Function
func jump_logic():
	if is_on_floor():
		dash_number = 1
		jump_amount = 2
		if Input.is_action_just_pressed("jump"):
			jump_amount -= 1
			# Set trực tiếp vận tốc nhảy thay vì trừ, tạo lực nhảy cố định khi ở trên đất
			velocity.y = -jump_force
	
	if not is_on_floor():
		if jump_amount > 0:
			if Input.is_action_just_pressed("jump"):
				jump_amount -= 1
				# Double jump cũng set trực tiếp bằng lực acceleration (theo logic cũ của bạn là lực mạnh hơn)
				velocity.y = -acceleration
			
		# Xử lý nhảy ngắn/cao tuỳ theo thời gian giữ phím (variable jump height)
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= 0.3
		
func wall_logic():
#Wall Slide
	if is_on_wall_only():
		velocity.y = wall_slide
		if Input.is_action_just_pressed("jump"):
			if right_ray.is_colliding():
				jump_amount = 2
				velocity = Vector2(-wall_x_force, wall_y_force)
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
	get_tree().reload_current_scene()
	Globals.health = 4

##Ham chuc nang hoi phuc
func healing(delta: float):
	if Input.is_action_just_pressed("healing"):
		is_holding = true
		hold_timer = 0.0
	
	if is_holding:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		if Input.is_action_pressed("healing") and hold_timer <= hold_time:
			hold_timer += delta		
		else:
			if hold_timer >= hold_time:
				can_healing()
			is_holding = false
			hold_timer = 0.0

func can_healing():
	if Globals.soul >= 0.25:
		Globals.health += 1
		Globals.soul -= 0.25
		
