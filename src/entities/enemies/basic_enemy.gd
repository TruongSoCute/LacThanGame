class_name BasicEnemy extends CharacterBody2D

@export var health: int = 3
@export var damage: float = 1.0
@export var speed: float = 100.0
@export var gravity: float = 600.0

@onready var sprite = $Sprite2D
@onready var anim = get_node_or_null("anim") if get_node_or_null("anim") else get_node_or_null("AnimationPlayer")
@onready var health_bar = get_node_or_null("HealthBar")

var is_on_path: bool = false
var last_pos: Vector2

func _ready():
	is_on_path = get_parent() is PathFollow2D
	last_pos = global_position
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
		health_bar.z_index = 100
	
	_setup_enemy()

func _setup_enemy():
	pass

func _physics_process(delta: float) -> void:
	if health <= 0:
		_die()
		return

	if is_on_path:
		_path_logic(delta)
	else:
		_normal_logic(delta)

func _path_logic(_delta: float):
	var pf = get_parent()
	if pf is PathFollow2D and "is_waiting" in pf and pf.is_waiting:
		if anim: anim.play("RESET")
	else:
		if anim: anim.play("move")
	
	if global_position.x > last_pos.x:
		sprite.flip_h = true
	elif global_position.x < last_pos.x:
		sprite.flip_h = false
	last_pos = global_position

func _normal_logic(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	_state_logic(delta)
	move_and_slide()

func _state_logic(_delta: float):
	pass

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
	if body.has_method("take_damage") and not body.is_in_group("Enemy"):
		body.take_damage(damage)
