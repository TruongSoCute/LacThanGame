extends Node2D

signal health_changed(new_health: float)
@warning_ignore("unused_signal")
signal player_died

var max_health: float = 4.0
var soul = 0.0
var coins : int = 0

var health: float = 4.0 :
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)

func _process(_delta: float) -> void:
	#$GUI/coin_value.text = str(coins)
	pass
