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

func _physics_process(delta: float) -> void:
	if health <= 0:
		_die()
		return
		
	if is_on_path:
		if anim:
			anim.play("move")
		# Tự động quay mặt theo hướng di chuyển trên Path
		if global_position.x > last_pos.x:
			sprite.flip_h = false # Nhìn phải
		elif global_position.x < last_pos.x:
			sprite.flip_h = true # Nhìn trái
		last_pos = global_position
		return

func _process(_delta: float) -> void:
	pass

func take_damage(amount: int = 1):
	health -= amount
	if health_bar:
		health_bar.value = health
	_flash_hit()

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
	if body.is_in_group("player"):
		Globals.health -= damage
