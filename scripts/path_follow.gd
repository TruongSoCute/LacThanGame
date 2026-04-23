extends PathFollow2D

@export var speed: float = 50.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not get_parent() is Path2D:
		return
		
	progress += speed * delta
