extends Sprite2D

func _ready():
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("play")
		$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	else:
		await get_tree().create_timer(0.3).timeout
		queue_free()

func _on_animation_finished(_anim_name: String):
	queue_free()
