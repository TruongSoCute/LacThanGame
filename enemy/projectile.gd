extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 1.0
var lifetime: float = 5.0

func _ready():
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _physics_process(delta):
	position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("Enemy"):
		queue_free()
