class_name BasicEnemy
extends CharacterBody2D

@export var health: int = 5
@export var damage = 1.0

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

@onready var anim = $AnimationPlayer

var is_on_path = false
var last_pos: Vector2

func _ready():
	is_on_path = get_parent() is PathFollow2D
	last_pos = global_position
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health

func _physics_process(_delta: float) -> void:
	if health <= 0:
		_die()
		return
		
	if is_on_path:
		var pf = get_parent()
		if pf is PathFollow2D and "is_waiting" in pf and pf.is_waiting:
			if anim:
				anim.play("Idle")
		else:
			if anim:
				anim.play("move")
		# Tự động quay mặt theo hướng di chuyển trên Path
		if global_position.x > last_pos.x:
			sprite.flip_h = true # Inverted
		elif global_position.x < last_pos.x:
			sprite.flip_h = false # Inverted
		last_pos = global_position
		return

func _process(_delta: float) -> void:
	pass

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
			# Đẩy lùi progress trên đường dẫn
			tween.tween_property(pf, "progress", pf.progress + (knock_dir * 40.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		# Đẩy lùi vật lý
		velocity.x = knock_dir * 200.0
		velocity.y = -100.0 # Nảy nhẹ lên
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
