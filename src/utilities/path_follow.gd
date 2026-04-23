extends PathFollow2D

@export var speed: float = 50.0
@export var idle_time: float = 1.0

var direction = 1
var is_waiting = false
var wait_timer = 0.0

func _ready() -> void:
	loop = false

func _process(delta: float) -> void:
	if not get_parent() is Path2D:
		return
		
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
		return

	progress += speed * delta * direction
	
	if (direction == 1 and progress_ratio >= 1.0) or (direction == -1 and progress_ratio <= 0.0):
		direction *= -1
		is_waiting = true
		wait_timer = idle_time
