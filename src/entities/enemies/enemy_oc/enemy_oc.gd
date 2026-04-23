extends BasicEnemy

func _setup_enemy():
	health = 5
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
