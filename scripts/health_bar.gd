extends ProgressBar

func _ready():
	print("HealthBar initialized at: ", global_position)
	# Force size and position just in case
	custom_minimum_size = Vector2(60, 3)
	show_percentage = false
