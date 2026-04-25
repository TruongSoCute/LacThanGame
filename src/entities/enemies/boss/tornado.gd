extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: float = 1.5
var lifetime: float = 6.0
var _time: float = 0.0

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _draw() -> void:
	for i in 5:
		var t_offset = _time * 4.0 + i * 1.2
		var r = float(30 - i * 4)
		var ox = cos(t_offset) * i * 4.0
		var oy = sin(t_offset * 1.3) * i * 3.0
		draw_circle(Vector2(ox, oy), r, Color(0.2, 0.65, 1.0, 0.25 + i * 0.04))
		draw_circle(Vector2(ox, oy), r * 0.55, Color(0.5, 0.9, 1.0, 0.55 - i * 0.08))
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 1.0, 1.0, 0.95))

func _physics_process(delta: float) -> void:
	_time += delta
	var perp = Vector2(-direction.y, direction.x)
	position += direction * speed * delta + perp * sin(_time * 5.0) * 55.0 * delta
	rotation = direction.angle()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
