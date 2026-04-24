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

	var current_speed_mult = 1.0
	if get_child_count() > 0:
		var child = get_child(0)
		if "speed_multiplier" in child:
			current_speed_mult = child.speed_multiplier

	progress += speed * delta * direction * current_speed_mult
	
	if (direction == 1 and progress_ratio >= 1.0) or (direction == -1 and progress_ratio <= 0.0):
		direction *= -1
		is_waiting = true
		wait_timer = idle_time
